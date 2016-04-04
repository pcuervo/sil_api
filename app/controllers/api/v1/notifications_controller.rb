class Api::V1::NotificationsController < ApplicationController
  respond_to :json

  def index 
    respond_with current_user.notifications.unread_first
  end

  def get_num_unread
    notifications = 0
    if ! current_user.notifications.nil? 
      notifications = current_user.notifications.unread.count
    end
    render json: { unread_notifications: notifications }, status: 200
  end

  def get_unread
    puts current_user.to_yaml
    respond_with current_user.notifications.unread
  end

  def get_read
    respond_with current_user.notifications.read
  end

  def mark_as_read
    Notification.where( 'status = ?', Notification::UNREAD ).update_all( status: Notification::READ )
    head 204
  end
  
  def destroy
    notification = Notification.find( params[:id] )
    notification.destroy
    head 204
  end

end
