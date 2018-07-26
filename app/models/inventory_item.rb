class InventoryItem < ActiveRecord::Base # rubocop:disable Metrics/ClassLength
  after_create :send_notification_to_account_executives, if: :belongs_to_client?
  after_create :send_entry_request_notifications, if: :pending_entry?
  before_destroy :delete_transactions
  before_destroy :delete_warehouse_transactions
  before_destroy :delete_item_locations
  before_destroy :delete_withdraw_request_items
  before_destroy :delete_delivery_request_items
  before_destroy :delete_pm_items
  before_destroy :delete_ae_items
  before_destroy :delete_bundle_item_parts

  validates :name, :status, :item_type, :user, :project, :serial_number, presence: true
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

  def self.search(params = {}, ids_only = false)
    inventory_items = InventoryItem.all.order(created_at: :desc)
    inventory_items = inventory_items.where('status IN (?)', [IN_STOCK, PARTIAL_STOCK]).recent if params[:recent].present?
    inventory_items = inventory_items.in_stock if params[:in_stock].present?
    inventory_items = inventory_items.out_of_stock if params[:out_of_stock].present?
    inventory_items_details = { 'inventory_items' => [] }

    inventory_items = inventory_items.where('lower(name) LIKE ? OR lower(barcode) LIKE ? OR lower(serial_number) LIKE ?', "%#{params[:keyword].downcase}%", "%#{params[:keyword].downcase}%", "%#{params[:keyword].downcase}%") if params[:keyword]

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

    inventory_items = inventory_items.page(params[:page]).per(50).order(created_at: :desc) if params[:page]

    return inventory_items.pluck(:id) if ids_only

    inventory_items.each do |i|
      inventory_items_details['inventory_items'].push(i.get_details)
    end

    inventory_items_details
  end

  def get_details
    project = Project.find(project_id)
    pm = get_pm(project)
    ae = get_ae(project)

    client = project.client
    client_contact = project.client_contact
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
        'img_thumb' => item_img(:thumb),
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
        'model' => model,
        'extra_parts' => extra_parts
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
    item_locations.each do |il|
      locations.push(
        'rack'        => il.warehouse_location.warehouse_rack.name,
        'location_id' => il.warehouse_location.id,
        'location'    => il.warehouse_location.name,
        'quantity'    => il.quantity
      )
    end
    locations
  end

  # Withdraws InventoryItem and remove from WarehouseLocation if it has any
  # * *Returns:*
  #   - true if successful or error code
  def withdraw(exit_date, estimated_return_date, pickup_company, pickup_company_contact, additional_comments, quantity_to_withdraw, folio = '-')
    return status if cannot_withdraw?

    if quantity_to_withdraw != '' && quantity_to_withdraw < quantity.to_i
      self.quantity = quantity.to_i - quantity_to_withdraw
      quantity_withdrawn = quantity_to_withdraw
    else
      self.status = InventoryItem::OUT_OF_STOCK
      quantity_withdrawn = quantity
      self.quantity = 0
    end

    save

    # Withdraw from WarehouseLocations
    withdraw_from_locations(quantity_withdrawn) if warehouse_locations?

    CheckOutTransaction.create(
      inventory_item_id: id,
      concept: 'Salida granel',
      additional_comments: additional_comments,
      exit_date: exit_date,
      estimated_return_date: estimated_return_date,
      pickup_company: pickup_company,
      pickup_company_contact: pickup_company_contact,
      quantity: quantity_withdrawn,
      folio: folio
    )
    true
  end

  # Withdraws a given quantity from the latest WarehouseLocation.
  #
  # @param quantity_to_withdraw [Integer].
  def withdraw_from_locations(quantity_to_withdraw)
    quantity_left = quantity_to_withdraw
    if quantity_to_withdraw != ''
      while quantity_left > 0
        item_location = item_locations.first

        break unless item_location.present?

        location = item_location.warehouse_location
        if quantity_left >= item_location.quantity
          current_location_quantity = item_location.quantity
          location.remove_item(id)
          item_locations.delete(item_location)
          location.update_status
        else
          location.remove_quantity(id, quantity_left)
          break
        end
        quantity_left -= current_location_quantity
      end
      return
    end

    item_location = item_locations.first
    location = item_location.warehouse_location
    location.remove_item(id)
    item_locations.delete(item_location)
    location.update_status
  end

  # Check if InventoryItem can be withdrawn
  #
  # @return [Boolean].
  def cannot_withdraw?
    cannot_withdraw = false
    case status
    when InventoryItem::OUT_OF_STOCK
      cannot_withdraw = true
    when InventoryItem::PENDING_ENTRY
      cannot_withdraw = true
    when InventoryItem::EXPIRED
      cannot_withdraw = true
    end

    cannot_withdraw
  end

  def belongs_to_client?
    return true if user.role == User::CLIENT

    false
  end

  def pending_entry?
    return true if status == PENDING_ENTRY

    false
  end

  def get_ae(project)
    return project.ae_name unless ae_items.present?

    ae = ae_items.first.user
    ae.first_name + ' ' + ae.last_name
  end

  def get_pm(project)
    return project.pm_name unless pm_items.present?

    pm = pm_items.first.user
    pm.first_name + ' ' + pm.last_name
  end

  def pm_id
    project = Project.find(project_id)
    return project.pm_id unless pm_items.present?

    pm = pm_items.first.user
    pm.id
  end

  def ae_id
    project = Project.find(project_id)
    return project.ae_id unless ae_items.present?

    ae = ae_items.first.user
    ae.id
  end

  def add(quantity_to_add, state, entry_date, concept, delivery_company, delivery_company_contact, additional_comments, folio = '-')
    raise SilExceptions::InvalidQuantityToAdd unless quantity_to_add > 0

    update(
      quantity: quantity + quantity_to_add,
      status: IN_STOCK,
      state: state
    )
    if save!
      CheckInTransaction.create(
        inventory_item_id: id,
        concept: concept,
        additional_comments: additional_comments,
        entry_date: entry_date,
        estimated_issue_date: '',
        delivery_company: delivery_company,
        delivery_company_contact: delivery_company_contact,
        quantity: quantity,
        folio: folio
      )
    end
  end

  def self.migrate_items
    InventoryItem.all.each do |item|
      if item.actable_type == 'BulkItem'
        bulk_item = BulkItem.find(item.actable_id)
        item.update_attributes(quantity: bulk_item.quantity)
      end

      next unless item.actable_type == 'UnitItem'
      unit = UnitItem.find(item.actable_id)
      item.update_attributes(
        serial_number: unit.serial_number,
        brand: unit.brand,
        model: unit.model,
        quantity: 1
      )
    end
  end

  def self.quick_search(keyword)
    InventoryItem.where('lower(name) LIKE ? OR lower(barcode) LIKE ? OR lower(serial_number) LIKE ?', "%#{keyword.downcase}%", "%#{keyword.downcase}%", "%#{keyword.downcase}%")
  end
  # Scopes

  scope :recent, lambda {
    order(created_at: :desc).limit(10)
  }

  scope :in_stock, lambda {
    where('status IN (?)', [IN_STOCK, PARTIAL_STOCK]).order(updated_at: :desc)
  }

  scope :out_of_stock, lambda {
    where('status = ?', OUT_OF_STOCK)
  }

  scope :this_month, lambda {
    where('created_at > ? AND created_at < ?', Date.today.beginning_of_month, Date.today.end_of_month)
  }

  scope :last_month, -> { where('created_at > ? AND created_at < ?', Date.today.last_month.beginning_of_month, Date.today.beginning_of_month) }

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
    account_executives = project.users.where('role = ?', User::ACCOUNT_EXECUTIVE)
    account_executives.each do |ae|
      ae.notifications << Notification.create(title: 'Solicitud de entrada', inventory_item_id: id, message: 'El cliente "' + user.first_name + ' ' + user.last_name + '" ha solicitado un ingreso.')
    end
  end

  def send_entry_request_notifications
    User.all_admin_users.each do |admin|
      admin.notifications << Notification.create(title: 'Solicitud de entrada', inventory_item_id: id, message: user.role_name + ' "' + user.first_name + ' ' + user.last_name + '" ha solicitado el ingreso del artículo "' + name + '".')
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
