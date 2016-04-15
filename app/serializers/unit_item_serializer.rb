class UnitItemSerializer < ActiveModel::Serializer
  attributes :id, :serial_number, :brand, :model, :name, :description, :status, :barcode, :state, :value, :actable_type, :actable_id
  has_one :project
end