class Api::V1::BundleItemsController < ApplicationController
  respond_to :json

  def show
    respond_with BundleItem.find(params[:id])
  end

  def index
    respond_with BundleItem.all
  end

  def create

    bundle_item = BundleItem.new(bundle_item_params)
    bundle_item.user = current_user

    if ! params[:parts].present?
      bundle_item.errors.add(:parts, 'cannot be empty')
      render json: { errors: bundle_item.errors }, status: 422
      return
    end

    # Paperclip adaptor 
    item_img = Paperclip.io_adapters.for(params[:item_img])
    item_img.original_filename = params[:filename]
    bundle_item.item_img = item_img

    if bundle_item.save
      bundle_item.add_new_parts( params[:parts] )
      inventory_item = InventoryItem.find_by_actable_id(bundle_item.id)
      log_checkin_transaction( params[:entry_date], inventory_item.id, "Entrada paquete", params[:storage_type], params[:estimated_issue_date], params[:additional_comments], params[:delivery_company], params[:delivery_company_contact], bundle_item.num_parts )
      log_action( current_user.id, 'InventoryItem', 'Created bundle item "' + bundle_item.name + '"', inventory_item.id )
      render json: bundle_item, status: 201, location: [:api, bundle_item]
    else
      render json: { errors: bundle_item.errors }, status: 422
    end
  end

  def withdraw

    bundle_item = BundleItem.find_by_id(params[:id])

    if ! bundle_item.present?
      render json: { errors: "No se encontró el artículo." }, status: 422
      return
    end

    if ! params[:parts].present?
      render json: { errors: "Deber retirar al menos una pieza del paquete." }, status: 422
      return
    end

    case bundle_item.status
    when InventoryItem::OUT_OF_STOCK
      render json: { errors: 'No se pudo completar la salida por que el artículo "' + bundle_item.name + '" no se encuentra en existencia.' }, status: 422
      return
    when InventoryItem::PENDING_ENTRY
      render json: { errors: 'No se pudo completar la salida por que el artículo "' + bundle_item.name + '" no ha ingresado al almacén.' }, status: 422
      return
    when InventoryItem::PENDING_WITHDRAWAL
      render json: { errors: 'No se pudo completar la salida por que el artículo "' + bundle_item.name + '" tiene una salida programada.' }, status: 422
      return
    end

    bundle_item.remove_parts( params[:parts] )
    quantity = params[:parts].count

    if bundle_item.save
      inventory_item = InventoryItem.find_by_actable_id( bundle_item.id )
      log_checkout_transaction( params[:exit_date], inventory_item.id, "Salida de paquete", '-', params[:estimated_return_date], params[:additional_comments], params[:pickup_company], params[:pickup_company_contact], quantity)
      log_action( current_user.id, 'InventoryItem', 'Salida de paquete de: "' + quantity.to_s + '" pieza(s)', inventory_item.id )
      render json: { success: '¡Has sacado ' + quantity.to_s + ' pieza(s) del paquete "' +  bundle_item.name + '"!' }, status: 201   
    else
      render json: { errors: bundle_item.errors }, status: 422
    end 
  end

  def re_entry
    bundle_item = BundleItem.find_by_id(params[:id])

    if ! bundle_item.present?
      render json: { errors: "No se encontró el artículo." }, status: 422
      return
    end

     if ! params[:parts].present?
      render json: { errors: "Deber retirar al menos una pieza del paquete." }, status: 422
      return
    end

    bundle_item.add_existing_parts( params[:parts] )
    bundle_item.state = params[:state]

    if bundle_item.save
      inventory_item = InventoryItem.find_by_actable_id( bundle_item.id )
      log_checkin_transaction( params[:entry_date], inventory_item.id, "Reingreso paquete", '-', '', params[:additional_comments], params[:delivery_company], params[:delivery_company_contact], params[:quantity])
      log_action( current_user.id, 'InventoryItem', 'Reingreso paquete de: "' + bundle_item.name + '"', inventory_item.id )
      render json: { success: '¡Has reingresado partes del artículo  "' +  bundle_item.name + '"!' }, status: 201  
      return
    end

    render json: { errors: bundle_item.errors }, status: 422 
  end

  private 

    def bundle_item_params
      params.require(:bundle_item).permit(:quantity, :name, :description, :project_id, :status, :item_type, :barcode, :validity_expiration_date, :state, :value)
    end

end
