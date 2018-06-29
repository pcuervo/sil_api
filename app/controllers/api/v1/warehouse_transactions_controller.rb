class Api::V1::WarehouseTransactionsController < ApplicationController
  respond_to :json

  def index
    respond_with WarehouseTransaction.details
  end
end
