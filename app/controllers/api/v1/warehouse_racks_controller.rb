class Api::V1::WarehouseRacksController < ApplicationController
  respond_to :json

  def index
    respond_with WarehouseRack.all
  end

  def show
    respond_with WarehouseRack.find( params[:id] )
  end
  
end
