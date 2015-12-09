class BulkItemSerializer < ActiveModel::Serializer
  attributes :id, :quantity, :name, :description, :image_url, :status, :barcode
  has_one :project
end