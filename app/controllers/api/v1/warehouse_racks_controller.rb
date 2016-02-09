class Api::V1::WarehouseRacksController < ApplicationController
  respond_to :json

  def index
    respond_with WarehouseRack.all
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

  private

    def warehouse_rack_params
      params.require(:warehouse_rack).permit(:name, :row, :column)
    end
  
end
