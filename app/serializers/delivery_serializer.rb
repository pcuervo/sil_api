class DeliverySerializer < ActiveModel::Serializer
  attributes :id, :delivery_user_id, :company, :address, :addressee, :addressee_phone, :image, :latitude, :longitude, :status, :additional_comments, :user, :delivery_items, :created_at
end
