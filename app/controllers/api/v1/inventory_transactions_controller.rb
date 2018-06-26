module Api
  module V1
    class InventoryTransactionsController < ApplicationController
      before_action only: %i[index get_check_ins get_check_outs] do
        authenticate_with_token! request.headers["Authorization"]
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

      def get_check_ins
        respond_with InventoryTransaction.check_ins
      end

      def get_check_outs
        respond_with InventoryTransaction.check_outs
      end

      def last_checkout_folio
        last_folio = CheckOutTransaction.where('folio != ?', '-').last.folio
        return render json: {folio: last_folio}, status: :ok if last_folio.present?

        render json: {folio: "FS-0000000"}, status: :ok
      end

      def last_checkin_folio
        last_folio = CheckInTransaction.where('folio != ?', '-').last
        return render json: {folio: last_folio.last}, status: :ok if last_folio.present?

        render json: {folio: "FE-0000000"}, status: :ok
      end

      def get_check_outs_by_client
        user = User.find(params[:id])
        client_user = ClientContact.find(user.actable_id)
        respond_with InventoryTransaction.check_outs_by_client(client_user)
      end

      def by_folio
        transactions = InventoryTransaction.by_folio(params[:folio])
        render json: transactions, status: :ok
      end
    end
  end
end
