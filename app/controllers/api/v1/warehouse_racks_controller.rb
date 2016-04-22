class Api::V1::WarehouseRacksController < ApplicationController
  respond_to :json

  def index
    respond_with WarehouseRack.more_info
  end

  def show
    respond_with WarehouseRack.find( params[:id] )
  end

  def show_details
    rack = WarehouseRack.find( params[:id] )
    respond_with rack.details
  end

  def get_available_locations
    rack = WarehouseRack.find( params[:id] )
    respond_with rack.available_locations
  end

  def create
    warehouse_rack = WarehouseRack.new( warehouse_rack_params )

    if warehouse_rack.save
      warehouse_rack.add_initial_locations( params[:units].to_i )
      log_action( current_user.id, 'WarehouseRack', 'Se ha creado el Rack: "' + warehouse_rack.name + '" con ' + warehouse_rack.warehouse_locations.count.to_s + ' ubicaciones.', warehouse_rack.id )
      render json: warehouse_rack, status: 201, location: [:api, warehouse_rack]
      return
    end

    render json: { errors: warehouse_rack.errors }, status: 422 
  end

  def get_items
    rack = WarehouseRack.find( params[:id] )
    respond_with rack.items
  end

  def destroy
    rack = WarehouseRack.find( params[:id] )
    if rack.is_empty? 
      rack.warehouse_locations.each do |l| 
        l.warehouse_transactions.destroy_all
        l.destroy 
      end
      rack.destroy
      head 204
      return
    end
    render json: { errors: "No se puede eliminar un rack con ubicaciones ocupadas" }, status: 422 
  end

  def stats
    stats = {}

    total_racks = WarehouseRack.all.count
    total_locations = WarehouseLocation.all.count
    total_occupied_locations = ItemLocation.all.count
    total_items_in_warehouse = ItemLocation.select("inventory_item_id").distinct.count
    total_items_with_pending_location = InventoryItem.joins('LEFT JOIN item_locations ON inventory_items.id = item_locations.inventory_item_id ').where(' item_locations.id is null AND inventory_items.status IN (?)', [ InventoryItem::IN_STOCK, InventoryItem::PARTIAL_STOCK ]).count
    warehouse_occupation_percentage = ( total_occupied_locations.to_i / total_locations.to_f * 100 ).round

    stats['total_racks'] = total_racks 
    stats['total_locations'] = total_locations 
    stats['total_occupied_locations'] = total_occupied_locations 
    stats['total_items_in_warehouse'] = total_items_in_warehouse 
    stats['total_items_with_pending_location'] = total_items_with_pending_location 
    stats['warehouse_occupation_percentage'] = warehouse_occupation_percentage 

    render json: { stats: stats }, status: 200
  end

  private

    def warehouse_rack_params
      params.require(:warehouse_rack).permit(:name, :row, :column)
    end
  
end
