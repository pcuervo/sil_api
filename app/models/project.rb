class Project < ActiveRecord::Base
  before_destroy :check_if_has_inventory

  validates :litobel_id, uniqueness: true
  validates :name, :litobel_id, :client, presence: true

  has_and_belongs_to_many :users
  has_many :inventory_items
  belongs_to :client

  def pm_name
    pm = self.users.where('role=?', User::PROJECT_MANAGER).first

    return unless pm.present?
    pm.first_name + ' ' + pm.last_name
  end

  def pm_id
    pm = self.users.where('role=?', User::PROJECT_MANAGER).first

    return unless pm.present?
    pm.id
  end

  def ae_name
    ae = self.users.where('role=?', User::ACCOUNT_EXECUTIVE).first

    return unless ae.present?
    ae.first_name + ' ' + ae.last_name
  end

  def ae_id
    ae = self.users.where('role=?', User::ACCOUNT_EXECUTIVE).first

    return unless ae.present?
    ae.id
  end

  def get_client
    client = Client.find( self.client_id ).name
  end

  def get_client_contact
    client_contact = ClientContact.find_by_client_id( self.client_id )

    return unless client_contact.present?
    client_contact.first_name + ' ' + client_contact.last_name
  end

  def check_if_has_inventory
    return false if self.inventory_items.count > 0
  end

  def transfer_inventory(to_project)
    inventory_items.each { |item| item.update_attributes(project_id: to_project.id  
  end
end
