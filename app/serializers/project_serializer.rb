class ProjectSerializer < ActiveModel::Serializer
  attributes :id, :name, :litobel_id, :created_at, :client, :users, :has_inventory, :inventory_items

  def has_inventory
    return true if object.inventory_items.count > 0

    return false
  end
end
