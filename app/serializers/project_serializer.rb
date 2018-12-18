class ProjectSerializer < ActiveModel::Serializer
  attributes :id, :name, :litobel_id, :created_at, :client, :users, :client_id, :has_inventory

  has_many :inventory_items, serializer: LeanItemSerializer

  def has_inventory
    object.inventory_items.count > 0
  end
end
