class InventoryItem < ActiveRecord::Base
  after_create :send_notification_to_account_executives, if: :belongs_to_client?
  after_create :send_entry_request_notifications, if: :has_pending_entry?

  actable

  validates :name, :status, :item_type, :user, :project, presence: true
  validates :barcode, presence: true, uniqueness: true

  belongs_to :user
  belongs_to :project
  has_many :inventory_transactions
  has_many :item_locations
  has_many :warehouse_transactions

  # For item image
  has_attached_file :item_img, :styles => { :medium => "300x300>", :thumb => "100x100#" }, default_url: "/images/:style/missing.png", :path => ":rails_root/storage/#{Rails.env}#{ENV['RAILS_TEST_NUMBER']}/attachments/:id/:style/:basename.:extension", :url => ":rails_root/storage/#{Rails.env}#{ENV['RAILS_TEST_NUMBER']}/attachments/:id/:style/:basename.:extension", :s3_credentials => S3_CREDENTIALS
  validates_attachment_content_type :item_img, content_type: /\Aimage\/.*\Z/
  
  # Item status
  IN_STOCK = 1
  OUT_OF_STOCK = 2
  PARTIAL_STOCK = 3
  EXPIRED = 4
  PENDING_ENTRY = 5
  PENDING_WITHDRAWAL = 6
  PENDING_APPROVAL = 7

  # States
  NEW = 1
  AS_NEW = 2
  USED = 3
  DAMAGED = 4
  INCOMPLETE = 5
  NEED_MAINTENANCE = 6
  GOOD = 7

  def self.search( params = {} )
    inventory_items = InventoryItem.all
    inventory_items = inventory_items.where( 'status IN (?)', [ IN_STOCK, PARTIAL_STOCK ] ).recent if params[:recent].present?
    inventory_items = inventory_items.in_stock if params[:in_stock].present?
    inventory_items = inventory_items.out_of_stock if params[:out_of_stock].present?

    if params[:keyword]
      inventory_items = inventory_items.where( 'lower( name ) LIKE ? OR lower( barcode ) LIKE ?', "%#{params[:keyword].downcase}%", "%#{params[:keyword].downcase}%" )
    end

    if params[:project_id].present?
      inventory_items = inventory_items.where( 'project_id = ?', params[:project_id] )
    end

    if params[:item_type].present?
      inventory_items = inventory_items.where( 'item_type = ?', params[:item_type] )
    end

    if params[:status].present?
      inventory_items = inventory_items.where( 'status = ?', params[:status] )
    end

    if params[:pm_id].present?
      user = User.find( params[:pm_id] )
      projects = user.projects
      projects_id = []
      projects.each {|p| projects_id.push(p.id) }
      inventory_items = inventory_items.where( 'project_id IN (?)', projects_id )
    end

    if params[:ae_id].present?
      user = User.find( params[:ae_id] )
      projects = user.projects
      projects_id = []
      projects.each {|p| projects_id.push(p.id) }
      inventory_items = inventory_items.where( 'project_id IN (?)', projects_id )
    end

    if params[:client_contact_id].present?
      user = User.find( params[:client_contact_id] )
      projects = user.projects
      projects_id = []
      projects.each {|p| projects_id.push(p.id) }
      inventory_items = inventory_items.where( 'project_id IN (?)', projects_id )
    end

    if params[:storage_type].present?
      inventory_items = inventory_items.where( 'storage_type = ?', params[:storage_type] )
    end

    inventory_items_details = { 'inventory_items' => [] }
    inventory_items.each do |i|
      inventory_items_details['inventory_items'].push({
        'id'                        => i.id,
        'name'                      => i.name,
        'item_type'                 => i.item_type,
        'quantity'                  => i.get_quantity,
        'actable_type'              => i.actable_type,
        'storage_type'              => i.storage_type,
        'status'                    => i.status,
        'barcode'                   => i.barcode,
        'value'                     => i.value,
        'locations'                 => i.get_locations,
        'img'                       => i.item_img(:thumb),
        'created_at'                => i.created_at,
        'validity_expiration_date'  => i.validity_expiration_date
      })
    end

    inventory_items_details
  end

  def get_details
    project = Project.find(self.project_id)
    pm = project.get_pm
    ae = project.get_ae
    client = project.get_client
    client_contact = project.get_client_contact
    locations = get_locations

    details = { 'inventory_item' => {
        'id'                        => self.id,
        'actable_id'                => self.actable_id,
        'name'                      => self.name,
        'actable_type'              => self.actable_type,
        'item_type'                 => self.item_type,
        'barcode'                   => self.barcode,
        'project'                   => project.name,
        'project_number'            => project.litobel_id,
        'pm'                        => pm,
        'ae'                        => ae,
        'description'               => self.description,
        'client'                    => client,
        'client_contact'            => client_contact,
        'img'                       => item_img(:medium),
        'state'                     => self.state,
        'status'                     => self.status,
        'storage_type'              => self.storage_type,
        'value'                     => self.value,
        'validity_expiration_date'  => self.validity_expiration_date,
        'locations'                 => locations,
        'quantity'                  => self.get_quantity,
        'created_at'                => self.created_at
      }  
    }

    if 'UnitItem' == self.actable_type
      unit_item = UnitItem.find( self.actable_id )
      details['inventory_item']['serial_number'] = unit_item.serial_number
      details['inventory_item']['brand'] = unit_item.brand
      details['inventory_item']['model'] = unit_item.model
    end

    if 'BulkItem' == self.actable_type
      bulk_item = BulkItem.find( self.actable_id )
    end

    if 'BundleItem' == self.actable_type
      bundle_item = BundleItem.find( self.actable_id )
      details['inventory_item']['num_parts'] = bundle_item.num_parts
      details['inventory_item']['parts'] = [] 
      bundle_item.bundle_item_parts.each do |part|
        details['inventory_item']['parts'].push( part.get_details )
      end
      puts details['inventory_item']['parts'].to_yaml
    end

    details
  end

  def get_quantity
    i = InventoryItem.get_by_type( self.actable_id, self.actable_type )
    return 1 if self.actable_type == 'UnitItem' 
    return i.quantity if self.actable_type == 'BulkItem'
    return i.num_parts if self.actable_type == 'BundleItem'
  end

  def self.get_by_type( id, type )
    case type
    when 'UnitItem'
      return UnitItem.find( id )
    when 'BulkItem'
      return BulkItem.find( id )
    when 'BundleItem'
      return BundleItem.find( id )
    end
  end

  def get_status
    case self.status
    when IN_STOCK 
      return 'Disponible'
    when OUT_OF_STOCK
      return 'No disponible'
    when PARTIAL_STOCK
      return 'Disponible parcialmente'
    when EXPIRED
      return 'Expirado'
    when PENDING_ENTRY
      return 'Entrada pendiente'
    when PENDING_WITHDRAWAL
      return 'Salida pendiente'
    end
  end

  def has_location?
    return self.item_locations.present?
  end

  def get_locations
    locations = []
    item_locations = self.item_locations
    item_locations.each do |il|
      locations.push({
        'rack'        => il.warehouse_location.warehouse_rack.name,
        'location_id' => il.warehouse_location.id,
        'location'    => il.warehouse_location.name,
        'quantity'    => il.quantity,
        'units'       => il.units
      })
    end
    locations
  end

  # Withdraws InventoryItem
  # * *Returns:* 
  #   - true if successful or error code
  def withdraw exit_date, estimated_return_date, pickup_company, pickup_company_contact, additional_comments
    case self.actable_type
    when 'UnitItem'
      unit_item = UnitItem.find( self.actable_id )
      return unit_item.withdraw( exit_date, estimated_return_date, pickup_company, pickup_company_contact, additional_comments )
    when 'BulkItem'
      bulk_item = BulkItem.find( self.actable_id )
      return bulk_item.withdraw( exit_date, estimated_return_date, pickup_company, pickup_company_contact, additional_comments )
    when 'BundleItem'
      bundle_item = BundleItem.find( self.actable_id )
      return bundle_item.withdraw( exit_date, estimated_return_date, pickup_company, pickup_company_contact, additional_comments )
    end
  end

  # Check if InventoryItem can be withdrawn
  # * *Returns:* 
  #   - bool
  def cannot_withdraw?
    case self.status
    when InventoryItem::OUT_OF_STOCK
      return true
    when InventoryItem::PENDING_ENTRY
      return true
    when InventoryItem::PENDING_WITHDRAWAL
      return true
    when InventoryItem::EXPIRED
      return true
    end
    return false
  end

  def belongs_to_client?
    return true if self.user.role == User::CLIENT

    return false
  end

  def has_pending_entry?
    return true if self.status == PENDING_ENTRY

    return false
  end

  scope :recent, -> {
    order(updated_at: :desc).limit(10)
  }

  scope :in_stock, -> {
    where('status IN (?)', [ IN_STOCK, PARTIAL_STOCK ]).order(updated_at: :desc)
  }

  scope :out_of_stock, -> {
    where('status = ?', OUT_OF_STOCK)
  }

  scope :this_month, -> {
    where( 'created_at > ? AND created_at < ?', 
            Date.today.beginning_of_month, 
            Date.today.end_of_month )
  }

  scope :last_month, -> {
    where( 'created_at > ? AND created_at < ?', 
            Date.today.last_month.beginning_of_month, 
            Date.today.beginning_of_month )
  }

  private

  def send_notification_to_account_executives
    project = self.project
    account_executives = project.users.where( 'role = ?', User::ACCOUNT_EXECUTIVE )
    account_executives.each do |ae|
      ae.notifications << Notification.create( :title => 'Solicitud de entrada', :inventory_item_id => self.id, :message => 'El cliente "' + self.user.first_name + ' ' + self.user.last_name + '" ha solicitado un ingreso.' )
    end
  end 

  def send_entry_request_notifications
    admins = User.where( 'role IN (?)', [ User::ADMIN, User::WAREHOUSE_ADMIN ]  )
    admins.each do |admin|
      admin.notifications << Notification.create( :title => 'Solicitud de entrada', :inventory_item_id => self.id, :message => self.user.get_role + ' "' + self.user.first_name + ' ' + self.user.last_name + '" ha solicitado el ingreso del artículo "' + self.name + '".' )
    end
  end 

end
