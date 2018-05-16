class DeliverySerializer < ActiveModel::Serializer
  attributes :id, :delivery_user_id, :company, :address, :addressee, :addressee_phone, :image, :latitude, :longitude, :status, :additional_comments, :user, :delivery_items, :created_at, :updated_at, :date_time, :supplier, :delivery_user

  def supplier
    supplier = Supplier.find_by_id( object.supplier_id )
    return supplier.name if supplier.present?

    '-'
  end

  def delivery_user
    user = User.find_by_id( object.delivery_user_id )
    return user.first_name + ' ' + user.last_name if user.present?

    '-'
  end
end
