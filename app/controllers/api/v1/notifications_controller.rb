class Api::V1::NotificationsController < ApplicationController
  before_action only: [:get_unread, :get_read, :get_num_unread, :mark_as_read] do 
    authenticate_with_token! request.headers['Authorization']
  end
  respond_to :json

  def index 
    respond_with current_user.notifications.unread_first
  end

  def get_num_unread
    render json: { unread_notifications: current_user.notifications.unread.count }, status: 200
    return
  end

  def get_unread
    respond_with current_user.notifications.unread
    return
  end

  def get_read
    respond_with current_user.notifications.read
    return
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
