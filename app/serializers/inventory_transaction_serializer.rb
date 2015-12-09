class InventoryTransactionSerializer < ActiveModel::Serializer
  attributes :id, :concept, :storage_type, :additional_comments, :created_at, :inventory_item

end
