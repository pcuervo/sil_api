class BundleItemSerializer < ActiveModel::Serializer
  attributes :id, :num_parts, :is_complete, :name, :description, :image_url, :status, :barcode
end
