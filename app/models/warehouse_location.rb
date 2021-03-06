# frozen_string_literal: true

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
  ITEM_ALREADY_LOCATED = -4

  def locate(inventory_item, quantity)
    raise SilExceptions::InvalidQuantityToLocate if quantity < 1

    return locate_in_new(inventory_item, quantity) unless in_location?(inventory_item.id)

    item_location = ItemLocation.where('inventory_item_id = ? AND warehouse_location_id = ?', inventory_item, id)
    locate_in_existing(item_location.first, quantity)
  end

  def locate_in_new(inventory_item, quantity)
    raise SilExceptions::InvalidQuantityToLocate if quantity > inventory_item.quantity

    item_location = ItemLocation.create(
      inventory_item_id: inventory_item.id,
      warehouse_location_id: id,
      quantity: quantity
    )
    item_locations << item_location
    WarehouseTransaction.create(
      inventory_item_id: inventory_item.id,
      warehouse_location_id: id,
      quantity: quantity,
      concept: WarehouseTransaction::ENTRY
    )

    update_status
    item_location.id
  end

  def in_location?(inventory_item_id)
    ItemLocation.where('inventory_item_id = ? AND warehouse_location_id = ?', inventory_item_id, id).exists?
  end

  def locate_in_existing(item_location, quantity)
    raise SilExceptions::InvalidQuantityToLocate if (item_location.quantity + quantity) > item_location.inventory_item.quantity

    item_location.update(quantity: item_location.quantity + quantity)
    WarehouseTransaction.create(
      inventory_item_id: item_location.inventory_item.id,
      warehouse_location_id: id,
      quantity: quantity,
      concept: WarehouseTransaction::ENTRY
    )

    update_status
    item_location.id
  end

  # Relocates an existing InventoryItem to new WarehouseLocation.
  def relocate(inventory_item, quantity, new_location)
    current_item_location = ItemLocation.find_by(
      inventory_item_id: inventory_item.id,
      warehouse_location_id: id
    )
    raise SilExceptions::ItemNotInLocation if current_item_location.nil?
    raise SilExceptions::InvalidQuantityToRelocate if current_item_location.quantity < quantity

    new_location.locate(inventory_item, quantity)

    if current_item_location.quantity == quantity
      remove_item(inventory_item.id) 
      update_status
      return
    end
    
    remove_quantity(inventory_item.id, quantity, WarehouseTransaction::RELOCATION)
  end

  def remove_item(inventory_item_id)
    item_location = item_locations.find_by(inventory_item_id: inventory_item_id)
    raise SilExceptions::ItemNotInLocation if item_location.nil?

    WarehouseTransaction.create(
      inventory_item_id: inventory_item_id,
      warehouse_location_id: id,
      quantity: item_location.quantity,
      concept: WarehouseTransaction::WITHDRAW
    )
    item_locations.delete(item_location)
    item_location.destroy
    #item_location.present?
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
    item_location = ItemLocation.find_by(
      inventory_item_id: inventory_item_id,
      warehouse_location_id: id
    )

    return NOT_ENOUGH_STOCKS if quantity > item_location.quantity

    item_location.quantity -= quantity
    quantity = item_location.quantity if item_location.quantity.negative?

    item_location.save
    WarehouseTransaction.create(
      inventory_item_id: inventory_item_id,
      warehouse_location_id: id,
      quantity: quantity,
      concept: concept
    )

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
  def available_units
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
      'inventory_items' => items
    } }
    details
  end

  def items
    inventory_items = []
    item_locations.order(created_at: :desc).each do |il|
      unless il.inventory_item.present?
        il.destroy
        next
      end

      item = il.inventory_item
      inventory_items.push(
        'id' => item.id,
        'img'           => item.item_img(:medium),
        'name'          => item.name,
        'location_id'   => il.warehouse_location_id,
        'location'      => il.warehouse_location.name,
        'quantity'      => il.quantity,
        'created_at'    => il.created_at,
        'item_type'     => item.item_type,
        'actable_type'  => item.actable_type,
        'serial_number' => item.serial_number
      )
    end

    inventory_items
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
    InventoryItem.select('inventory_items.id, SUM(item_locations.quantity) AS quantity_locations, SUM(bulk_items.quantity) AS quantity_bulk')
                 .joins(:item_locations)
                 .joins('INNER JOIN bulk_items ON bulk_items.id = inventory_items.actable_id')
                 .where('actable_type = ?', 'BulkItem')
                 .group('inventory_items.id, bulk_items.quantity')
                 .having('SUM(item_locations.quantity) < bulk_items.quantity')
                 .pluck('inventory_items.id')
  end

  def self.pending_location_items(id)
    InventoryItem.select(
      'inventory_items.id, bulk_items.quantity-SUM(item_locations.quantity) AS quantity'
    )
                 .joins(:item_locations)
                 .joins('INNER JOIN bulk_items ON bulk_items.id = inventory_items.actable_id')
                 .where('actable_type = ? AND inventory_items.id = ?', 'BulkItem', id)
                 .group('inventory_items.id, bulk_items.quantity')
                 .having('SUM(item_locations.quantity) < bulk_items.quantity')
  end

  def self.bulk_locate(_user_email, item_locations_arr); end

  def self.current_or_last(item_id)
    item_location = ItemLocation.find_by(inventory_item_id: item_id)
    return item_location.warehouse_location if item_location

    transactions = WarehouseTransaction.where(inventory_item_id: item_id).order(created_at: :desc)

    return transactions.first.warehouse_location if transactions.count > 0

    nil
  end

  def transfer_to(new_location)
    items = item_locations.select(:inventory_item_id, :quantity)
    items.each do |item|
      relocate(InventoryItem.find(item.inventory_item_id), item.quantity, new_location)
    end

    empty
  end

  # def self.remove_extra 


  #   inventory_difference = ItemLocation.select('inventory_items.id, SUM(item_locations.quantity)').joins(:inventory_item).group('inventory_items.id').having('SUM(item_locations.quantity) > inventory_items.quantity').pluck('inventory_items.id, SUM(item_locations.quantity)')

  # end
end
