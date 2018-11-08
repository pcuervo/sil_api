class ClientContactSerializer < ActiveModel::Serializer
  attributes :id, :first_name, :last_name, :phone, :phone_ext, :email, :business_unit, :created_at, :client, :discount, :current_month_rent, :actable_id, :parent_id

  def current_month_rent
    object.get_current_rent
  end

  def parent_id
    object.acting_as.id
  end
end
