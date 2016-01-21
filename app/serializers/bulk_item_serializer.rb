class BulkItemSerializer < ActiveModel::Serializer
  attributes :id, :quantity, :name, :description, :image_url, :status, :barcode, :state, :value
  has_one :project
end