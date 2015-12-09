class ProjectSerializer < ActiveModel::Serializer
  attributes :id, :name, :litobel_id, :created_at
  has_one :client
end
