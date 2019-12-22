module Api
  module V1
    class InventoryTransactionsController < ApplicationController
      before_action only: %i[index get_check_ins get_check_outs] do
        authenticate_with_token! request.headers['Authorization']
      end
      before_action only: %i[by_project] do
        set_project_params 
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

      def by_folio
        transactions = InventoryTransaction.by_folio(params[:folio])
        render json: transactions, status: :ok
      end

      def latest
        type = params[:type]
        transactions = params[:num_transactions]

        render json: CheckInTransaction.latest(transactions), status: :ok and return if type == 'check_in'
        render json: CheckOutTransaction.latest(transactions), status: :ok and return if type == 'check_out'

        render json: { inventory_transactions: InventoryTransaction.latest(transactions) }, serializer: InventoryTransactionSerializer, status: :ok
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

      def cancel_folio
        folio = InventoryTransaction.by_folio(params[:folio])
        transactions = folio['inventory_transactions']

        if transactions.count.positive? 
          if transactions.first['actable_type'] == 'CheckOutTransaction'
            InventoryTransaction.cancel_checkout_folio(params[:folio])
            new_folio = CheckInTransaction.last.folio
          else
            InventoryTransaction.cancel_checkin_folio(params[:folio])
            new_folio = CheckOutTransaction.last.folio
          end

          render json: { 
              success: '¡El folio fue cancelado correctamente!',
              items: transactions.count,
              folio: new_folio
            }, 
            status: :ok
          return
        end
      
        render json: { error: 'No se encontró el folio' }, status: 422
      end

      def by_project
        transactions = InventoryTransaction.by_project(@project, @type, @start_date, @end_date)
        render json: transactions, each_serializer: LeanTransactionSerializer, status: :ok
      end

      private

        def set_project_params
          @project = Project.find(params[:project_id])
          @type = params[:type].nil? ? 'all' : params[:type]
          @start_date = params[:start_date].nil? ? nil : params[:start_date].to_date
          @end_date = params[:end_date].nil? ? nil : params[:end_date].to_date
        end
    end
  end
end
