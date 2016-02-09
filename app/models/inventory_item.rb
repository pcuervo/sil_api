class InventoryItem < ActiveRecord::Base
  actable

  validates :name, :status, :item_type, :user, :project, presence: true
  validates :barcode, presence: true, uniqueness: true

  belongs_to :user
  belongs_to :project
  has_many :inventory_transactions
  has_many :item_locations
  has_many :warehouse_transactions

  # For item image
  has_attached_file :item_img, :styles => { :medium => "300x300>" }, default_url: "/images/:style/missing.png", :path => ":rails_root/storage/#{Rails.env}#{ENV['RAILS_TEST_NUMBER']}/attachments/:id/:style/:basename.:extension", :url => ":rails_root/storage/#{Rails.env}#{ENV['RAILS_TEST_NUMBER']}/attachments/:id/:style/:basename.:extension", :s3_credentials => S3_CREDENTIALS
  validates_attachment_content_type :item_img, content_type: /\Aimage\/.*\Z/
  
  # Item status
  IN_STOCK = 1
  OUT_OF_STOCK = 2
  PARTIAL_STOCK = 3
  EXPIRED = 4
  PENDING_ENTRY = 5
  PENDING_WITHDRAWAL = 6

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
    inventory_items = inventory_items.where('status=?', IN_STOCK).recent if params[:recent].present?

    inventory_items_details = { 'inventory_items' => [] }

    inventory_items.each do |i|
      inventory_items_details['inventory_items'].push({
        'id'                            => i.id,
        'name'                          => i.name,
        'item_type'                     => i.item_type,
        'quantity'                      => i.get_quantity,
        'actable_type'                  => i.actable_type,
        'created_at'                    => i.created_at,
        'validity_expiration_date'      => i.validity_expiration_date
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
    details = { 'inventory_item' => {
        'id'                        => self.id,
        'actable_id'                => self.actable_id,
        'name'                      => self.name,
        'actable_type'              => self.actable_type,
        'item_type'                 => self.item_type,
        'barcode'                   => self.barcode,
        'project'                   => project.name,
        'pm'                        => pm,
        'ae'                        => ae,
        'description'               => self.description,
        'client'                    => client,
        'client_contact'            => client_contact,
        'img'                       => item_img(:medium),
        'state'                     => self.state,
        'item_type'                 => self.item_type,
        'value'                     => self.value,
        'validity_expiration_date'  => self.validity_expiration_date,
        'created_at'                => self.created_at
      }  
    }

    if 'BulkItem' == self.actable_type
      bulk_item = BulkItem.find( self.actable_id )
      details['inventory_item']['quantity'] = bulk_item.quantity
    end

    if 'BundleItem' == self.actable_type
      bundle_item = BundleItem.find( self.actable_id )
      details['inventory_item']['parts'] = bundle_item.bundle_item_parts
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

  scope :recent, -> {
    order(updated_at: :desc).limit(5)
  }

end
