class Api::V1::WithdrawRequestsController < ApplicationController
  before_action only: [:create, :authorize_withdrawal, :cancel_withdrawal] do 
    authenticate_with_token! request.headers['Authorization']
  end
  after_action :send_withdrawal_request_notifications, only: [:create]
  after_action :send_withdrawal_approve_notifications, only: [:authorize_withdrawal]
  after_action :send_withdrawal_cancel_notifications, only: [:cancel_withdrawal]
  respond_to :json

  def show
    respond_with WithdrawRequest.find( params[:id] )
  end

  def index
    respond_with WithdrawRequest.all
  end

  def create

    if ! params[:withdraw_request][:inventory_items].present?
      render json: { errors: 'La solicitud de salida no contiene artículos.' }, status: 422
      return
    end

    @withdraw_request = WithdrawRequest.new( withdraw_request_params )
    user = current_user

    @withdraw_request.user = user
    params[:withdraw_request][:inventory_items].each do |item|
      item_request = WithdrawRequestItem.create( :inventory_item_id => item[:inventory_item_id], :quantity => item[:quantity] )
      @withdraw_request.withdraw_request_items << item_request
    end

    if @withdraw_request.save!
      @withdraw_request.update_items_status_to_pending
      render json: @withdraw_request, status: 201
    else
      render json: { errors: @withdraw_request.errors }, status: 422
    end
  end

  def authorize_withdrawal
    @withdraw_request = WithdrawRequest.find( params[:id] )
    @approved = @withdraw_request.authorize( params[:pickup_company_contact], params[:additional_comments], params[:quantities] )
    if @approved
      render json: { success: '¡Se ha autorizado la salida! Se le enviará una notificación al usuario que la solicitó.' }, status: 201
      return
    end

    render json: { errors: 'Ha ocurrido un error, no se pudo realizar la salida en este momento.' }, status: 201
  end

  def cancel_withdrawal
    @withdraw_request = WithdrawRequest.find( params[:id] )
    @cancelled = @withdraw_request.cancel
    if @cancelled
      render json: { success: '¡Se ha cancelado la salida!' }, status: 201
      return
    end

    render json: { errors: 'Ha ocurrido un error, no se pudo realizar la cancelación en este momento.' }, status: 201
  end

  def by_user
    respond_with WithdrawRequest.where( 'user_id = ?', params[:id] )
  end

  private

    def withdraw_request_params
      params.require(:withdraw_request).permit( :exit_date, :pickup_company_id )
    end

    def send_withdrawal_request_notifications
      admins = User.where( 'role IN (?)', [ User::ADMIN, User::WAREHOUSE_ADMIN ]  )
      admins.each do |admin|
        admin.notifications << Notification.create( :title => 'Solicitud de salida', :inventory_item_id => -1, :message => current_user.role_name + ' "' + current_user.first_name + ' ' + current_user.last_name + '" ha solicitado una salida para el día ' + @withdraw_request.exit_date.strftime("%d/%m/%Y") + '.' )
      end
    end 

    def send_withdrawal_approve_notifications
      if @approved
        user = @withdraw_request.user
        user.notifications << Notification.create( :title => 'Aprobación de salida', :inventory_item_id => -1, :message => 'Se ha aprobado la salida que solicitaste para el día ' + @withdraw_request.exit_date.strftime("%d/%m/%Y") + '.' )
      end
    end 


    def send_withdrawal_cancel_notifications
      return if ! @cancelled

      if  1 == current_user.role || 4 == current_user.role
        user = @withdraw_request.user
        user.notifications << Notification.create( :title => 'Cancelación de solicitud salida', :inventory_item_id => -1, :message => 'Se ha cancelado la salida que solicitaste para el día ' + @withdraw_request.exit_date.strftime("%d/%m/%Y") + ', ponte en contacto con un ejecutivo de cuenta para conocer el motivo.' )
        return
      end
      # Send notification to Admins when user cancels its own WithdrawRequest
      users = User.where('role IN (?)', [ User::ADMIN, User::WAREHOUSE_ADMIN ] )
      users.each do |admin|
        admin.notifications << Notification.create( :title => 'Solicitud de entrada rechazada', :inventory_item_id => -1, :message => 'El usuario ' + current_user.first_name + ' ' + current_user.last_name + ' ha cancelado la salida que solicitó para el día ' + @withdraw_request.exit_date.strftime("%d/%m/%Y") + '.' )
      end
    end 

end
