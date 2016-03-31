class Api::V1::InventoryItemsController < ApplicationController
  before_action :authenticate_with_token!, only: [:create]
  after_action :send_notification_authorize_entry, only: [:authorize_entry]
  after_action :send_notification_authorize_withdrawal, only: [:authorize_withdrawal]
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
    is_reentry = params[:re_entry]

    if inventory_item.present?
      respond_with inventory_item.get_details
      return
    end
    
    render json: { errors: 'No se encontró ningún artículo' }, status: 422

  end

  def by_type
    respond_with InventoryItem.where( 'actable_type=? AND status = ?', params[:type], params[:status] )
  end

  def pending_entry
    respond_with InventoryItem.where( 'status=?', InventoryItem::PENDING_ENTRY )
  end

  def pending_withdrawal
    respond_with InventoryItem.where( 'status=?', InventoryItem::PENDING_WITHDRAWAL )
  end

  def authorize_entry
    @item = InventoryItem.find( params[:id] )
    @item.status = InventoryItem::IN_STOCK
    @item.save
    render json: { success: '¡Se ha aprobado el ingreso del artículo "' + @item.name + '"!' }, status: 201
  end

  def authorize_withdrawal
    @item = InventoryItem.find( params[:id] )
    @item.status = InventoryItem::OUT_OF_STOCK
    @item.save
    render json: { success: '¡Se ha aprobado la salida del artículo "' + @item.name + '"!' }, status: 201
  end

  def with_pending_location
    respond_with InventoryItem.joins('LEFT JOIN item_locations ON inventory_items.id = item_locations.inventory_item_id ').where(' item_locations.id is null AND inventory_items.status IN (?)', [ InventoryItem::IN_STOCK, InventoryItem::PARTIAL_STOCK ]).order(updated_at: :desc)
  end

  def total_number_items
    render json: { total_number_items: InventoryItem.all.count }, status: 200
  end

  def inventory_value
    in_stock_statuses = [ InventoryItem::IN_STOCK, InventoryItem::PARTIAL_STOCK, InventoryItem::PENDING_ENTRY  ]
    render json: { inventory_value: InventoryItem.where( 'status IN (?)', in_stock_statuses ).sum( :value ) }, status: 200
  end

  def current_rent
    in_stock_statuses = [ InventoryItem::IN_STOCK, InventoryItem::PARTIAL_STOCK  ]
    rentable_units = InventoryItem.joins( :item_locations ).where( 'status IN (?)', in_stock_statuses ).sum( :units )
    render json: { current_rent: rentable_units / 50.0 * 500 }, status: 200
  end

  def multiple_withdrawal
    item_ids = params[:inventory_item_ids]

    item_ids.each do |id|
      inventory_item = InventoryItem.find( id )
      withdraw = inventory_item.withdraw( params[:exit_date], '', params[:pickup_company], params[:pickup_company_contact], params[:additional_comments] )

      if [ InventoryItem::OUT_OF_STOCK, InventoryItem::PENDING_ENTRY, InventoryItem::PENDING_WITHDRAWAL, InventoryItem::EXPIRED ].include? withdraw
        render json: { errors: 'No se pudo realizar la salida masiva', items_withdrawn: 0 }, status: 422
        return
      end 
      
    end

    render json: { success: '¡Se ha realizado una salida masiva!', items_withdrawn: item_ids.count }, status: 201
  end

  private
    def inventory_item_params
      params.require(:inventory_item).permit(:name, :description, :project_id, :status, :item_img, :barcode, :item_type, :storage_type)
    end

    def send_notification_authorize_entry
      project = @item.project
      users = project.users.where( 'role IN (?)', [ User::ACCOUNT_EXECUTIVE, User::CLIENT ] )
      users.each do |u|
        u.notifications << Notification.create( :title => 'Confirmación de entrada', :inventory_item_id => @item.id, :message => 'Se ha aprobado la entrada del artículo "' + @item.name + '" en el proyecto "' + project.name + '".' )
      end
    end

    def send_notification_authorize_withdrawal
      puts 'sending notif'
      project = @item.project
      users = project.users.where( 'role IN (?)', [ User::ACCOUNT_EXECUTIVE, User::CLIENT ] )
      puts users.count.to_yaml
      users.each do |u|
        u.notifications << Notification.create( :title => 'Confirmación de salida', :inventory_item_id => @item.id, :message => 'Se ha aprobado la salida del artículo "' + @item.name + '" en el proyecto "' + project.name + '".' )
      end
    end

end
