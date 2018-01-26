class Api::V1::InventoryTransactionsController < ApplicationController
  before_action only: [:index, :get_check_ins, :get_check_outs] do 
    authenticate_with_token! request.headers['Authorization']
  end
  respond_to :json
  
  def show
    respond_with InventoryTransaction.find(params[:id]).get_details
  end

  def index
    respond_with InventoryTransaction.search( params, current_user )
  end

  def search 
    puts params.to_yaml
    transactions = InventoryTransaction.better_search( params[:keyword], current_user )
    render json: transactions, status: 200
  end

  def get_check_ins
    respond_with InventoryTransaction.check_ins
  end

  def get_check_outs
    respond_with InventoryTransaction.check_outs
  end

  def get_check_outs_by_client
    user = User.find( params[:id] )
    client_user = ClientContact.find( user.actable_id )
    respond_with InventoryTransaction.check_outs_by_client( client_user )
  end

end
