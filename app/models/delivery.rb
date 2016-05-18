class Delivery < ActiveRecord::Base
  validates :company, :addressee, :address, :delivery_user_id, presence: true

  belongs_to :user
  has_many :delivery_items

  SHIPPED = 1
  DELIVERED = 2
  REJECTED = 3
  PARTIALLY_DELIVERED = 4
  PENDING_APPROVAL = 5

  has_attached_file :image, :styles => { :medium => "300x300>" }, default_url: "/images/:style/missing.png", :path => ":rails_root/storage/#{Rails.env}#{ENV['RAILS_TEST_NUMBER']}/attachments/:id/:style/:basename.:extension", :url => ":rails_root/storage/#{Rails.env}#{ENV['RAILS_TEST_NUMBER']}/attachments/:id/:style/:basename.:extension", :s3_credentials => S3_CREDENTIALS
  validates_attachment_content_type :image, content_type: /\Aimage\/.*\Z/

  def add_items items, delivery_guy, additional_comments
    items.each do |i|
      item = InventoryItem.find( i[:item_id] )
      item.withdraw Time.now, '', 'Envío Litobel', delivery_guy, additional_comments, i[:quantity].to_i
      DeliveryItem.create( :inventory_item_id => i[:item_id], :delivery_id => self.id, :quantity => i[:quantity], )
    end
  end

  def get_details
    delivery_guy = User.find( self.delivery_user_id )

    details = { 'delivery' => {
        'id'                  => self.id,
        'delivery_guy'        => delivery_guy.first_name + ' ' + delivery_guy.last_name,
        'user'                => self.user.first_name + ' ' + self.user.last_name,
        'delivery_items'      => self.delivery_items.details,
        'address'             => self.address,
        'latitude'            => self.latitude,
        'longitude'           => self.longitude,
        'company'             => self.company,
        'image'               => self.image,
        'status'              => self.status,
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

end
