class User < ActiveRecord::Base
  actable
  before_create :generate_authentication_token!

	validates :auth_token, uniqueness: true
  validates :role, inclusion: { in: [1, 2, 3, 4, 5, 6], message: "%{value} is not a valid role" }
  validates :first_name, :last_name, :email, :role, presence: true

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :inventory_items
  has_many :logs
  has_and_belongs_to_many :projects

  # AVAILABLE ROLES
  ADMIN = 1
  PROJECT_MANAGER = 2
  ACCOUNT_EXECUTIVE = 3
  WAREHOUSE_ADMIN = 4
  DELIVERY = 5
  CLIENT = 6
 	
 	def generate_authentication_token!
    begin
      self.auth_token = Devise.friendly_token
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

  scope :admin_users, -> { where( role: ADMIN ) }
  scope :pm_users, -> { where( role: PROJECT_MANAGER ) }
  scope :ae_users, -> { where( role: ACCOUNT_EXECUTIVE ) }
  scope :client_users, -> { where( role: CLIENT ) }
  scope :pm_ae_users, -> { where('role = ? OR role = ?', PROJECT_MANAGER, ACCOUNT_EXECUTIVE ) }
end
