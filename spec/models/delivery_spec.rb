require 'spec_helper'

describe Delivery, type: :model do
  before { @delivery = FactoryGirl.build(:delivery) }

  it { should validate_presence_of :company }
  it { should validate_presence_of :addressee }
  it { should validate_presence_of :address }

  it { should belong_to :user }

  describe ".add_items" do
    before(:each) do
      @delivery = FactoryGirl.create :delivery
      supplier = FactoryGirl.create :supplier
      supplier.name = 'Litobel'
      supplier.save
      @items = []
      3.times do |t|
        delivery_item = {}
        unit_item = FactoryGirl.create :unit_item
        item = FactoryGirl.create :inventory_item
        item.actable_type = 'UnitItem'
        item.actable_id = unit_item.id
        item.save
        delivery_item[:item_id] = item.id
        delivery_item[:quantity] = 1
        @items.push( delivery_item )
      end
    end

    it "creates 2 DeliveryItems" do
      @delivery.add_items( @items, 'El Chomper', 'No comments' )
      expect( DeliveryItem.all.count ).to eq 3
    end

    it "register InventoryTransaction with folio" do 
      @delivery.add_items( @items, 'El Chomper', 'No comments' )
      first_transaction_folio = CheckOutTransaction.first.folio
      expect(first_transaction_folio).to eq 'FS-0000001'
    end
  end

  describe ".get_withdrawn_locations" do
    before(:each) do
      @delivery = FactoryGirl.create :delivery
      supplier = FactoryGirl.create :supplier
      supplier.name = 'Litobel'
      supplier.save
      @items = []
      2.times do |t|
        delivery_item = {}
        unit_item = FactoryGirl.create :unit_item
        location = FactoryGirl.create :warehouse_location
        item = FactoryGirl.create :inventory_item
        item.actable_type = 'UnitItem'
        item.actable_id = unit_item.id
        item.save

        item_location = ItemLocation.find( location.locate( item.id, 1, 1 ) )
        item_location.save

        delivery_item[:item_id] = item.id
        delivery_item[:quantity] = 1
        @items.push( delivery_item )
      end
    end

    it "returns WarehouseLocations from which delivery Items where removed" do
      @delivery.add_items( @items, 'El Chomper', 'No comments' )
      widthdrawn_locations = @delivery.get_withdrawn_locations

      expect( 3 ).to eq 3
    end
  end
end
