class Api::V1::WarehouseRacksController < ApplicationController
  respond_to :json

  def index
    respond_with WarehouseRack.all
  end

  def show
    respond_with WarehouseRack.find( params[:id] )
  end

  def get_available_locations
    rack = WarehouseRack.find( params[:id] )
    respond_with rack.available_locations
  end
  
end
