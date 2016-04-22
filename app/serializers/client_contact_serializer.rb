class ClientContactSerializer < ActiveModel::Serializer
  attributes :id, :first_name, :last_name, :phone, :phone_ext, :email, :business_unit, :created_at, :client, :discount
end
