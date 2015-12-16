class WarehouseRackSerializer < ActiveModel::Serializer
  attributes :id, :name, :row, :column, :warehouse_locations
end
