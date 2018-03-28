class InventoryItem < ActiveRecord::Base # rubocop:disable Metrics/ClassLength
  after_create :send_notification_to_account_executives, if: :belongs_to_client?
  after_create :send_entry_request_notifications, if: :has_pending_entry?
  before_destroy :delete_transactions
  before_destroy :delete_warehouse_transactions
  before_destroy :delete_item_locations
  before_destroy :delete_withdraw_request_items
  before_destroy :delete_delivery_request_items
  before_destroy :delete_pm_items
  before_destroy :delete_ae_items
  before_destroy :delete_bundle_item_parts

  validates :name, :status, :item_type, :user, :project, presence: true
  validates :barcode, presence: true, uniqueness: true

  belongs_to :user
  belongs_to :project
  has_many :inventory_transactions
  has_many :item_locations
  has_many :warehouse_transactions
  has_many :withdraw_request_items
  has_many :delivery_request_items
  has_many :pm_items
  has_many :ae_items

  # For item image
  has_attached_file :item_img, styles: { medium: '300x300>', thumb: '100x100#' }, default_url: '/images/:style/missing.png', path: ":rails_root/storage/#{Rails.env}#{ENV['RAILS_TEST_NUMBER']}/attachments/:id/:style/:basename.:extension", url: ":rails_root/storage/#{Rails.env}#{ENV['RAILS_TEST_NUMBER']}/attachments/:id/:style/:basename.:extension", s3_credentials: S3_CREDENTIALS # rubocop:disable Metrics/LineLength

  validates_attachment_content_type :item_img, content_type: /\Aimage\/.*\Z/
  
  # Item status
  IN_STOCK = 1
  OUT_OF_STOCK = 2
  PARTIAL_STOCK = 3
  EXPIRED = 4
  PENDING_ENTRY = 5
  PENDING_WITHDRAWAL = 6
  PENDING_APPROVAL = 7
  PENDING_DELIVERY = 8

  # States
  NEW = 1
  AS_NEW = 2
  USED = 3
  DAMAGED = 4
  INCOMPLETE = 5
  NEED_MAINTENANCE = 6
  GOOD = 7

  def self.search(params = {})
    inventory_items = InventoryItem.all.order(created_at: :desc)
    inventory_items = inventory_items.where('status IN (?)', [IN_STOCK, PARTIAL_STOCK]).recent if params[:recent].present?
    inventory_items = inventory_items.in_stock if params[:in_stock].present?
    inventory_items = inventory_items.out_of_stock if params[:out_of_stock].present?
    inventory_items_details = { 'inventory_items' => [] }

    inventory_items = inventory_items.where('name LIKE ? OR lower(barcode) LIKE ? OR lower(serial_number) LIKE ?', "%#{params[:keyword]}%", "%#{params[:keyword].downcase}%", "%#{params[:keyword].downcase}%") if params[:keyword]

    inventory_items = inventory_items.where('project_id = ?', params[:project_id]) if params[:project_id].present?

    inventory_items = inventory_items.where('item_type = ?', params[:item_type]) if params[:item_type].present?

    inventory_items = inventory_items.where('status = ?', params[:status]) if params[:status].present?

    if params[:pm_id].present?
      user = User.find(params[:pm_id])
      projects = user.projects
      projects_id = []
      projects.each { |p| projects_id.push(p.id) }
      inventory_items = inventory_items.where('project_id IN (?)', projects_id)
    end

    if params[:ae_id].present?
      user = User.find(params[:ae_id])
      projects = user.projects
      projects_id = []
      projects.each { |p| projects_id.push(p.id) }
      inventory_items = inventory_items.where('project_id IN (?)', projects_id)
    end

    if params[:client_id].present?
      user = User.find(params[:client_id])
      client_user = ClientContact.find(user.actable_id)
      projects = client_user.client.projects
      projects_id = []
      projects.each { |p| projects_id.push(p.id) }
      inventory_items = inventory_items.where('project_id IN (?)', projects_id)
    end

    if params[:client_contact_id].present?
      user = User.find(params[:client_contact_id])
      projects = user.projects
      projects_id = []
      projects.each { |p| projects_id.push(p.id) }
      inventory_items = inventory_items.where('project_id IN (?)', projects_id)
    end

    inventory_items = inventory_items.where('storage_type = ?', params[:storage_type]) if params[:storage_type].present?

    inventory_items.each do |i|
      item_with_locations = {
        'item' => i,
        'locations' => i.warehouse_locations
      }
      inventory_items_details['inventory_items'].push(item_with_locations)
    end

    inventory_items_details
  end

  def get_details
    project = Project.find(project_id)
    pm = get_pm(project)
    ae = get_ae(project)

    client = project.get_client
    client_contact = project.get_client_contact
    locations = warehouse_locations

    details = {
      'inventory_item' => {
        'id' => id,
        'serial_number' => serial_number,
        'name' => name,
        'item_type' => item_type,
        'barcode' => barcode,
        'project' => project.litobel_id + ' / ' + project.name,
        'project_number' => project.litobel_id,
        'project_id' => project_id,
        'pm_id' => pm_id,
        'ae_id' => ae_id,
        'pm' => pm,
        'ae' => ae,
        'description' => description,
        'client' => client,
        'client_contact' => client_contact,
        'img' => item_img(:medium),
        'state' => state,
        'status' => status,
        'storage_type' => storage_type,
        'value' => value,
        'is_high_value' => is_high_value,
        'validity_expiration_date' => validity_expiration_date,
        'locations' => locations,
        'created_at' => created_at,
        'quantity' => quantity,
        'brand' => brand,
        'model' => model
      }
    }

    details
  end

  def status_name
    case status
    when IN_STOCK
      'Disponible'
    when OUT_OF_STOCK
      'No disponible'
    when PARTIAL_STOCK
      'Disponible parcialmente'
    when EXPIRED
      'Expirado'
    when PENDING_ENTRY
      'Entrada pendiente'
    when PENDING_WITHDRAWAL
      'Salida pendiente'
    end
  end

  def warehouse_locations?
    item_locations.present?
  end

  def warehouse_locations
    locations = []
    self.item_locations.each do |il|
      locations.push(
        'rack'        => il.warehouse_location.warehouse_rack.name,
        'location_id' => il.warehouse_location.id,
        'location'    => il.warehouse_location.name,
        'quantity'    => il.quantity,
        'units'       => il.units
      )
    end
    locations
  end

  # Withdraws InventoryItem and remove from WarehouseLocation if it has any
  # * *Returns:*
  #   - true if successful or error code
  def withdraw exit_date, estimated_return_date, pickup_company, pickup_company_contact, additional_comments, quantityToWithdraw
    
    return self.status if cannot_withdraw?

    puts 'current quantity: ' + quantity.to_s
    if quantityToWithdraw != '' and quantityToWithdraw < self.quantity.to_i
      self.quantity = self.quantity.to_i - quantityToWithdraw
      quantity_withdrawn = quantityToWithdraw
    else
      self.status = InventoryItem::OUT_OF_STOCK
      quantity_withdrawn = self.quantity
      self.quantity = 0
    end
    
    if self.save
      if self.warehouse_locations?
        quantity_left = quantityToWithdraw
        puts 'quantityToWithdraw: ' + quantityToWithdraw.to_s
        puts 'self.quantity: ' + self.quantity.to_s
        puts 'quantity_withdrawn: ' + quantity_withdrawn.to_s
        # if quantityToWithdraw != '' and quantityToWithdraw < ( self.quantity.to_i + quantity_withdrawn.to_i )
        #   item_location = self.item_locations.where( 'quantity >= ?', quantityToWithdraw ).first
        #   location = item_location.warehouse_location
        #   location.remove_quantity( self.id, quantityToWithdraw, 1 )
        # elsif 
        if quantityToWithdraw != ''
          while quantity_left > 0
            item_location = self.item_locations.first
            location = item_location.warehouse_location

            puts 'quantity_left: ' + quantity_left.to_s
            puts 'location quantity: ' + item_location.quantity .to_s
            if quantity_left >= item_location.quantity 
              current_location_quantity = item_location.quantity 
              location.remove_item( id )
              item_locations.delete( item_location )
              location.update_status
            else
              location.remove_quantity( id, quantity_left, 1 )
              break
            end
            quantity_left = quantity_left - current_location_quantity
          end
        else
          item_location = self.item_locations.first
          location = item_location.warehouse_location
          location.remove_item( self.id )
          self.item_locations.delete( item_location )
          location.update_status
        end
      end
      CheckOutTransaction.create( :inventory_item_id => self.id, :concept => 'Salida granel', :additional_comments => additional_comments, :exit_date => exit_date, :estimated_return_date => estimated_return_date, :pickup_company => pickup_company, :pickup_company_contact => pickup_company_contact, :quantity => quantity_withdrawn )
      return true
    end

    return false
  end

  # Withdraws InventoryItem
  # * *Returns:* 
  #   - true if successful or error code
  # def withdraw exit_date, estimated_return_date, pickup_company, pickup_company_contact, additional_comments, quantity=''
  #   case self.actable_type
  #   when 'UnitItem'
  #     unit_item = UnitItem.find(self.actable_id)
  #     return unit_item.withdraw(exit_date, estimated_return_date, pickup_company, pickup_company_contact, additional_comments)
  #   when 'BulkItem'
  #     bulk_item = BulkItem.find(self.actable_id)
  #     return bulk_item.withdraw(exit_date, estimated_return_date, pickup_company, pickup_company_contact, additional_comments, quantity)
  #   when 'BundleItem'
  #     bundle_item = BundleItem.find(self.actable_id)
  #     return bundle_item.withdraw(exit_date, estimated_return_date, pickup_company, pickup_company_contact, additional_comments)
  #   end
  # end

  # Check if InventoryItem can be withdrawn
  # * *Returns:* 
  #   - bool
  def cannot_withdraw?
    case self.status
    when InventoryItem::OUT_OF_STOCK
      return true
    when InventoryItem::PENDING_ENTRY
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

  def self.estimated_current_rent project_ids=-1

    if -1 != project_ids
      current_occupied_units = InventoryItem.joins(:item_locations).where('status IN (?) AND project_id IN (?)', [ InventoryItem::IN_STOCK, InventoryItem::PARTIAL_STOCK, InventoryItem::PENDING_ENTRY ], project_ids).sum(:units)
    else
      current_occupied_units = InventoryItem.joins(:item_locations).where('status IN (?)', [ InventoryItem::IN_STOCK, InventoryItem::PARTIAL_STOCK, InventoryItem::PENDING_ENTRY ]).sum(:units)
    end

    settings = SystemSetting.select(:units_per_location, :cost_per_location).first
    rounded_units = current_occupied_units / settings.units_per_location * settings.units_per_location + settings.units_per_location

    return rounded_units / settings.units_per_location.to_f  * settings.cost_per_location 
  end

  def get_ae project
    ae_items = self.ae_items
    return project.get_ae if ! ae_items.present? 

    ae = ae_items.first.user
    return ae.first_name + ' ' + ae.last_name
  end

  def get_pm project
    pm_items = self.pm_items
    return project.get_pm if ! pm_items.present? 

    pm = pm_items.first.user
    return pm.first_name + ' ' + pm.last_name
  end

  def pm_id
    project = Project.find(self.project_id)
    pm_items = self.pm_items
    return project.get_pm_id if ! pm_items.present? 

    pm = pm_items.first.user
    return pm.id
  end

  def ae_id
    project = Project.find(self.project_id)
    ae_items = self.ae_items
    return project.get_ae_id if ! ae_items.present?

    ae = ae_items.first.user
    return ae.id
  end

  # Scopes 
  
  scope :recent, lambda {
    order(created_at: :desc).limit(10)
  }

  scope :in_stock, lambda {
    where('status IN (?)', [ IN_STOCK, PARTIAL_STOCK ]).order(updated_at: :desc)
  }

  scope :out_of_stock, lambda {
    where('status = ?', OUT_OF_STOCK)
  }

  scope :this_month, lambda {
    where('created_at > ? AND created_at < ?', Date.today.beginning_of_month, Date.today.end_of_month)
  }

  scope :last_month, -> { where('created_at > ? AND created_at < ?', Date.today.last_month.beginning_of_month, Date.today.beginning_of_month)
  }

  scope :inventory_value, -> { where('status IN (?)', [IN_STOCK, PARTIAL_STOCK, PENDING_ENTRY]).sum(:value) }

  scope :inventory_by_type, lambda { |project_ids = nil|
    if !project_ids.nil?
      where('project_id IN (?)', project_ids).group(:item_type).count
    else
      group(:item_type).count
    end
  }

  scope :occupation_by_month, lambda {
    find_by_sql("
      SELECT to_char(created_at, 'MM-YY') as mon, count(created_at)
      FROM warehouse_transactions
      WHERE concept = 1
      GROUP BY 1
      ORDER BY to_char(created_at, 'MM-YY')
      LIMIT 12")
  }

  scope :total_high_value_items, -> { where('is_high_value = ?', 1).count }

  private

  def send_notification_to_account_executives
    project = self.project
    account_executives = project.users.where('role = ?', User::ACCOUNT_EXECUTIVE)
    account_executives.each do |ae|
      ae.notifications << Notification.create(title: 'Solicitud de entrada', inventory_item_id: id, message: 'El cliente "' + user.first_name + ' ' + user.last_name + '" ha solicitado un ingreso.')
    end
  end

  def send_entry_request_notifications
    admins = User.where('role IN (?)', [User::ADMIN, User::WAREHOUSE_ADMIN])
    admins.each do |admin|
      admin.notifications << Notification.create(title: 'Solicitud de entrada', inventory_item_id: id, message: user.get_role + ' "' + user.first_name + ' ' + user.last_name + '" ha solicitado el ingreso del artículo "' + name + '".')
    end
  end

  def delete_transactions
    inventory_transactions.destroy_all
  end

  def delete_warehouse_transactions
    warehouse_transactions.destroy_all
  end

  def delete_item_locations
    item_locations.destroy_all
  end

  def delete_withdraw_request_items
    withdraw_request_items.destroy_all
  end

  def delete_bundle_item_parts
    return if actable_type != 'BundleItem'

    sql = 'DELETE from bundle_item_parts WHERE bundle_item_id = ' + actable_id.to_s
    ActiveRecord::Base.connection.execute(sql)
  end

  def delete_delivery_request_items
    delivery_request_items.destroy_all
  end

  def delete_pm_items
    sql = 'DELETE from pm_items WHERE inventory_item_id = ' + id.to_s
    ActiveRecord::Base.connection.execute(sql)
  end

  def delete_ae_items
    sql = 'DELETE from ae_items WHERE inventory_item_id = ' + id.to_s
    ActiveRecord::Base.connection.execute(sql)
  end
end
