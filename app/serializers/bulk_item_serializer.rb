class BulkItemSerializer < ActiveModel::Serializer
  attributes :id, :quantity, :name, :description, :image_url, :status, :barcode, :state, :value, :actable_type, :actable_id
  has_one :project
end