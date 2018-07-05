module Api
  module V1
    class WarehouseTransactionsController < ApplicationController
      respond_to :json

      def index
        respond_with WarehouseTransaction.details
      end
    end
  end
end
