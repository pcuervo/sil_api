module Api
  module V1
    class InventoryItemsController < ApplicationController
      before_action only: %i[create authorize_entry authorize_withdrawal request_item_entry cancel_item_entry_request destroy stats_pm_ae re_entry] do
        authenticate_with_token! request.headers['Authorization']
      end
      after_action :send_notification_authorize_entry, only: [:authorize_entry]
      after_action :send_notification_authorize_withdrawal, only: [:authorize_withdrawal]
      after_action :send_entry_request_notifications, only: [:request_item_entry]
      after_action :send_cancelled_entry_request_notifications, only: [:cancel_item_entry_request]
      respond_to :json

      def index
        respond_with InventoryItem.search(params)
      end

      def show
        respond_with InventoryItem.find(params[:id]).get_details
      end

      def create
        @inventory_item = current_user.inventory_items.build(inventory_item_params)

        if User::CLIENT == current_user.role || User::PROJECT_MANAGER == current_user.role || User::ACCOUNT_EXECUTIVE == current_user.role
          @inventory_item.status = InventoryItem::PENDING_ENTRY
        end

        item_img = Paperclip.io_adapters.for(params[:item_img])
        item_img.original_filename = params[:filename]
        @inventory_item.item_img = item_img

        if @inventory_item.save
          next_folio = InventoryTransaction.next_checkin_folio
          log_checkin_transaction(params[:entry_date], @inventory_item.id, 'Entrada granel inicial', params[:estimated_issue_date], params[:additional_comments], params[:delivery_company], params[:delivery_company_contact], params[:inventory_item][:quantity], next_folio)

          if params[:item_request_id].to_i > 0
            @item_request = InventoryItemRequest.find(params[:item_request_id])
            send_notifications_approved_entry
            @item_request.destroy
          end

          PmItem.create(user_id: params[:pm_id], inventory_item_id: @inventory_item.id) if params[:pm_id].present?
          AeItem.create(user_id: params[:ae_id], inventory_item_id: @inventory_item.id) if params[:pm_id].present?

          render json: @inventory_item.get_details, status: 201, location: [:api, @inventory_item]
          return
        end

        render json: { errors: @inventory_item.errors }, status: 422
      end

      def update
        inventory_item = InventoryItem.find( params[:id] )

        if params[:item_img].present?
          item_img = Paperclip.io_adapters.for(params[:item_img])
          item_img.original_filename = params[:filename]
          inventory_item.item_img = item_img
        end
    
        if inventory_item.update( inventory_item_params )
          
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
    
          render json: inventory_item.get_details, status: 200, location: [:api, inventory_item]
          return
        end
    
        render json: { errors: inventory_item.errors }, status: 422
      end

      def by_barcode
        inventory_item = InventoryItem.find_by_barcode(params[:barcode])
        if inventory_item.present?
          respond_with inventory_item.get_details
          return
        end

        render json: { errors: 'No se encontró ningún artículo' }, status: 422
      end

      def by_type
        respond_with InventoryItem.where('status = ?', params[:status])
      end

      def pending_entry
        respond_with InventoryItem.where('status=?', InventoryItem::PENDING_ENTRY)
      end

      def pending_validation_entries
        respond_with InventoryItem.where('status=?', InventoryItem::PENDING_APPROVAL)
      end

      def pending_entry_requests
        respond_with InventoryItemRequest.details
      end

      def pending_withdrawal_requests
        respond_with WithdrawRequest.all
      end

      def pending_withdrawal
        respond_with InventoryItem.where('status=?', InventoryItem::PENDING_WITHDRAWAL)
      end

      def authorize_entry
        @item = InventoryItem.find(params[:id])
        @item.status = InventoryItem::IN_STOCK
        @item.save
        render json: { success: '¡Se ha aprobado el ingreso del artículo "' + @item.name + '"!' }, status: 201
      end

      def authorize_withdrawal
        @item = InventoryItem.find(params[:id])
        @item.status = InventoryItem::OUT_OF_STOCK
        @item.save
        render json: { success: '¡Se ha aprobado la salida del artículo "' + @item.name + '"!' }, status: 201
      end

      def with_pending_location
        respond_with InventoryItem.joins('LEFT JOIN item_locations ON inventory_items.id = item_locations.inventory_item_id ').where(' item_locations.id is null AND inventory_items.status IN (?)', [InventoryItem::IN_STOCK, InventoryItem::PARTIAL_STOCK]).order(updated_at: :desc)
      end

      def reentry_with_pending_location
        pending_location_ids = WarehouseLocation.pending_location_ids
        if pending_location_ids.present?
          respond_with InventoryItem.where('id IN (?)', pending_location_ids)
          return
        end
        respond_with InventoryItem.none
      end

      def reentry_with_pending_location?
        pending_location_items = WarehouseLocation.pending_location_items(params[:id])
        if pending_location_items.present?
          render json: { quantity: pending_location_items.first.quantity }, status: 201
          return
        end
        respond_with InventoryItem.none
      end

      def multiple_withdrawal
        inventory_items = params[:inventory_items]
        has_errors = false

        inventory_items.each do |item|
          inventory_item = InventoryItem.find(item[:id])
          quantity = item[:quantity].to_i
          withdraw = inventory_item.withdraw(params[:exit_date], '', params[:pickup_company], params[:pickup_company_contact], params[:additional_comments], quantity, params[:folio])

          if [InventoryItem::OUT_OF_STOCK, InventoryItem::PENDING_ENTRY, InventoryItem::PENDING_WITHDRAWAL, InventoryItem::EXPIRED].include? withdraw
            has_errors = true
            break
          end
        end

        if has_errors
          render json: { errors: 'No se pudo realizar la salida masiva', items_withdrawn: 0 }, status: 422
          return
        end

        render json: { success: '¡Se ha realizado una salida masiva!', items_withdrawn: inventory_items.count }, status: 201
      end

      def request_item_entry
        @inventory_item_request = InventoryItemRequest.new(inventory_item_request_params)

        if @inventory_item_request.save!
          render json: { inventory_item: @inventory_item_request }, status: 201
        else
          render json: { errors: @inventory_item_request.errors }, status: 422
        end
      end

      def cancel_item_entry_request
        @inventory_item_request = InventoryItemRequest.find(params[:id])
        @cancelled = @inventory_item_request.cancel
        if @cancelled
          render json: { success: '¡Se ha cancelado la entrada!' }, status: 201
          return
        end

        render json: { errors: 'Ha ocurrido un error, no se pudo realizar la cancelación en este momento.' }, status: 201
      end

      def item_request
        respond_with InventoryItemRequest.where('id = ?', params[:id]).details
      end

      def stats
        stats = {}
        stats['total_number_items'] = InventoryItem.all.count
        stats['inventory_value'] = InventoryItem.inventory_value
        stats['inventory_by_type'] = InventoryItem.inventory_by_type
        stats['occupation_by_month'] = InventoryItem.occupation_by_month
        stats['total_high_value_items'] = InventoryItem.total_high_value_items

        render json: { stats: stats }, status: 200
      end

      def stats_pm_ae
        stats = {}
        project_ids = []
        current_user.projects.each do |p|
          project_ids.push(p.id)
        end

        stats['total_number_items'] = InventoryItem.where('project_id IN (?)', project_ids).count
        stats['total_number_projects'] = current_user.projects.count
        #stats['current_rent'] = InventoryItem.estimated_current_rent(project_ids)
        stats['inventory_by_type'] = InventoryItem.inventory_by_type(project_ids)
        # stats['occupation_by_month'] = InventoryItem.occupation_by_month

        render json: { stats: stats }, status: 200
      end

      def destroy
        item = InventoryItem.find(params[:id])
        item.destroy
        head 204
      end

      def re_entry
        @inventory_item = InventoryItem.find(params[:id])
        if ! @inventory_item.present?
          render json: { errors: "No se encontró el artículo." }, status: 422
          return
        end

        begin
          last_folio = InventoryTransaction.next_checkin_folio
          @inventory_item.add(
            params[:quantity].to_i, 
            params[:state], 
            params[:entry_date],
            'Reingreso',
            params[:delivery_company], 
            params[:delivery_company_contact], 
            params[:additional_comments],
            last_folio
          )
        rescue SilExceptions::InvalidQuantityToAdd => e
          render json: { errors: e.message }, status: 422 
        else
          render json: { success: '¡Has reingresado '+ params[:quantity].to_s + ' existencia(s) del artículo  "' +  @inventory_item.name + '"!' }, status: 201
        end

         
        #@todo: 
        # inventory_item.update({
        #   status: InventoryItem::IN_STOCK,
        #   state: params[:state]})
        # inventory_item.quantity = inventory_item.quantity.to_i + params[:quantity].to_i
        # if inventory_item.save
        #   @inventory_item = InventoryItem.where('actable_id = ? AND actable_type = ?', inventory_item.id, 'BulkItem').first
        #   log_checkin_transaction( params[:entry_date], @inventory_item.id, "Reingreso granel", '', params[:additional_comments], params[:delivery_company], params[:delivery_company_contact], params[:quantity])
        #   send_notifications_re_entry
        #   render json: { success: '¡Has reingresado '+ params[:quantity].to_s + ' existencia(s) del artículo  "' +  inventory_item.name + '"!' }, status: 201  
        #   return
        # end
    
        # render json: { errors: inventory_item.errors }, status: 422 
      end

      def quick_search
        if ! params[:keyword].present?
          render json: { errors: "La palabra clave no puede estar vacía." }, status: 422
          return
        end

        in_stock = true
        render json: InventoryItem.quick_search(params[:keyword], in_stock), status: 200  
      end

      private

      def inventory_item_params
        params.require(:inventory_item).permit(:name, :description, :project_id, :status, :item_img, :barcode, :item_type, :storage_type, :serial_number, :quantity, :brand, :model, :extra_parts, :value, :validity_expiration_date, :is_high_value, :user_id, :state)
      end

      def inventory_item_request_params
        params.require(:inventory_item_request).permit(:name, :description, :state, :quantity, :project_id, :pm_id, :ae_id, :item_type, :validity_expiration_date, :entry_date, :is_high_value)
      end

      def send_notification_authorize_entry
        project = @item.project
        users = User.where('role IN (?)', [User::ADMIN, User::WAREHOUSE_ADMIN])
        users.each do |u|
          u.notifications << Notification.create(title: 'Confirmación de entrada', inventory_item_id: @item.id, message: 'Se ha validado la entrada del artículo "' + @item.name + '" en el proyecto "' + project.name + '".')
        end
      end

      def send_notification_authorize_withdrawal
        project = @item.project
        users = project.users.where('role IN (?)', [User::ACCOUNT_EXECUTIVE, User::CLIENT])
        users.each do |u|
          u.notifications << Notification.create(title: 'Confirmación de salida', inventory_item_id: @item.id, message: 'Se ha aprobado la salida del artículo "' + @item.name + '" en el proyecto "' + project.name + '".')
        end
      end

      def send_entry_request_notifications
        admins = User.where('role IN (?)', [User::ADMIN, User::WAREHOUSE_ADMIN])
        admins.each do |admin|
          admin.notifications << Notification.create(title: 'Solicitud de entrada', inventory_item_id: -1, message: current_user.role_name + ' "' + current_user.first_name + ' ' + current_user.last_name + '" ha solicitado el ingreso del artículo "' + @inventory_item_request.name + '" para el día ' + @inventory_item_request.entry_date.strftime('%d/%m/%Y') + '.')
        end
      end

      def send_cancelled_entry_request_notifications
        return unless @cancelled

        if current_user.role == User::PROJECT_MANAGER || current_user.role == User::ACCOUNT_EXECUTIVE || current_user.role == User::CLIENT
          users = User.where('role IN (?)', [User::ADMIN, User::WAREHOUSE_ADMIN])
          message = 'El usuario ' + current_user.first_name + ' ' + current_user.last_name + ' ha cancelado la solicitud de entrada para el artículo "' + @inventory_item_request.name + '" del día ' + @inventory_item_request.entry_date.strftime('%d/%m/%Y') + '.'
        else
          users = User.where('id IN (?)', [@inventory_item_request.pm_id, @inventory_item_request.ae_id])
          message = 'Se ha rechazado tu solicitud de entrada para el artículo "' + @inventory_item_request.name + '" para el día ' + @inventory_item_request.entry_date.strftime('%d/%m/%Y') + ', ponte en contacto con el jefe de almacén para conocer el motivo.'
        end
        users.each do |admin|
          admin.notifications << Notification.create(title: 'Solicitud de entrada rechazada', inventory_item_id: -1, message: message)
        end
      end
    end
  end
end
