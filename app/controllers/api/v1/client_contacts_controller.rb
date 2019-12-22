module Api
  module V1
    class ClientContactsController < ApplicationController
      before_action only: [:stats] do
        authenticate_with_token! request.headers['Authorization']
      end
      respond_to :json

      def show
        respond_with ClientContact.find(params[:id])
      end

      def by_user
        user = User.find(params[:id])
        respond_with ClientContact.find(user.actable_id)
      end

      def index
        respond_with ClientContact.all.order(:created_at)
      end

      def update
        client_contact = ClientContact.find(params[:id])

        if client_contact.update(client_contact_params)
          render json: client_contact, status: 201, location: [:api, client_contact]
          return
        end

        render json: { errors: client_contact.errors }, status: 422
      end

      def destroy
        client_contact = ClientContact.find(params[:id])
        client_contact.delivery_requests.destroy_all
        client_contact.deliveries.destroy_all

        client_contact.destroy
        render json: client_contact, status: 200
      end

      def by_client
        client_contacts = ClientContact.where('client_id = ?', params[:id])
        respond_with client_contacts
      end

      def inventory_items
        user = User.find(params[:id])
        client_contact = ClientContact.find(user.actable_id)
        render json: client_contact.inventory_items(params[:in_stock]), status: 200
      end

      def stats
        project_ids = []
        client_contact = if current_user.role == 6
                           ClientContact.find(current_user.actable_id)
                         else
                           ClientContact.find(params[:id])
                         end

        client_contact.client.projects.each { |p| project_ids.push(p.id) }

        stats = {
          'inventory_by_type' => InventoryItem.inventory_by_type(project_ids),
          'total_number_items' => client_contact.inventory_items.count,
          'total_high_value_items' => client_contact.total_high_value_items
        }

        render json: { stats: stats }, status: 200
      end

      private

      def client_contact_params
        params.require(:client_contact).permit(:first_name, :last_name, :password, :password_confirmation, :phone, :phone_ext, :email, :business_unit, :client_id, :discount)
      end
    end
  end
end
