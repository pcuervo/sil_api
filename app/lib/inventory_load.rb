# frozen_string_literal: true

# Static class to create new InventoryItems
# and locate in given WarehouseLocations.

class InventoryLoad
  attr_reader(:data, :processed, :errors)

  PROJECT_INDEX = 0
  CLIENT_INDEX = 1
  NAME_INDEX = 2
  QUANTITY_INDEX = 3
  SERIAL_NUMBER_INDEX = 4
  BRAND_INDEX = 5
  MODEL_INDEX = 6
  DESCRIPTION_INDEX = 7
  ADDITIONAL_COMMENTS_INDEX = 8
  ITEM_TYPE_INDEX = 9
  HIGH_VALUE_INDEX = 10
  LOCATION_INDEX = 11

  class InventoryLoadError < StandardError; end
  class InvalidProjectError < InventoryLoadError; end
  class InvalidClientError < InventoryLoadError; end
  class InvalidLocationError < InventoryLoadError; end
  class InvalidQuantity < InventoryLoadError; end

  ERRORS = [ 
    InvalidProjectError, 
    InvalidClientError, 
    InvalidLocationError,
    InvalidQuantity
  ]

  def initialize(user, data)
    @user = user
    @data = data
    @errors = []
    @processed = 0
  end

  def load
    folio = InventoryTransaction.next_checkin_folio
    @data.each { |d| create_item(d, folio) }
  end

  def create_item(item_data, folio)
    return unless valid_row(item_data)
    
    project = Project.find_by(name: item_data[PROJECT_INDEX])
    client = Client.find_by(name: item_data[CLIENT_INDEX])
    item = InventoryItem.create(
      project_id: project.id,
      client_id: client.id,
      name: item_data[NAME_INDEX],
      quantity: 0,
      serial_number: item_data[SERIAL_NUMBER_INDEX],
      brand: item_data[BRAND_INDEX],
      model: item_data[MODEL_INDEX],
      description: item_data[DESCRIPTION_INDEX],
      extra_parts: item_data[ADDITIONAL_COMMENTS_INDEX],
      item_type: item_data[ITEM_TYPE_INDEX],
      is_high_value: item_data[HIGH_VALUE_INDEX],
      barcode: generate_barcode(project.name, item_data[NAME_INDEX], item_data[ITEM_TYPE_INDEX]),
      user: @user,
      storage_type: 'Permanente',
      validity_expiration_date: 1.year.since(Date.today)
    )

    if item.errors.count.positive?
      puts 'This shit has errors'
      puts item.errors.to_yaml
    end
    location = WarehouseLocation.find_by(name: item_data[LOCATION_INDEX])
    item.add(item_data[QUANTITY_INDEX], InventoryItem::NEW, Date.today, 'Entrada por CSV', '', '', 'Alta de inventario.', folio)
    location.locate(item, item_data[QUANTITY_INDEX])
    @processed += 1
  end

  def valid_row(data)    
    raise InvalidProjectError.new(data[PROJECT_INDEX]) unless Project.exists?(name: data[PROJECT_INDEX])
    raise InvalidClientError.new(data[CLIENT_INDEX]) unless Client.exists?(name: data[CLIENT_INDEX])
    raise InvalidLocationError.new(data[LOCATION_INDEX]) unless WarehouseLocation.exists?(name: data[LOCATION_INDEX])
    raise InvalidQuantity.new(data[NAME_INDEX]) unless data[QUANTITY_INDEX].to_i > 0

    true
  rescue InventoryLoadError => e
    handle_exception(e)
    false
  end

  def handle_exception(exception)
    case exception
    when InvalidProjectError
      message = "No se encontró el proyecto: #{exception.message}"
    when InvalidClientError
      message = "No se encontró el cliente: #{exception.message}"
    when InvalidLocationError
      message = "No se pudo encontrar la ubicación: #{exception.message}"
    when InvalidQuantity
      message = "La cantidad del artículo #{exception.message} debe ser mayor que 0"
    else
      puts exception.to_yaml
    end
    errors.push(message)
  end

  #private 

  def generate_barcode(project_name, item_name, item_type)
    clean_project = project_name.gsub('-','').first(5).upcase
    clean_item = slug(item_name).first(3).upcase
    clean_type = item_type.first(3).upcase
    timestamp = Time.now.to_i

    code = "#{clean_project} #{clean_item} #{clean_type} #{timestamp.to_s.last(4)}"

    return code unless InventoryItem.exists?(barcode: code)

    sleep(1)
    code + Time.now.to_s
  end

  def slug(str)
    str.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')
  end
end
