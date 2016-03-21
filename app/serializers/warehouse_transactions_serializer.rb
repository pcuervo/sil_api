class WarehouseTransactionsSerializer < ActiveModel::Serializer
  attributes :id, :inventory_item, :warehouse_location, :concept, :units, :quantity, :part_id, :created_at
end
