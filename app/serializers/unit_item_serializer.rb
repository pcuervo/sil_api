class UnitItemSerializer < ActiveModel::Serializer
  attributes :id, :serial_number, :brand, :model, :name, :description, :status, :barcode, :state, :value, :actable_type, :actable_id, :item_type, :created_at, :inventory_item_id
  has_one :project

  def inventory_item_id
    item = InventoryItem.where('actable_id = ? and actable_type = "UnitItem"', object.id )
    item.id
  end
end