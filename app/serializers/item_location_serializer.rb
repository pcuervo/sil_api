class ItemLocationSerializer < ActiveModel::Serializer
  attributes :id, :quantity, :inventory_item, :warehouse_location
end
