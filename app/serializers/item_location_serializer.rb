class ItemLocationSerializer < ActiveModel::Serializer
  attributes :id, :units, :quantity, :inventory_item, :warehouse_location
end
