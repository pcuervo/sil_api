class UserSerializer < ActiveModel::Serializer
  attributes :id, :first_name, :last_name, :email, :auth_token, :role
end
