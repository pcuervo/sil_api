class Delivery < ActiveRecord::Base
  validates :company, :addressee, :address, presence: true

  belongs_to :user
  has_many :delivery_items

  READY_TO_SHIP = 0
  SHIPPED = 1
  DELIVERED = 2
  REJECTED = 3
  PARTIALLY_DELIVERED = 4
  PENDING_APPROVAL = 5
  SCHEDULED_DELIVERY = 6

  has_attached_file :image, styles: { medium: '300x300>' }, default_url: '/images/:style/missing.png', path: ":rails_root/storage/#{Rails.env}#{ENV['RAILS_TEST_NUMBER']}/attachments/:id/:style/:basename.:extension", url: ":rails_root/storage/#{Rails.env}#{ENV['RAILS_TEST_NUMBER']}/attachments/:id/:style/:basename.:extension", s3_credentials: S3_CREDENTIALS
  validates_attachment_content_type :image, content_type: /\Aimage\/.*\Z/

  def add_items(items, delivery_guy, additional_comments)
    next_checkout_folio = InventoryTransaction.next_checkout_folio
    items.each do |i|
      item = InventoryItem.find(i[:item_id])
      litobel_supplier = Supplier.find_by_name('Litobel')
      item.withdraw(Time.now, '', litobel_supplier.id, delivery_guy, additional_comments, i[:quantity].to_i, next_checkout_folio)

      DeliveryItem.create(inventory_item_id: i[:item_id], delivery_id: id, quantity: i[:quantity])
    end
  end

  def details
    delivery_guy = get_delivery_guy(delivery_user_id)

    details = { 'delivery' => {
      'id' => id,
      'delivery_guy'        => delivery_guy,
      'user'                => user.first_name + ' ' + user.last_name,
      'delivery_items'      => delivery_items.details,
      'address'             => address,
      'latitude'            => latitude,
      'longitude'           => longitude,
      'company'             => company,
      'image'               => image,
      'status'              => status,
      'supplier'            => get_supplier(supplier_id),
      'addressee'           => addressee,
      'addressee_phone'     => addressee_phone,
      'additional_comments' => additional_comments,
      'created_at'          => created_at,
      'date_time' => date_time
    } }
    details
  end

  def withdrawn_items_locations
    withdrawn_locations = []
    delivery_items.each do |item|
      item_location = ItemLocation.where('inventory_item_id = ? AND quantity = ?', item.inventory_item_id, item.quantity).last

      next unless item_location.present?
    end

    withdrawn_locations
  end

  # @todo Clean InventoryItem.search, remove ids_only
  # return ActiveRelation
  def self.by_keyword(params)
    ids_only = true
    deliveries = []

    inventory_item_ids = InventoryItem.search(params, ids_only)
    delivery_ids = DeliveryItem.where('inventory_item_id IN (?)', inventory_item_ids).pluck(:delivery_id)

    Delivery.where('id IN (?)', delivery_ids).each do |delivery|
      details = delivery.details
      deliveries.push(details['delivery'])
    end
    deliveries
  end

  scope :recent, -> { order(updated_at: :desc).limit(10) }
  scope :shipped, -> { where('status = ?', SHIPPED) }
  scope :delivered, -> { where('status = ?', DELIVERED) }
  scope :rejected, -> { where('status = ?', REJECTED) }
  scope :pending_approval, -> { where('status = ?', PENDING_APPROVAL) }

  private

  def get_delivery_guy(user_id)
    delivery_guy = User.find_by_id(user_id)

    return delivery_guy.first_name + ' ' + delivery_guy.last_name if delivery_guy.present?

    '-'
  end

  def get_supplier(_supplier_id)
    supplier = Supplier.find_by_id(supplier_id)

    return supplier.name if supplier.present?

    '-'
  end
end
