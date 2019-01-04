# frozen_string_literal: true

# Static class to replenish InventoryItems
# and locate in given WarehouseLocations.

class ReplenishInventory
  attr_reader(:data, :processed, :errors)

  ITEM_ID_INDEX = 0
  ITEM_NAME_INDEX = 1
  QUANTITY_INDEX = 2
  LOCATION_INDEX = 3
  COMMENTS_INDEX = 4

  class ReplenishInventoryError < StandardError; end
  class InvalidItemError < ReplenishInventoryError; end
  class InvalidLocationError < ReplenishInventoryError; end
  class InvalidQuantity < ReplenishInventoryError; end

  ERRORS = [ 
    InvalidItemError, 
    InvalidLocationError,
    InvalidQuantity
  ]

  def initialize(data)
    @data = data
    @errors = []
    @processed = 0
  end

  def replenish
    folio = InventoryTransaction.next_checkin_folio
    @data.each do |d| 
      by_item(d[ITEM_ID_INDEX], d[QUANTITY_INDEX], d[LOCATION_INDEX], d[COMMENTS_INDEX], folio)
    end
  end

  def by_item(item_id, quantity, location_name, additional_comments, folio)
    return unless valid_row(item_id, quantity, location_name)

    item = InventoryItem.find(item_id)
    location = WarehouseLocation.find_by(name: location_name)
    item.add(quantity, InventoryItem::GOOD, Date.today, 'Entrada por CSV', '', '', additional_comments, folio)
    location.locate(item, quantity)
    @processed += 1
  end

  def valid_row(item_id, quantity, location_name)    
    raise InvalidItemError.new(item_id) unless InventoryItem.exists?(item_id)
    raise InvalidLocationError.new(location_name) unless WarehouseLocation.exists?(name: location_name)
    raise InvalidQuantity.new(item_id) unless quantity.to_i > 0

    true
  rescue ReplenishInventoryError => e
    handle_exception(e)
    false
  end

  def handle_exception(exception)
    case exception
    when InvalidItemError
      message = "No se pudo agregar el artículo con ID: #{exception.message}"
    when InvalidLocationError
      message = "No se pudo encontrar la ubicación: #{exception.message}"
    when InvalidQuantity
      message = "La cantidad el artículo con ID #{exception.message} debe ser mayor que 0"
    end
    errors.push(message)
  end
end