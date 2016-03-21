class ProjectSerializer < ActiveModel::Serializer
  attributes :id, :name, :litobel_id, :created_at, :client, :users
end
