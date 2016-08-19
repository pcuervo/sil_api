class Api::V1::NotificationsController < ApplicationController
  before_action :authenticate_with_token!, only: [:get_unread, :get_read]
  respond_to :json

  def index 
    respond_with current_user.notifications.unread_first
  end

  def get_num_unread
    if user_signed_in?
      render json: { unread_notifications: current_user.notifications.unread.count }, status: 200
      return
    end
    render json: { error: 'La sesión ha caducado.' }, status: 200
  end

  def get_unread
    respond_with current_user.notifications.unread
  end

  def get_read
    respond_with current_user.notifications.read
  end

  def mark_as_read
    notifications = current_user.notifications
    notifications.where( 'status = ?', Notification::UNREAD ).update_all( status: Notification::READ )
    head 204
  end
  
  def destroy
    notification = Notification.find( params[:id] )
    notification.destroy
    head 204
  end

end
