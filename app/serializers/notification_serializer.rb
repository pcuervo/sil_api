class NotificationSerializer < ActiveModel::Serializer
  attributes :id, :title, :message, :status, :created_at, :inventory_item_id
end
