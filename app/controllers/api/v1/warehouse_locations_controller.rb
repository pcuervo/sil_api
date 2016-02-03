class Api::V1::WarehouseLocationsController < ApplicationController
  respond_to :json

  def show
     respond_with WarehouseLocation.find(params[:id])
  end

  def index
    respond_with WarehouseLocation.all
  end

  def locate_item
    if params[:is_inventory_item]
      inventory_item = InventoryItem.find( params[:inventory_item_id] )
    else
      inventory_item = InventoryItem.find_by_actable_id( params[:inventory_item_id] )
    end
    location = WarehouseLocation.find( params[:warehouse_location_id] )
    new_location_id = location.locate( inventory_item.id, params[:units].to_i, params[:quantity] )

    if new_location_id > 0
      item_location = ItemLocation.find( new_location_id )
      item_location.update_status
      render json: item_location, status: 201, location: [:api, item_location]
      return
    end

    render json: { errors: 'No se pudo ubicar el artículo' }, status: 422
  end

  def locate_bundle
    if params[:is_inventory_item]
      inventory_item = InventoryItem.find( params[:inventory_item_id] )
    else
      inventory_item = InventoryItem.find_by_actable_id( params[:inventory_item_id] )
    end
    part_locations = params[:part_locations]
    locations = []

    part_locations.each do |pl|
      location = WarehouseLocation.find( pl[:locationId] )
      new_location_id = location.locate( inventory_item.id, pl[:units].to_i, 1, pl[:partId] )
      if new_location_id > 0
        locations.push( ItemLocation.find( new_location_id ) )
        next
      end

      render json: { errors: 'No se pudo ubicar el artículo' }, status: 422
      return
    end

    render json: { item_locations: locations }, status: 201
  end

end
