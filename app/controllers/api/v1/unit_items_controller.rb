class Api::V1::UnitItemsController < ApplicationController
  before_action only: [:create, :withdraw] do 
    authenticate_with_token! request.headers['Authorization']
  end
  respond_to :json
  
  def show
    respond_with UnitItem.find(params[:id])
  end

  def index
    respond_with UnitItem.all
  end

  def create

    unit_item = UnitItem.new(unit_item_params)
    unit_item.user = current_user

    if User::CLIENT == current_user.role or User::PROJECT_MANAGER == current_user.role or User::ACCOUNT_EXECUTIVE == current_user.role
      unit_item.status = InventoryItem::PENDING_ENTRY
    end

    # Paperclip adaptor 
    item_img = Paperclip.io_adapters.for(params[:item_img])
    item_img.original_filename = params[:filename]
    unit_item.item_img = item_img

    if unit_item.save
      @inventory_item = InventoryItem.where( 'actable_id = ? AND actable_type = ?', unit_item.id, 'UnitItem' ).first
      log_checkin_transaction( params[:entry_date], @inventory_item.id, "Entrada unitaria", params[:estimated_issue_date], params[:additional_comments], params[:delivery_company], params[:delivery_company_contact], 1)
      if params[:item_request_id].to_i > 0
        @item_request = InventoryItemRequest.find( params[:item_request_id] )
        send_notifications_approved_entry
        @item_request.destroy
      end
      
      PmItem.create( :user_id => params[:pm_id], :inventory_item_id => @inventory_item.id ) if params[:pm_id].present?
      AeItem.create( :user_id => params[:ae_id], :inventory_item_id => @inventory_item.id ) if params[:pm_id].present?
        
      render json: unit_item.get_details, status: 201, location: [:api, unit_item]
      return
    end

    render json: { errors: unit_item.errors }, status: 422
  end

  def update
    if params[:is_inventory_item]
      inventory_item = InventoryItem.find( params[:id] )
      unit_item = UnitItem.find( inventory_item.actable_id )
    else
      unit_item = UnitItem.find( params[:id] )
    end

    if unit_item.update( unit_item_params )

      if params[:pm_id].present?
        pm_item = PmItem.where( :inventory_item_id => inventory_item.id ).first
        if pm_item.present?          
          sql = "DELETE from pm_items WHERE inventory_item_id = " + inventory_item.id.to_s
          ActiveRecord::Base.connection.execute(sql)
          PmItem.create( :user_id => params[:pm_id], :inventory_item_id => inventory_item.id ) 
        else
          PmItem.create( :user_id => params[:pm_id], :inventory_item_id => inventory_item.id ) 
        end
      end

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
      
      render json: unit_item.get_details, status: 200, location: [:api, unit_item]
      return
    end

    render json: { errors: unit_item.errors }, status: 422
  end

  def withdraw
    unit_item = UnitItem.find_by_id(params[:id])

    if ! unit_item.present?
      render json: { errors: "No se encontró el artículo." }, status: 422
      return
    end

    case unit_item.status
    when InventoryItem::OUT_OF_STOCK
      render json: { errors: 'No se pudo completar la salida por que el artículo "' + unit_item.name + '" no se encuentra en existencia.' }, status: 422
      return
    when InventoryItem::PENDING_ENTRY
      render json: { errors: 'No se pudo completar la salida por que el artículo "' + unit_item.name + '" no ha ingresado al almacén.' }, status: 422
      return
    when InventoryItem::PENDING_WITHDRAWAL
      render json: { errors: 'No se pudo completar la salida por que el artículo "' + unit_item.name + '" tiene una salida programada.' }, status: 422
      return
    end

    if User::CLIENT == current_user.role or User::PROJECT_MANAGER == current_user.role or User::ACCOUNT_EXECUTIVE == current_user.role
      unit_item.status = InventoryItem::PENDING_WITHDRAWAL
    else
      unit_item.status = InventoryItem::OUT_OF_STOCK
    end
    
    if unit_item.save
      @inventory_item = InventoryItem.where( 'actable_id = ? AND actable_type = ?', unit_item.id, 'UnitItem' ).first

      from_location = {}
      if unit_item.warehouse_locations?
        item_location = unit_item.item_locations.first
        location = item_location.warehouse_location
        location.remove_item( @inventory_item.id )
        from_location = location
      end

      log_checkout_transaction( params[:exit_date], @inventory_item.id, "Salida unitaria", params[:estimated_return_date], params[:additional_comments], params[:pickup_company], params[:pickup_company_contact], 1)
      
      send_notifications_withdraw if InventoryItem::PENDING_WITHDRAWAL == unit_item.status      

      render json: { success: '¡Has sacado el artículo "' +  unit_item.name + '"!', location: location }, status: 201  
      return
    end 

    render json: { errors: unit_item.errors }, status: 422
  end

  def re_entry
    unit_item = UnitItem.find_by_id(params[:id])

    if ! unit_item.present?
      render json: { errors: "No se encontró el artículo." }, status: 422
      return
    end

    unit_item.state = params[:state]
    unit_item.status = InventoryItem::IN_STOCK
    if unit_item.save
      @inventory_item = InventoryItem.where( 'actable_id = ? AND actable_type = ?', unit_item.id, 'UnitItem' ).first
      log_checkin_transaction( params[:entry_date], @inventory_item.id, "Reingreso unitario", '-', params[:additional_comments], params[:delivery_company], params[:delivery_company_contact], 1)
      send_notifications_re_entry
      render json: { success: '¡Has reingresado el artículo "' +  unit_item.name + '"!' }, status: 201  
      return
    end

    render json: { errors: unit_item.errors }, status: 422 
  end

  private

    def unit_item_params
      params.require( :unit_item ).permit( :serial_number, :brand, :model, :name, :description, :project_id, :status, :item_type, :barcode, :validity_expiration_date, :value, :state, :storage_type, :is_high_value )
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

      if User::CLIENT == @inventory_item.user.role
        account_executives = project.users.where( 'role = ?', User::ACCOUNT_EXECUTIVE )
        account_executives.each do |ae|
          ae.notifications << Notification.create( :title => 'Solicitud de salida', :inventory_item_id => @inventory_item.id, :message => @inventory_item.user.role_name + ' "' + @inventory_item.user.first_name + ' ' + @inventory_item.user.last_name + '" ha solicitado la salida del artículo "' + @inventory_item.name + '".'  )
        end
      end
    end

    def send_notifications_approved_entry
      transaction = CheckInTransaction.last
      pm = User.find( @item_request.pm_id )
      ae = User.find( @item_request.ae_id )

      pm.notifications << Notification.create( :title => 'Entrada aprobada', :inventory_item_id => @inventory_item.id, :message => 'Se aprobó la entrada del artículo "' + @inventory_item.name + '" con fecha de entrada ' + transaction.entry_date.strftime("%d/%m/%Y")  )
      ae.notifications << Notification.create( :title => 'Entrada aprobada', :inventory_item_id => @inventory_item.id, :message => 'Se aprobó la entrada del artículo "' + @inventory_item.name + '" con fecha de entrada ' + transaction.entry_date.strftime("%d/%m/%Y")  )
    end
    
end
