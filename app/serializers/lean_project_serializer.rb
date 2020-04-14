class LeanProjectSerializer < ActiveModel::Serializer
  attributes :id, :name, :litobel_id, :client

  belongs_to :client, serializer: ClientSerializer
end
