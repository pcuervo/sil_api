class Api::V1::WarehouseLocationsController < ApplicationController
  respond_to :json

  def show
     respond_with WarehouseLocation.find(params[:id])
  end

  def index
    respond_with WarehouseLocation.all
  end
end
