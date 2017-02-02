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

  has_attached_file :image, :styles => { :medium => "300x300>" }, default_url: "/images/:style/missing.png", :path => ":rails_root/storage/#{Rails.env}#{ENV['RAILS_TEST_NUMBER']}/attachments/:id/:style/:basename.:extension", :url => ":rails_root/storage/#{Rails.env}#{ENV['RAILS_TEST_NUMBER']}/attachments/:id/:style/:basename.:extension", :s3_credentials => S3_CREDENTIALS
  validates_attachment_content_type :image, content_type: /\Aimage\/.*\Z/

  def add_items items, delivery_guy, additional_comments
    items.each do |i|
      item = InventoryItem.find( i[:item_id] )
      litobel_supplier = Supplier.find_by_name( 'Litobel' )
      item.withdraw Time.now, '', litobel_supplier.id, delivery_guy, additional_comments, i[:quantity].to_i
      DeliveryItem.create( :inventory_item_id => i[:item_id], :delivery_id => self.id, :quantity => i[:quantity], )
    end
  end

  def get_details
    delivery_guy = get_delivery_guy( self.delivery_user_id )

    details = { 'delivery' => {
        'id'                  => self.id,
        'delivery_guy'        => delivery_guy,
        'user'                => self.user.first_name + ' ' + self.user.last_name,
        'delivery_items'      => self.delivery_items.details,
        'address'             => self.address,
        'latitude'            => self.latitude,
        'longitude'           => self.longitude,
        'company'             => self.company,
        'image'               => self.image,
        'status'              => self.status,
        'supplier'            => get_supplier( self.supplier_id ),
        'addressee'           => self.addressee,
        'addressee_phone'     => self.addressee_phone,
        'additional_comments' => self.additional_comments,
        'created_at'          => self.created_at
      }  
    }
    details
  end

  scope :recent, -> {
    order(updated_at: :desc).limit(10)
  }

  scope :shipped, -> {
    where( 'status = ?', SHIPPED )
  }

  scope :delivered, -> {
    where( 'status = ?', DELIVERED )
  }

  scope :rejected, -> {
    where( 'status = ?', REJECTED )
  }

  scope :pending_approval, -> {
   where( 'status = ?', PENDING_APPROVAL )
  }

  private

    def get_delivery_guy user_id
      delivery_guy = User.find_by_id( user_id )

      return delivery_guy.first_name + ' ' + delivery_guy.last_name if delivery_guy.present?

      return '-'
    end

    def get_supplier supplier_id
      supplier = Supplier.find_by_id( self.supplier_id )

      return supplier.name if supplier.present?

      return '-'
    end

end
