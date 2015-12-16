class WarehouseLocationSerializer < ActiveModel::Serializer
  attributes :id, :name, :units, :status, :warehouse_rack, :item_locations
end
