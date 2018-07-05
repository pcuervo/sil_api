module Api
  module V1
    class NotificationsController < ApplicationController
      before_action only: %i[unread read num_unread mark_as_read index] do
        authenticate_with_token! request.headers['Authorization']
      end
      respond_to :json

      def index
        respond_with current_user.notifications.unread_first
      end

      def num_unread
        render json: { unread_notifications: current_user.notifications.unread.count }, status: 200
        nil
      end

      def unread
        respond_with current_user.notifications.unread
        nil
      end

      def read
        respond_with current_user.notifications.read
        nil
      end

      def mark_as_read
        notifications = current_user.notifications
        notifications.where('status = ?', Notification::UNREAD).update_all(status: Notification::READ)
        head 204
      end

      def destroy
        notification = Notification.find(params[:id])
        notification.destroy
        head 204
      end
    end
  end
end
