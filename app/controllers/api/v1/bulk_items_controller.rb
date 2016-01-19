class Api::V1::BulkItemsController < ApplicationController
  respond_to :json
  
  def show
    respond_with BulkItem.find(params[:id])
  end

  def index
    respond_with BulkItem.all
  end

  def create
    bulk_item = BulkItem.new(bulk_item_params)
    bulk_item.user = current_user

    # Paperclip adaptor 
    item_img = Paperclip.io_adapters.for(params[:item_img])
    item_img.original_filename = params[:filename]
    bulk_item.item_img = item_img

    if bulk_item.save
      inventory_item = InventoryItem.find_by_actable_id(bulk_item.id)
      log_checkin_transaction( params[:entry_date], inventory_item.id, "Entrada granel inicial", params[:storage_type], params[:estimated_issue_date], params[:additional_comments], params[:delivery_company], params[:delivery_company_contact], params[:bulk_item][:quantity])
      log_action( current_user.id, 'InventoryItem', 'Ingreso inicial a granel de: "' + bulk_item.name + '"', inventory_item.id )
      render json: bulk_item, status: 201, location: [:api, bulk_item]
    else
      render json: { errors: bulk_item.errors }, status: 422
    end
  end

  def withdraw

    bulk_item = BulkItem.find_by_id(params[:id])

    if ! bulk_item.present?
      render json: { errors: "No se encontró el artículo." }, status: 422
      return
    end

    case bulk_item.status
    when InventoryItem::OUT_OF_STOCK
      render json: { errors: 'No se pudo completar la salida por que el artículo "' + bulk_item.name + '" no se encuentra en existencia.' }, status: 422
      return
    when InventoryItem::PENDING_ENTRY
      render json: { errors: 'No se pudo completar la salida por que el artículo "' + bulk_item.name + '" no ha ingresado al almacén.' }, status: 422
      return
    when InventoryItem::PENDING_WITHDRAWAL
      render json: { errors: 'No se pudo completar la salida por que el artículo "' + bulk_item.name + '" tiene una salida programada.' }, status: 422
      return
    end

    bulk_item.quantity = bulk_item.quantity.to_i - params[:quantity].to_i
    if 0 > bulk_item.quantity.to_i
      render json: { errors: '¡No puedes sacar mas existencias de las que hay disponibles!' }, status: 422
      return
    end

    bulk_item.status = InventoryItem::OUT_OF_STOCK if bulk_item.quantity.to_i == 0
    if bulk_item.save
      inventory_item = InventoryItem.find_by_actable_id(bulk_item.id)
      log_checkout_transaction( params[:exit_date], inventory_item.id, "Salida a granel", '-', params[:estimated_return_date], params[:additional_comments], params[:pickup_company], params[:pickup_company_contact], params[:quantity])
      log_action( current_user.id, 'InventoryItem', 'Salida a granel de: "' + bulk_item.name + '" por ' + params[:quantity].to_s + ' existencia(s)', inventory_item.id )
      render json: { success: '¡Has sacado ' + params[:quantity].to_s + ' existencia(s) del artículo "' +  bulk_item.name + '"!', quantity: bulk_item.quantity }, status: 201   
    else
      render json: { errors: bulk_item.errors }, status: 422
    end 

  end

  private

    def bulk_item_params
      params.require(:bulk_item).permit(:quantity, :name, :description, :project_id, :status, :item_type, :barcode, :validity_expiration_date)
    end
end

