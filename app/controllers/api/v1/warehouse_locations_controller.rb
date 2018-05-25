class Api::V1::WarehouseLocationsController < ApplicationController
  require 'csv'

  before_action only: [:update, :locate_item, :locate_bundle, :csv_locate] do 
    authenticate_with_token! request.headers['Authorization']
  end
  respond_to :json

  def show
     respond_with WarehouseLocation.find(params[:id]).get_details
  end

  def index
    respond_with WarehouseLocation.all
  end

  def update
    warehouse_location = WarehouseLocation.find( params[:id] )

    if warehouse_location.update(warehouse_location_params)
      render json: warehouse_location, status: 200, location: [:api, warehouse_location]
    else
      render json: { errors: warehouse_location.errors }, status: 422
    end
  end

  def locate_item
    if params[:is_inventory_item]
      inventory_item = InventoryItem.find( params[:inventory_item_id] )
    else
      inventory_item = InventoryItem.where( 'actable_type = ? AND actable_id = ?', params[:actable_type], params[:inventory_item_id] ).first
    end
    location = WarehouseLocation.find( params[:warehouse_location_id] )
    new_location_id = location.locate( inventory_item.id, params[:units].to_i, params[:quantity] )

    if new_location_id > 0
      item_location = ItemLocation.find( new_location_id )
      render json: item_location, status: 201, location: [:api, item_location]
      return
    end

    render json: { errors: 'No se pudo ubicar el artículo' }, status: 422
  end

  def locate_bundle
    if params[:is_inventory_item]
      inventory_item = InventoryItem.find( params[:inventory_item_id] )
    else
      inventory_item = InventoryItem.where( 'actable_type = "BundleItem" AND actable_id = ?', params[:actable_type] ).first
    end
    part_locations = params[:part_locations]
    locations = []

    part_locations.each do |pl|
      location = WarehouseLocation.find( pl[:locationId] )
      new_location_id = location.locate( inventory_item.id, pl[:units].to_i, 1, pl[:partId] )
      if new_location_id > 0
        location.update_status
        locations.push( ItemLocation.find( new_location_id ) )
        next
      end

      render json: { errors: 'No se pudo ubicar el artículo' }, status: 422
      return
    end

    render json: { item_locations: locations }, status: 201
  end

  def locate_bulk
    if params[:is_inventory_item]
      inventory_item = InventoryItem.find( params[:inventory_item_id] )
    else
      inventory_item = InventoryItem.where( 'actable_type = "BulkItem" AND actable_id = ?', params[:inventory_item_id] ).first
    end
    bulk_locations = params[:bulk_locations]
    locations = []

    bulk_locations.each do |bl|
      location = WarehouseLocation.find( bl[:locationId] )
      new_location_id = location.locate( inventory_item.id, bl[:units].to_i, bl[:quantity], 0 )
      if new_location_id > 0
        locations.push( ItemLocation.find( new_location_id ) )
        next
      end

      render json: { errors: 'No se pudo ubicar el artículo' }, status: 422
      return
    end

    render json: { item_locations: locations }, status: 201
  end

  def relocate_item
    item_location = ItemLocation.find( params[:item_location_id] )
    location = WarehouseLocation.find( params[:new_location_id] )
    new_location_id = location.relocate( item_location.id, item_location.units, item_location.quantity )

    if new_location_id > 0
      item_location = ItemLocation.find( new_location_id )
      location.item_locations << item_location
      location.update_status
      render json: item_location, status: 201, location: [:api, item_location]
      return
    end

    render json: { errors: 'No se pudo ubicar el artículo, la ubicación "' + location.name + '" se encuentra llena.' }, status: 422
  end

  def mark_as_full 
    location = WarehouseLocation.find( params[:location_id] )
    location.mark_as_full
    render json: { success: 'Ubiación marcada como llena.' }, status: 200
  end

  def mark_as_available 
    location = WarehouseLocation.find( params[:location_id] )
    location.mark_as_available
    render json: { success: 'Ubiación marcada como disponible.' }, status: 200
  end

  def csv_locate
    warehouse_update = WarehouseLocation.bulk_locate( current_user.email, params[:warehouse_data] )  
    if warehouse_update[:errors].count == 0
      render json: { success: 'Los artículos se ubicarion correctamente.' }, status: 200
      return
    end

    render json: { errors: warehouse_update[:errors], located_items: warehouse_update[:located_items] }, status: 200 
  end

  private

    def warehouse_location_params
      params.require(:warehouse_location).permit( :name, :units )
    end

end
