class Project < ActiveRecord::Base
  before_destroy :remove_inventory

  validates :litobel_id, uniqueness: true
  validates :name, :litobel_id, :client, presence: true

  has_and_belongs_to_many :users
  has_many :inventory_items
  belongs_to :client

  def ae_name
    ae = users.where('role=?', User::ACCOUNT_EXECUTIVE).first

    return unless ae.present?
    ae.first_name + ' ' + ae.last_name
  end

  def ae_id
    ae = users.where('role=?', User::ACCOUNT_EXECUTIVE).first

    return unless ae.present?
    ae.id
  end

  def remove_inventory
    inventory_items.delete_all
  end

  def transfer_inventory(to_project)
    inventory_items.each { |item| item.update_attributes(project_id: to_project.id) }
  end

  def transfer_inventory_items(to_project, items_ids)
    items_to_transfer = inventory_items.where('id IN (?)', items_ids)
    items_to_transfer.each { |item| item.update_attributes(project_id: to_project.id) }
  end
end
