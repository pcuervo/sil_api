class BulkItemSerializer < ActiveModel::Serializer
  attributes :id, :quantity, :name, :description, :image_url, :status, :barcode, :state, :value, :actable_type
  has_one :project
end