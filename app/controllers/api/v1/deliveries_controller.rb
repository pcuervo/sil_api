module Api
  module V1
    class DeliveriesController < ApplicationController
      before_action only: %i[index by_delivery_man create] do
        authenticate_with_token! request.headers['Authorization']
      end
      after_action :send_new_delivery_notifications, only: [:create]
      respond_to :json

      def show
        respond_with Delivery.find(params[:id]).details
      end

      def index
        deliveries = if params[:recent]
                       Delivery.recent
                     else
                       Delivery.all.order(updated_at: :desc)
                     end

        if params[:status].present?
          deliveries = if params[:status] == 'pending'
                         Delivery.where('status NOT IN (?)', [Delivery::DELIVERED, Delivery::REJECTED, Delivery::PARTIALLY_DELIVERED, Delivery::PENDING_APPROVAL]).order(updated_at: :desc)
                       else
                         Delivery.where('status IN (?)', [Delivery::DELIVERED, Delivery::REJECTED, Delivery::PARTIALLY_DELIVERED]).order(updated_at: :desc)
                       end
        end

        if params[:user_role].present?
          deliveries = deliveries.where('user_id = ?', current_user.id) if params[:user_role].to_i != 1 && params[:user_role].to_i != 4
        end

        respond_with deliveries
      end

      def by_delivery_man
        deliveries = if params[:status] == 'pending'
                       Delivery.where('delivery_user_id = ? AND status NOT IN (?)', current_user.id, [Delivery::DELIVERED, Delivery::REJECTED, Delivery::PARTIALLY_DELIVERED]).order(updated_at: :desc)
                     else
                       Delivery.where('delivery_user_id = ? AND status IN (?)', current_user.id, [Delivery::DELIVERED, Delivery::REJECTED, Delivery::PARTIALLY_DELIVERED]).order(updated_at: :desc)
                     end

        render json: deliveries.order(date_time: :desc), status: 200
      end

      def create
        @delivery_user = User.find(params[:user_id])
        @delivery = Delivery.new(delivery_params)
        @delivery_user.deliveries << @delivery

        @delivery.status = Delivery::PENDING_APPROVAL if [User::PROJECT_MANAGER, User::ACCOUNT_EXECUTIVE, User::CLIENT].include? @delivery_user.role

        if @delivery.save!
          items = params[:inventory_items]
          @delivery.add_items(items, @delivery_user.first_name + ' ' + @delivery_user.last_name, 'Salida por envío a ' + @delivery.company + '. Recibe: ' + @delivery.addressee + '.')

          send_delivery_request_notifications if Delivery::PENDING_APPROVAL == @delivery.status

          log_action(current_user.id, 'Envío', "Envío de #{items.count} artículos.", @delivery.folio) 

          render json: @delivery, status: 201, location: [:api, @delivery]
        else
          render json: { errors: @delivery.errors }, status: 422
        end
      end

      def update
        @delivery = Delivery.find(params[:id])
        previous_status = @delivery.status

        if params[:image]
          image = Paperclip.io_adapters.for(params[:image])
          image.original_filename = params[:filename]
          @delivery.image = image
        end

        if @delivery.update(delivery_params)
          send_delivery_approval_notifications if Delivery::PENDING_APPROVAL == previous_status
          send_delivered_notifications if Delivery::DELIVERED == @delivery.status
          send_rejected_notifications if Delivery::REJECTED == @delivery.status
          render json: @delivery, status: 200, location: [:api, @delivery]
          return
        end

        render json: { errors: @delivery.errors }, status: 422
      end

      def pending_approval
        respond_with Delivery.pending_approval
      end

      def stats
        stats = {}

        shipped = Delivery.shipped.count
        delivered = Delivery.delivered.count
        rejected = Delivery.rejected.count

        stats['shipped'] = shipped
        stats['delivered'] = delivered
        stats['rejected'] = rejected

        render json: { stats: stats }, status: 200
      end

      def by_delivery_item
        render json: { deliveries: DeliveryItem.by_delivery_item(params[:inventory_item_id]) }, status: 200
      end

      def by_keyword
        deliveries = Delivery.by_keyword(params)
        render json: { deliveries: deliveries }, status: :ok
      end

      private

      def delivery_params
        params.require(:delivery).permit(:delivery_user_id, :company, :address, :addressee, :addressee_phone, :image, :latitude, :longitude, :status, :additional_comments, :date_time, :supplier_id)
      end

      def send_delivery_request_notifications
        admins = User.where('role IN (?)', [User::ADMIN, User::WAREHOUSE_ADMIN])
        admins.each do |admin|
          admin.notifications << Notification.create(title: 'Solicitud de envío', inventory_item_id: -1, message: @delivery_user.role_name + ' "' + @delivery_user.first_name + ' ' + @delivery_user.last_name + '" ha solicitado un envío.')
        end
      end

      def send_delivery_approval_notifications
        user = @delivery.user
        user.notifications << Notification.create(title: 'Aprobación de envío', inventory_item_id: -1, message: 'Se ha aprobado tu solicitud de envío.')
      end

      def send_delivered_notifications
        user = @delivery.user
        user.notifications << Notification.create(title: 'Envío entregado', inventory_item_id: -1, message: 'Se ha entregado el envío de ' + @delivery.delivery_items.count.to_s + ' artículo(s) que solicitaste para "' + @delivery.company + '" el día ' + @delivery.date_time.strftime('%d/%m/%Y') + '.')
        admins = User.where('role IN (?)', [User::ADMIN, User::WAREHOUSE_ADMIN])
        admins.each do |admin|
          next if admin.email == user.email

          admin.notifications << Notification.create(title: 'Envío entregado', inventory_item_id: -1, message: 'Se ha entregado el envío de ' + @delivery.delivery_items.count.to_s + ' artículo(s) que solicitaste para "' + @delivery.company + '" el día ' + @delivery.date_time.strftime('%d/%m/%Y') + '.')
        end
      end

      def send_rejected_notifications
        user = @delivery.user
        user.notifications << Notification.create(title: 'Envío rechazado', inventory_item_id: -1, message: 'Se ha rechazado el envío de ' + @delivery.delivery_items.count.to_s + ' artículo(s) que solicitaste para "' + @delivery.company + '" el día ' + @delivery.date_time.strftime('%d/%m/%Y') + '. Por favor ponte en contacto con el jefe de almacén para conocer el motivo.')
        admins = User.where('role IN (?)', [User::ADMIN, User::WAREHOUSE_ADMIN])
        admins.each do |admin|
          next if admin.email == user.email

          admin.notifications << Notification.create(title: 'Envío rechazado', inventory_item_id: -1, message: 'Se ha rechazado el envío de ' + @delivery.delivery_items.count.to_s + ' artículo(s) que solicitaste para "' + @delivery.company + '" el día ' + @delivery.date_time.strftime('%d/%m/%Y') + '. Por favor ponte en contacto con el repartidor para conocer el motivo.')
        end
      end

      def send_new_delivery_notifications
        return if @delivery.delivery_user_id.to_i == -1

        delivery_guy = User.find(@delivery.delivery_user_id)

        return unless delivery_guy.present?

        delivery_guy.notifications << Notification.create(title: 'Nuevo envío', inventory_item_id: -1, message: 'Te han asignado un envío para el día ' + @delivery.date_time.strftime('%d/%m/%Y') + '. Por favor ponte en contacto con el jefe de almacén.')
      end
    end
  end
end
