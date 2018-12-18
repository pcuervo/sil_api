class LeanItemSerializer < ActiveModel::Serializer
  attributes :id, :name, :item_type, :validity_expiration_date, :status, :value, :created_at, :img_medium, :thumb, :quantity, :serial_number, :brand, :model, :extra_parts, :barcode, :item_locations, :description

  has_many :item_locations, serializer: ItemLocationSerializer

  def img_medium
    object.item_img(:medium)
  end

  def thumb 
    object.item_img(:thumb)
  end
end
