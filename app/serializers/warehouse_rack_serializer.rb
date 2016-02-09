class WarehouseRackSerializer < ActiveModel::Serializer
  attributes :id, :name, :row, :column, :warehouse_locations, :created_at
end
