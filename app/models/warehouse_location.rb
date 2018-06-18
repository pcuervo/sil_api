class WarehouseLocation < ActiveRecord::Base
  validates :name, presence: true
  validates :name, uniqueness: true
  belongs_to :warehouse_rack
  has_many :item_locations
  has_many :warehouse_transactions

  # Status
  EMPTY = 1
  PARTIAL_SPACE = 2
  NO_SPACE = 3

  # Error codes
  IS_FULL = -1
  NOT_ENOUGH_STOCKS = -2
  NOT_ENOUGH_UNITS = -3
  ITEM_ALREADY_LOCATED = -4

  def locate(inventory_item_id, quantity)
    item_location = ItemLocation.where('inventory_item_id = ? AND warehouse_location_id = ?', inventory_item_id, id).first
    inventory_item = InventoryItem.find(inventory_item_id)

    if item_location.present?
      return ITEM_ALREADY_LOCATED if (item_location.quantity + quantity) >= inventory_item.quantity

      item_location.update(quantity: item_location.quantity + quantity)
      item_location.update(quantity: inventory_item.quantity) if item_location.quantity > inventory_item.quantity

      WarehouseTransaction.create(inventory_item_id: inventory_item_id, warehouse_location_id: id, quantity: item_location.quantity, concept: WarehouseTransaction::ENTRY)
    else
      quantity = inventory_item.quantity if quantity > inventory_item.quantity

      item_location = ItemLocation.create(inventory_item_id: inventory_item_id, warehouse_location_id: id, quantity: quantity)
      item_locations << item_location
      WarehouseTransaction.create(inventory_item_id: inventory_item_id, warehouse_location_id: id, quantity: quantity, concept: WarehouseTransaction::ENTRY)
    end

    update_status

    item_location.id
  end

  # Relocates an existing InventoryItem to current WarehouseLocation
  # * *Params:*
  #   - +item_location_id+ -> ID of ItemLocation to relocate
  #   - +quantity+ -> Item quantity
  # * *Returns:*
  #   - ID of new ItemLocation
  # @todo REDEFINE THIS SHIT
  def relocate(item_location_id, quantity)
    item_location = ItemLocation.find(item_location_id)
    inventory_item = InventoryItem.find(item_location.inventory_item_id)
    old_location = item_location.warehouse_location

    new_item_location = ItemLocation.create(inventory_item_id: item_location.inventory_item_id, warehouse_location_id: id, quantity: quantity)
    w = WarehouseTransaction.create(inventory_item_id: item_location.inventory_item_id, warehouse_location_id: id, quantity: quantity, concept: WarehouseTransaction::RELOCATION)

    new_item_location.save
    item_location.destroy

    new_item_location.id
  end

  # Remove an item from current location
  # * *Params:*
  #   - +inventory_item_id+ -> ID of ItemLocation to relocate
  # * *Returns:*
  #   - bool if item was removed successfully
  def remove_item(inventory_item_id)
    item_location = item_locations.find_by_inventory_item_id(inventory_item_id)

    w = WarehouseTransaction.create(inventory_item_id: inventory_item_id, warehouse_location_id: id, quantity: item_location.quantity, concept: WarehouseTransaction::WITHDRAW)
    item_locations.delete(item_location)
    item_location.destroy
    item_location.present?
  end

  # Remove a quantity of an item from current location. By default
  # the concept is WITHDRAWAL (3).
  # * *Params:*
  #   - +inventory_item_id+ -> ID of ItemLocation to relocate
  #   - +quantity+ -> quantity to remove
  #   - +concept+ -> quantity to remove
  # * *Returns:*
  #   - current quantity or error
  def remove_quantity(inventory_item_id, quantity, concept = 3)
    item_location = ItemLocation.where('inventory_item_id = ? AND warehouse_location_id = ?', inventory_item_id, id).first

    return NOT_ENOUGH_STOCKS if quantity > item_location.quantity

    item_location.quantity -= quantity
    quantity = item_location.quantity if item_location.quantity < 0

    item_location.save
    w = WarehouseTransaction.create(inventory_item_id: inventory_item_id, warehouse_location_id: id, quantity: quantity, concept: concept)

    if item_location.quantity <= 0
      item_location.destroy
      return 0
    end
    update_status
    item_location.quantity
  end

  # Returns the available units in current WarehouseLocation
  # * *Returns:*
  #   - number of available units
  def get_available_units
    return 0 if status == NO_SPACE
    999
  end

  def update_status
    return if status == NO_SPACE

    self.status = if item_locations.count.zero?
                    EMPTY
                  else
                    PARTIAL_SPACE
                  end
    save
  end

  def get_details
    inventory_items = []
    item_locations.each { |il| inventory_items.push(il.inventory_item.get_details) }
    details = { 'warehouse_location' => {
      'id' => id,
      'name' => name,
      'status' => status,
      'warehouse_rack' => warehouse_rack,
      'item_locations' => item_locations,
      'inventory_items' => inventory_items
    } }
  end

  def empty
    item_locations.each do |item_location|
      quantity_to_remove = item_location.quantity
      remove_quantity(item_location.inventory_item_id, quantity_to_remove, WarehouseTransaction::EMPTIED)
    end

    true
  end

  def mark_as_full
    update(status: NO_SPACE)
  end

  def mark_as_available
    if item_locations.count.zero?
      update(status: EMPTY)
    else
      update(status: PARTIAL_SPACE)
    end
  end

  def self.pending_location_ids
    InventoryItem.select('inventory_items.id, SUM(item_locations.quantity) AS quantity_locations, SUM(bulk_items.quantity) AS quantity_bulk').joins(:item_locations).joins('INNER JOIN bulk_items ON bulk_items.id = inventory_items.actable_id').where('actable_type = ?', 'BulkItem').group('inventory_items.id, bulk_items.quantity').having('SUM(item_locations.quantity) < bulk_items.quantity').pluck('inventory_items.id')
  end

  def self.pending_location_items
    InventoryItem.select('inventory_items.id, bulk_items.quantity-SUM(item_locations.quantity) AS quantity').joins(:item_locations).joins('INNER JOIN bulk_items ON bulk_items.id = inventory_items.actable_id').where('actable_type = ? AND inventory_items.id = ?', 'BulkItem', params[:id]).group('inventory_items.id, bulk_items.quantity').having('SUM(item_locations.quantity) < bulk_items.quantity')
  end

  def self.bulk_locate(_user_email, item_locations_arr)
    errors = []
    located_items = 0
    item_locations_arr.each_with_index do |row, _i|
      barcode = row[:barcode]
      quantity = row[:quantity].to_i
      location_name = row[:location].delete("\n").delete("\r")

      location = WarehouseLocation.find_by_name(location_name)
      unless location.present?
        errors.push('¡No existe la ubicación con nombre: ' + location_name.to_s + '!')
        next
      end

      item = InventoryItem.find_by_barcode(barcode)
      unless item.present?
        errors.push('¡No existe el artículo con código de barras: ' + barcode + '!')
        next
      end

      # @todo: Corregir cuando se usen un solo tipo de articulo.
      if item.status == InventoryItem::OUT_OF_STOCK
        errors.push('No se ubicó el artículo con código de barras "' + barcode + '" porque no cuenta con piezas en el inventario.')
        next
      end

      if item.actable_type == 'BulkItem'
        bulk_item = BulkItem.find(item.actable_type)
        new_quantity = bulk_item.quantity
      else
        new_quantity = 1
      end

      locate_item = location.locate(item.id, new_quantity, new_quantity)

      if ITEM_ALREADY_LOCATED == locate_item
        errors.push('No se agregó la cantidad de ' + quantity.to_s + ' pieza(s) del artículo con código de barras "' + barcode + '" porque ya estaba previamente ubicado en la ubicación ' + location_name + '.')
        next
      end
      located_items += 1
    end

    { located_items: located_items, errors: errors }
  end
end
