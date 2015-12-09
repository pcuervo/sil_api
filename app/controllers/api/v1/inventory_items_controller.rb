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

  private

    def inventory_item_params
      params.require(:inventory_item).permit(:name, :description, :project_id, :status, :item_img, :barcode, :item_type)
    end

end
