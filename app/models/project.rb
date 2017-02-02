class Project < ActiveRecord::Base
  validates :litobel_id, uniqueness: true
  validates :name, :litobel_id, :client, presence: true

  has_and_belongs_to_many :users
  has_many :inventory_items
  belongs_to :client

  def get_pm
    pm = self.users.where('role=?', User::PROJECT_MANAGER).first

    return unless pm.present?
    pm.first_name + ' ' + pm.last_name
  end

  def get_pm_id
    pm = self.users.where('role=?', User::PROJECT_MANAGER).first

    return unless pm.present?
    pm.id
  end

  def get_ae
    ae = self.users.where('role=?', User::ACCOUNT_EXECUTIVE).first

    return unless ae.present?
    ae.first_name + ' ' + ae.last_name
  end

  def get_ae_id
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

end
