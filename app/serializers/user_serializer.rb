class UserSerializer < ActiveModel::Serializer
  attributes :id, :first_name, :last_name, :email, :auth_token, :role, :avatar_thumb

  def avatar_thumb
    object.avatar(:thumb)
  end
end
