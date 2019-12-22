class Api::V1::BulkItemsController < ApplicationController
  before_action only: [:create] do 
    authenticate_with_token! request.headers['Authorization']
  end
  respond_to :json
  
  def show
    respond_with BulkItem.find(params[:id])
  end

  def index
    respond_with BulkItem.all
  end

  def create
    bulk_item = BulkItem.new(bulk_item_params)
    bulk_item.user = current_user

    # Paperclip adaptor 
    item_img = Paperclip.io_adapters.for(params[:item_img])
    item_img.original_filename = params[:filename]
    bulk_item.item_img = item_img

    if bulk_item.save
      @inventory_item = InventoryItem.where('actable_id = ? AND actable_type = ?', bulk_item.id, 'BulkItem').first
      log_checkin_transaction( params[:entry_date], @inventory_item.id, "Entrada granel inicial", params[:estimated_issue_date], params[:additional_comments], params[:delivery_company], params[:delivery_company_contact], params[:bulk_item][:quantity], params[:folio])

      if params[:item_request_id].to_i > 0
        @item_request = InventoryItemRequest.find( params[:item_request_id] )
        send_notifications_approved_entry
        @item_request.destroy
      end

      AeItem.create( :user_id => params[:ae_id], :inventory_item_id => @inventory_item.id ) if params[:ae_id].present?

      render json: bulk_item.get_details, status: 201, location: [:api, bulk_item]
    else
      render json: { errors: bulk_item.errors }, status: 422
    end
  end

  def update
    if params[:is_inventory_item]
      inventory_item = InventoryItem.find( params[:id] )
      bulk_item = BulkItem.find( inventory_item.actable_id )
    else
      bulk_item = BulkItem.find( params[:id] )
    end

    if bulk_item.update( bulk_item_params )
      if params[:ae_id].present?
        ae_item = AeItem.where( :inventory_item_id => inventory_item.id ).first
        if ae_item.present?          
          sql = "DELETE from ae_items WHERE inventory_item_id = " + inventory_item.id.to_s
          ActiveRecord::Base.connection.execute(sql)
          AeItem.create( :user_id => params[:ae_id], :inventory_item_id => inventory_item.id ) 
        else
          AeItem.create( :user_id => params[:ae_id], :inventory_item_id => inventory_item.id ) 
        end
      end

      render json: bulk_item.get_details, status: 200, location: [:api, bulk_item]
      return
    end

    render json: { errors: bulk_item.errors }, status: 422
  end

  def withdraw

    bulk_item = BulkItem.find_by_id(params[:id])

    if ! bulk_item.present?
      render json: { errors: "No se encontró el artículo." }, status: 422
      return
    end

    case bulk_item.status
    when InventoryItem::OUT_OF_STOCK
      render json: { errors: 'No se pudo completar la salida por que el artículo "' + bulk_item.name + '" no se encuentra en existencia.' }, status: 422
      return
    when InventoryItem::PENDING_ENTRY
      render json: { errors: 'No se pudo completar la salida por que el artículo "' + bulk_item.name + '" no ha ingresado al almacén.' }, status: 422
      return
    when InventoryItem::PENDING_WITHDRAWAL
      render json: { errors: 'No se pudo completar la salida por que el artículo "' + bulk_item.name + '" tiene una salida programada.' }, status: 422
      return
    end

    bulk_item.quantity = bulk_item.quantity.to_i - params[:quantity].to_i
    if 0 > bulk_item.quantity.to_i
      render json: { errors: '¡No puedes sacar mas existencias de las que hay disponibles!' }, status: 422
      return
    end

    bulk_item.status = InventoryItem::OUT_OF_STOCK if bulk_item.quantity.to_i == 0
    if bulk_item.save
      @inventory_item = InventoryItem.where('actable_id = ? AND actable_type = ?', bulk_item.id, 'BulkItem').first
      
      if bulk_item.warehouse_locations? and ! params[:locations].present? and ! params[:any_location]
        item_locations = bulk_item.item_locations
        item_locations.each do |il|
          location = il.warehouse_location
          location.remove_item( @inventory_item.id )
        end
      end

      if params[:locations].present?
        params[:locations].each do |l|
          location = WarehouseLocation.find( l[:location_id] )
          location.remove_quantity( @inventory_item.id, l[:quantity].to_i )
        end
      end

      log_checkout_transaction( params[:exit_date], @inventory_item.id, "Salida a granel", params[:estimated_return_date], params[:additional_comments], params[:pickup_company], params[:pickup_company_contact], params[:quantity])

      send_notifications_withdraw if InventoryItem::PENDING_WITHDRAWAL == bulk_item.status  

      render json: { success: '¡Has sacado ' + params[:quantity].to_s + ' existencia(s) del artículo "' +  bulk_item.name + '"!', quantity: bulk_item.quantity }, status: 201   
      return
    end

    render json: { errors: bulk_item.errors }, status: 422 
  end

  def re_entry
    bulk_item = BulkItem.find_by_id(params[:id])

    if ! bulk_item.present?
      render json: { errors: "No se encontró el artículo." }, status: 422
      return
    end

    bulk_item.status = InventoryItem::IN_STOCK
    bulk_item.state = params[:state]
    bulk_item.quantity = bulk_item.quantity.to_i + params[:quantity].to_i
    if bulk_item.save
      @inventory_item = InventoryItem.where('actable_id = ? AND actable_type = ?', bulk_item.id, 'BulkItem').first
      log_checkin_transaction( params[:entry_date], @inventory_item.id, "Reingreso granel", '', params[:additional_comments], params[:delivery_company], params[:delivery_company_contact], params[:quantity])
      send_notifications_re_entry
      render json: { success: '¡Has reingresado '+ params[:quantity].to_s + ' existencia(s) del artículo  "' +  bulk_item.name + '"!' }, status: 201  
      return
    end

    render json: { errors: bulk_item.errors }, status: 422 
  end

  private

    def bulk_item_params
      params.require(:bulk_item).permit(:quantity, :name, :description, :project_id, :status, :item_type, :barcode, :validity_expiration_date, :value, :state, :storage_type, :is_high_value)
    end

    def send_notifications_re_entry
      project = @inventory_item.project
      account_executives = project.users.where( 'role = ?', User::ACCOUNT_EXECUTIVE )
      admins = User.where( 'role = ?', User::ADMIN )

      account_executives.each do |ae|
        ae.notifications << Notification.create( :title => 'Reingreso de material', :inventory_item_id => @inventory_item.id, :message => 'Se ha reingresado al almacén el artículo "' + @inventory_item.name + '" del proyecto "' + project.name + '".' )
      end
      admins.each do |admin|
        admin.notifications << Notification.create( :title => 'Reingreso de material', :inventory_item_id => @inventory_item.id, :message => 'Se ha reingresado al almacén el artículo "' + @inventory_item.name + '" del proyecto "' + project.name + '".' )
      end
    end

    def send_notifications_withdraw
      project = @inventory_item.project
      admins = User.where( 'role IN (?)', [ User::ADMIN, User::WAREHOUSE_ADMIN ] )

      admins.each do |admin|
        admin.notifications << Notification.create( :title => 'Solicitud de salida', :inventory_item_id => @inventory_item.id, :message => @inventory_item.user.role_name + ' "' + @inventory_item.user.first_name + ' ' + @inventory_item.user.last_name + '" ha solicitado la salida del artículo "' + @inventory_item.name + '".'  )
      end
    end

    def send_notifications_approved_entry
      transaction = CheckInTransaction.last
      ae = User.find( @item_request.ae_id )

      ae.notifications << Notification.create( :title => 'Entrada aprobada', :inventory_item_id => @inventory_item.id, :message => 'Se aprobó la entrada del artículo "' + @inventory_item.name + '" con fecha de entrada ' + transaction.entry_date.strftime("%d/%m/%Y")  )
    end
end

