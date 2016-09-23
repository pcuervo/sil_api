class Api::V1::DeliveryRequestsController < ApplicationController
  after_action :send_delivery_request_notifications, only: [:create]
  after_action :send_delivery_approved_notifications, only: [:authorize_delivery]
  after_action :send_delivery_rejected_notifications, only: [:reject_delivery]
  respond_to :json

  def index
    respond_with DeliveryRequest.all
  end

  def show
    respond_with DeliveryRequest.find( params[:id] )
  end

  def create

    if ! params[:inventory_items].present?
      render json: { errors: 'La solicitud de envío no contiene artículos.' }, status: 422
      return
    end

    @delivery_request = DeliveryRequest.new( delivery_request_params )
    user = current_user

    @delivery_request.user = user
    params[:inventory_items].each do |item|
      item_request = DeliveryRequestItem.create( :inventory_item_id => item[:item_id], :quantity => item[:quantity] )
      @delivery_request.delivery_request_items << item_request
    end

    if @delivery_request.save!
      @delivery_request.update_items_status_to_pending
      render json: @delivery_request, status: 201
      return
    end
    
    render json: { errors: @delivery_request.errors }, status: 422
  end

  def authorize_delivery
    @delivery_request = DeliveryRequest.find( params[:id] )
    @approved = @delivery_request.authorize( params[:delivery_user_id], params[:supplier_id], params[:additional_comments], params[:quantities] )
    if @approved
      render json: { success: '¡Se ha autorizado el envío! Se le enviará una notificación al usuario que la solicitó.' }, status: 201
      return
    end

    render json: { errors: 'Ha ocurrido un error, no se pudo realizar el envío en este momento.' }, status: 201
  end

  def reject_delivery
    @delivery_request = DeliveryRequest.find( params[:id] )
    @delivery_request.set_items_in_stock
    puts 'after setting status'
    @delivery_request.destroy
    render json: { success: '¡Se ha rechazado el envío! Se le enviará una notificación al usuario que la solicitó.' }, status: 201
  end

  def cancel_delivery
    @delivery_request = DeliveryRequest.find( params[:id] )
    @delivery_request.set_items_in_stock
    @delivery_request.destroy
    render json: { success: '¡Se ha cancelado el envío!' }, status: 201
  end

  private

    def delivery_request_params
      params.require(:delivery_request).permit( :company, :addressee, :addressee_phone, :address, :latitude, :longitude, :additional_comments, :date_time )
    end

    def send_delivery_request_notifications
      admins = User.where( 'role IN (?)', [ User::ADMIN, User::WAREHOUSE_ADMIN ]  )
      admins.each do |admin|
        admin.notifications << Notification.create( :title => 'Solicitud de envío', :inventory_item_id => -1, :message => current_user.get_role + ' "' + current_user.first_name + ' ' + current_user.last_name + '" ha solicitado un envío para el día ' + @delivery_request.date_time.strftime("%d/%m/%Y %H:%M") + '.' )
      end
    end 

    def send_delivery_approved_notifications
      user = @delivery_request.user
      user.notifications << Notification.create( :title => 'Aprobación de envío', :inventory_item_id => -1, :message => 'Se ha aprobado el envío que solicitaste para el día ' + @delivery_request.date_time.strftime("%d/%m/%Y") + '.' )
    end 

    def send_delivery_rejected_notifications
      user = @delivery_request.user
      user.notifications << Notification.create( :title => 'Rechazo de envío', :inventory_item_id => -1, :message => 'Se ha rechazado el envío que solicitaste para el día ' + @delivery_request.date_time.strftime("%d/%m/%Y") + '.' )
    end 
end
