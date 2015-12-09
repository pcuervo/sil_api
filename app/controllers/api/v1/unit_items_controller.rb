class Api::V1::UnitItemsController < ApplicationController
  respond_to :json
  
  def show
    respond_with UnitItem.find(params[:id])
  end

  def index
    respond_with UnitItem.all
  end

  def create

    unit_item = UnitItem.new(unit_item_params)
    unit_item.user = current_user

    # Paperclip adaptor 
    item_img = Paperclip.io_adapters.for(params[:item_img])
    item_img.original_filename = params[:filename]
    unit_item.item_img = item_img

    if unit_item.save
      inventory_item = InventoryItem.find_by_actable_id(unit_item.id)
      log_checkin_transaction( params[:entry_date], inventory_item.id, "Entrada unitaria", params[:storage_type], params[:estimated_issue_date], params[:additional_comments], params[:delivery_company], params[:delivery_company_contact], 1)
      log_action( current_user.id, 'InventoryItem', 'Created unit item "' + unit_item.name + '"', inventory_item.id )
      render json: unit_item, status: 201, location: [:api, unit_item]
      return
    end

    render json: { errors: unit_item.errors }, status: 422
  end

  def withdraw
    unit_item = UnitItem.find_by_id(params[:id])

    if ! unit_item.present?
      render json: { errors: "No se encontró el artículo." }, status: 422
      return
    end

    case unit_item.status
    when InventoryItem::OUT_OF_STOCK
      render json: { errors: 'No se pudo completar la salida por que el artículo "' + unit_item.name + '" no se encuentra en existencia.' }, status: 422
      return
    when InventoryItem::PENDING_ENTRY
      render json: { errors: 'No se pudo completar la salida por que el artículo "' + unit_item.name + '" no ha ingresado al almacén.' }, status: 422
      return
    when InventoryItem::PENDING_WITHDRAWAL
      render json: { errors: 'No se pudo completar la salida por que el artículo "' + unit_item.name + '" tiene una salida programada.' }, status: 422
      return
    end

    unit_item.status = InventoryItem::OUT_OF_STOCK
    if unit_item.save
      inventory_item = InventoryItem.find_by_actable_id(unit_item.id)
      log_checkout_transaction( params[:exit_date], inventory_item.id, "Salida unitaria", '-', params[:estimated_return_date], params[:additional_comments], params[:pickup_company], params[:pickup_company_contact], 1)
      log_action( current_user.id, 'InventoryItem', 'Salida unitaria de: "' + unit_item.name + '"', inventory_item.id )
      render json: { success: '¡Has sacado el artículo "' +  unit_item.name + '"!' }, status: 201  
    else
      render json: { errors: unit_item.errors }, status: 422
    end 
       

  end

  private

    def unit_item_params
      params.require(:unit_item).permit(:serial_number, :brand, :model, :name, :description, :project_id, :status, :item_type, :barcode, :validity_expiration_date)
      # params.permit(:serial_number, :brand, :model, :name, :description, :project_id, :image_url, :status, :item_img)
    end
end
