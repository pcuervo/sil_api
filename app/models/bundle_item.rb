class BundleItem < ActiveRecord::Base
  acts_as :inventory_item
  has_many :bundle_item_parts

  validates :num_parts, :numericality => {:greater_than_or_equal_to => 0}, :allow_nil => true


  def add_new_parts( parts = [] )
    parts.each do |p|
      new_part = BundleItemPart.create( parts_params( p )  )
      self.bundle_item_parts << new_part
    end
    update_num_parts
  end

  def add_existing_parts( partsId = [] )
    self.bundle_item_parts.each do |p|
      partsId.each do |id|
        next if p.id != id.to_i
        p.status = InventoryItem::IN_STOCK
        p.save
      end  
    end
    update_status
  end

  def remove_parts( partsId = [] )
    self.bundle_item_parts.each do |p|
      partsId.each do |id|
        if p.id == id.to_i
          p.status = InventoryItem::OUT_OF_STOCK
          p.save
        end
      end
    end
    update_status
  end

  def update_num_parts
    self.num_parts = self.bundle_item_parts.count
    self.save
  end

  def update_status
    out_of_stock_parts = 0
    self.bundle_item_parts.each do |p|
      if p.status == InventoryItem::OUT_OF_STOCK
        out_of_stock_parts += 1
      end
    end

    if 0 == out_of_stock_parts 
      self.status = InventoryItem::IN_STOCK
      self.save
      return
    end

    if out_of_stock_parts == self.num_parts
      self.status = InventoryItem::OUT_OF_STOCK
      self.save
      return
    end

    self.status = InventoryItem::PARTIAL_STOCK
    self.save
  end


  private 
    def parts_params( params )
      params.permit( :name, :serial_number, :brand, :model )
    end
end
