class Api::V1::InventoryTransactionsController < ApplicationController
  respond_to :json
  
  def show
    respond_with InventoryTransaction.find(params[:id]).get_details
  end

  def index
    respond_with InventoryTransaction.search( params )
  end

  def get_check_ins
    respond_with InventoryTransaction.check_ins
  end

  def get_check_outs
    respond_with InventoryTransaction.check_outs
  end

end
