class Project < ActiveRecord::Base
  before_destroy :check_if_has_inventory

  validates :litobel_id, uniqueness: true
  validates :name, :litobel_id, :client, presence: true

  has_and_belongs_to_many :users
  has_many :inventory_items
  belongs_to :client

  def pm
    pm = users.where('role=?', User::PROJECT_MANAGER).first

    return unless pm.present?
    pm.first_name + ' ' + pm.last_name
  end

  def pm_id
    pm = users.where('role=?', User::PROJECT_MANAGER).first

    return unless pm.present?
    pm.id
  end

  def ae
    ae = users.where('role=?', User::ACCOUNT_EXECUTIVE).first

    return unless ae.present?
    ae.first_name + ' ' + ae.last_name
  end

  def ae_id
    ae = users.where('role=?', User::ACCOUNT_EXECUTIVE).first

    return unless ae.present?
    ae.id
  end

  def get_client
    Client.find(client_id).name
  end

  def get_client_contact
    client_contact = ClientContact.find_by_client_id(client_id)

    return unless client_contact.present?
    client_contact.first_name + ' ' + client_contact.last_name
  end

  def check_if_has_inventory
    return false if inventory_items.count > 0
  end
end
