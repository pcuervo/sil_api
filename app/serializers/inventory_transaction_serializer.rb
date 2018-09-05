class InventoryTransactionSerializer < ActiveModel::Serializer
  attributes :id, :quantity, :concept, :additional_comments, :created_at, :inventory_item

end
