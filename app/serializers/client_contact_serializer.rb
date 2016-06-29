class ClientContactSerializer < ActiveModel::Serializer
  attributes :id, :first_name, :last_name, :phone, :phone_ext, :email, :business_unit, :created_at, :client, :discount, :current_month_rent

  def current_month_rent
    object.get_rent( Time.now.month, Time.now.year )
  end
end
