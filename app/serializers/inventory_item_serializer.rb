class InventoryItemSerializer < ActiveModel::Serializer
  attributes :id, :name, :item_type, :actable_type, :validity_expiration_date, :status, :value, :created_at, :item_img_thumb, :quantity

  def item_img_thumb
    object.item_img(:thumb)
  end

  def quantity
    object.get_quantity
  end
end
