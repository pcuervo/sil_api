module Api
  module V1
    class InventoryTransactionsController < ApplicationController
      before_action only: %i[index get_check_ins get_check_outs] do
        authenticate_with_token! request.headers['Authorization']
      end
      respond_to :json

      def show
        respond_with InventoryTransaction.find(params[:id]).get_details
      end

      def index
        respond_with InventoryTransaction.search(params, current_user)
      end

      def search
        transactions = InventoryTransaction.better_search(params[:keyword], current_user)
        render json: transactions, status: :ok
      end

      def check_ins
        respond_with InventoryTransaction.check_ins
      end

      def check_outs
        respond_with InventoryTransaction.check_outs
      end

      def last_checkout_folio
        last_folio = CheckOutTransaction.where('folio != ?', '-').order(folio: :desc).first
        return render json: { folio: last_folio.folio }, status: :ok if last_folio.present?

        render json: { folio: 'FS-0000000' }, status: :ok
      end

      def last_checkin_folio
        last_folio = CheckInTransaction.where('folio != ?', '-').order(folio: :desc).first
        return render json: {folio: last_folio.folio}, status: :ok if last_folio.present?

        render json: { folio: 'FE-0000000' }, status: :ok
      end

      def check_outs_by_client
        user = User.find(params[:id])
        client_user = ClientContact.find(user.actable_id)
        respond_with InventoryTransaction.check_outs_by_client(client_user)
      end

      def by_folio
        transactions = InventoryTransaction.by_folio(params[:folio])
        render json: transactions, status: :ok
      end

      def latest
        type = params[:type]
        transactions = params[:num_transactions]

        render json: CheckInTransaction.latest(transactions), status: :ok and return if type == 'check_in'
        render json: CheckOutTransaction.latest(transactions), status: :ok and return if type == 'check_out'

        render json: InventoryTransaction.latest(transactions), status: :ok
      end

      def latest_by_user
        type = params[:type]
        num = params[:num_transactions]
        user = User.find(params[:user_id])
        item_ids = []

        user.projects.each { |p| p.inventory_items.pluck(:id).map { |id| item_ids.push(id) } }

        transaction_ids = InventoryTransaction.where('inventory_item_id IN (?)', item_ids).limit(num).pluck(:actable_id)

        if type == 'check_in'
          checkin_transactions = CheckInTransaction.where('id IN (?)', transaction_ids).order(folio: :desc)
          render json: checkin_transactions, status: :ok and return
        end
        
      end
    end
  end
end
