class InventoryItemSerializer < ActiveModel::Serializer
  attributes :id, :name, :item_type, :actable_type, :validity_expiration_date, :status, :value, :created_at
end
