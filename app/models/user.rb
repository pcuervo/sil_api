class User < ActiveRecord::Base
  actable
  before_create :generate_authentication_token!
  #before_destroy :remove_from_projects

	validates :auth_token, uniqueness: true
  validates :role, inclusion: { in: [1, 2, 3, 4, 5, 6], message: "%{value} is not a valid role" }
  validates :first_name, :last_name, :email, :role, presence: true

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :inventory_items
  has_many :logs
  has_many :deliveries
  has_many :withdraw_requests
  has_many :delivery_requests
  has_and_belongs_to_many :projects
  has_and_belongs_to_many :notifications
  has_many :pm_items
  has_many :ae_items
  has_many :user_tokens

  # AVAILABLE ROLES
  ADMIN = 1
  PROJECT_MANAGER = 2
  ACCOUNT_EXECUTIVE = 3
  WAREHOUSE_ADMIN = 4
  DELIVERY = 5
  CLIENT = 6

  has_attached_file :avatar, :styles => { :medium => "300x300>", :thumb => "200x200#" }, default_url: "/images/:style/missing.png", :path => ":rails_root/storage/#{Rails.env}#{ENV['RAILS_TEST_NUMBER']}/attachments/:id/:style/:basename.:extension", :url => ":rails_root/storage/#{Rails.env}#{ENV['RAILS_TEST_NUMBER']}/attachments/:id/:style/:basename.:extension", :s3_credentials => S3_CREDENTIALS
  validates_attachment_content_type :avatar, content_type: /\Aimage\/.*\Z/
 

  def generate_authentication_token!
    begin
      self.auth_token = Devise.friendly_token
      puts 'id ' + self.id.to_s
      UserToken.create( :user_id => self.id, :auth_token => self.auth_token )
    end while self.class.exists?(auth_token: auth_token)
  end

  def get_role 
    case self.role
    when ADMIN
      "Administrador"
    when PROJECT_MANAGER
      "Project Manager"
    when ACCOUNT_EXECUTIVE
      "Ejecutivo de cuenta"
    when WAREHOUSE_ADMIN
      "Jefe de almacén"
    when DELIVERY
      "Repartidor"
    when CLIENT
      "Cliente" 
    end
  end

  def transfer_inventory_to new_user_id
    new_user = User.find( new_user_id )
    if self.role == PROJECT_MANAGER
      self.pm_items.each do |item|
        PmItem.create( :user_id => new_user_id, :inventory_item_id => item.inventory_item_id )
        sql = "DELETE from pm_items WHERE inventory_item_id = " + item.inventory_item_id.to_s + " AND user_id = " + self.id.to_s
        ActiveRecord::Base.connection.execute(sql)
      end
    elsif self.role == ACCOUNT_EXECUTIVE
      self.ae_items.each do |item|
        AeItem.create( :user_id => new_user_id, :inventory_item_id => item.inventory_item_id )
        sql = "DELETE from ae_items WHERE inventory_item_id = " + item.inventory_item_id.to_s + " AND user_id = " + self.id.to_s
        ActiveRecord::Base.connection.execute(sql)
      end
    end
  end

  def transfer_deliveries_to new_user_id
    new_user = User.find( new_user_id )
    self.deliveries.each do |delivery|
      new_user.deliveries << delivery
      new_user.save
    end
  end

  def transfer_requests_to new_user_id
    new_user = User.find( new_user_id )
    self.delivery_requests.each do |delivery_request|
      new_user.delivery_requests << delivery_request
      new_user.save
    end
    self.withdraw_requests.each do |wr|
      new_user.withdraw_requests << wr
      new_user.save
    end
  end

  

  scope :admin_users, -> { where( role: ADMIN ) }
  scope :pm_users, -> { where( role: PROJECT_MANAGER ) }
  scope :ae_users, -> { where( role: ACCOUNT_EXECUTIVE ) }
  scope :client_users, -> { where( role: CLIENT ) }
  scope :delivery_users, -> { where( role: DELIVERY ) }
  scope :pm_ae_users, -> { where('role = ? OR role = ?', PROJECT_MANAGER, ACCOUNT_EXECUTIVE ) }

  private

    def remove_from_projects
      self.projects.destroy_all
    end
end
