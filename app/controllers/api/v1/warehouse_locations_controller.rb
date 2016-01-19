class Api::V1::WarehouseLocationsController < ApplicationController
  respond_to :json

  def show
     respond_with WarehouseLocation.find(params[:id])
  end

  def index
    respond_with WarehouseLocation.all
  end

  def locate_item
    location = WarehouseLocation.find( params[:warehouse_location_id] )
    inventory_item = InventoryItem.find_by_actable_id( params[:inventory_item_id] )
    new_location_id = location.locate( inventory_item.id, params[:units].to_i, params[:quantity] )

    if new_location_id > 0
      item_location = ItemLocation.find( new_location_id )
      render json: item_location, status: 201, location: [:api, item_location]
      return
    end

    render json: { errors: 'No se pudo ubicar el artículo' }, status: 422
  end

end
