class DeliveryRequestSerializer < ActiveModel::Serializer
  attributes :id, :company, :addressee, :addressee_phone, :address, :latitude, :longitude, :additional_comments, :delivery_request_items, :date_time, :user
end
