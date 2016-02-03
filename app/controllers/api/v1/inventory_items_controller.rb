class Api::V1::InventoryItemsController < ApplicationController
  before_action :authenticate_with_token!, only: [:create]
  respond_to :json

  def index
    respond_with InventoryItem.search( params )
  end

  def show
    respond_with InventoryItem.find(params[:id]).get_details
  end

  def create

    inventory_item = current_user.inventory_items.build(inventory_item_params)

    if inventory_item.save
      render json: inventory_item, status: 201, location: [:api, inventory_item]
    else
      render json: { errors: inventory_item.errors }, status: 422
    end
  end

  def by_barcode
    inventory_item = InventoryItem.find_by_barcode(params[:barcode])

    if inventory_item.present?
      respond_with inventory_item.get_details
      return
    end
    
    render json: { errors: 'No se encontró ningún artículo' }, status: 422

  end

  def by_type
    respond_with InventoryItem.where( 'actable_type=?', params[:type] )
  end

  def pending_entry
    respond_with InventoryItem.where( 'status=?', InventoryItem::PENDING_ENTRY )
  end

  def authorize_entry
    item = InventoryItem.find( params[:id] )
    item.status = InventoryItem::IN_STOCK
    item.save
    render json: { success: '¡Se ha aprobado el ingreso del artículo "' + item.name + '"!' }, status: 201
  end

  def with_pending_location
    respond_with InventoryItem.joins('LEFT JOIN item_locations ON inventory_items.id = item_locations.inventory_item_id WHERE item_locations.id is null').order(updated_at: :desc)
  end

  private
    def inventory_item_params
      params.require(:inventory_item).permit(:name, :description, :project_id, :status, :item_img, :barcode, :item_type)
    end

end
