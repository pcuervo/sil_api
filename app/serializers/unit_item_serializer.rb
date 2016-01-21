class UnitItemSerializer < ActiveModel::Serializer
  attributes :id, :serial_number, :brand, :model, :name, :description, :image_url, :status, :barcode, :state, :value
  has_one :project
end