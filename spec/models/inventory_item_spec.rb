require 'spec_helper'

describe InventoryItem do
  let(:inventory_item) { FactoryGirl.build :inventory_item }
  subject { inventory_item }

  it { should respond_to(:name) }
  it { should respond_to(:description) }
  it { should respond_to(:image_url) }
  it { should respond_to(:status) }
  it { should respond_to(:quantity) }
  it { should respond_to(:serial_number) }
  it { should respond_to(:brand) }
  it { should respond_to(:model) }

  # Required fields
  it { should validate_presence_of :name }
  it { should validate_presence_of :status }
  it { should validate_presence_of :item_type }

  # Required relations
  it { should validate_presence_of(:user)}
  it { should validate_presence_of(:project) }

  it { should belong_to :user }
  it { should belong_to :project }
  it { should have_many(:item_locations) }

  describe ".search" do
    before(:each) do
      @params = {}
      @inventory_item = FactoryGirl.create :inventory_item
    end

    it "returns an array of InventoryItems given a keyword" do
      @inventory_item.name = 'Somename'
      @inventory_item.save

      @params['keyword'] = 'somen'
      searched_items = InventoryItem.search(@params)
      expect( searched_items['inventory_items'].first['item']['name'] ).to eq 'Somename'
    end

    it "returns an array of InventoryItems given a serial_number" do
      @inventory_item.serial_number = 'Serial'
      @inventory_item.save

      @params['keyword'] = 'somen'
      searched_items = InventoryItem.search(@params)
      expect( searched_items['inventory_items'].first['item']['serial_number'] ).to eq 'Serial'
    end
  end  

  describe ".get_details" do
    before(:each) do
      @inventory_item = FactoryGirl.create :inventory_item
    end

    it "returns details of InventoryItem" do
      details = @inventory_item.get_details
      expect(details['inventory_item']['serial_number']).to eq @inventory_item.serial_number
    end
  end 

  describe ".warehouse_locations" do
    before(:each) do
      @inventory_item = FactoryGirl.create :inventory_item
      @warehouse_location = FactoryGirl.create :warehouse_location
      @item_location = FactoryGirl.create :item_location
      @item_location.quantity = @inventory_item.quantity
      @item_location.save
      @inventory_item.item_locations << @item_location
      @warehouse_location.item_locations << @item_location
    end

    it "returns true if withdrawal was sucessful" do
      locations = @inventory_item.warehouse_locations
      expect( locations.count ).to eq 1
      expect( locations.first['location'] ).to eq @warehouse_location.name
    end
  end

  describe ".withdraw" do
    before(:each) do
      @inventory_item = FactoryGirl.create :inventory_item
    end

    context "withdraws whole quantity of InventoryItem with location successfuly" do
      before(:each) do
        @warehouse_location = FactoryGirl.create :warehouse_location
        @item_location = FactoryGirl.create :item_location
        @item_location.quantity = @inventory_item.quantity
        @item_location.save
        @inventory_item.item_locations << @item_location
        @warehouse_location.item_locations << @item_location
        @supplier = FactoryGirl.create :supplier
        @withdraw = @inventory_item.withdraw( Time.now, Time.now + 10.days, @supplier.id, 'John Doe', 'This is just a test', @inventory_item.quantity )
      end

      it "returns true if withdrawal was sucessful" do
        expect( @withdraw ).to eq true
      end

      it "changes InventoryItem status to Out of Stock" do
        expect( @inventory_item.status ).to eq InventoryItem::OUT_OF_STOCK
      end

      it "records the WarehouseTransaction" do
        last_transaction = WarehouseTransaction.last
        expect( last_transaction.quantity ).to eq @item_location.quantity
      end

      it "deletes ItemLocation associated with InventoryItem" do
        item_location = ItemLocation.find_by_id( @item_location.id )
        expect( @warehouse_location.item_locations.count ).to eq 0
      end
    end

    context "withdraws partial quantity of InventoryItem from one location successfuly" do
      before(:each) do
        @warehouse_location = FactoryGirl.create :warehouse_location
        @item_location = FactoryGirl.create :item_location
        @item_location.quantity = @inventory_item.quantity
        @item_location.save
        @inventory_item.item_locations << @item_location
        @warehouse_location.item_locations << @item_location
        @supplier = FactoryGirl.create :supplier
        @withdraw = @inventory_item.withdraw( Time.now, Time.now + 10.days, @supplier.id, 'John Doe', 'This is just a test', 1 )
      end

      it "returns true if withdrawal was sucessful" do
        expect( @withdraw ).to eq true
      end

      it "changes InventoryItem status to Out of Stock" do
        expect( @inventory_item.status ).to eq InventoryItem::IN_STOCK
      end

      it "records the WarehouseTransaction" do
        last_transaction = WarehouseTransaction.last
        expect( last_transaction.quantity ).to eq 1
      end

    end

    context "withdraws partial quantity of InventoryItem from multiple locations successfuly" do
      before(:each) do
        @warehouse_location = FactoryGirl.create :warehouse_location
        @item_location = FactoryGirl.create :item_location
        @item_location.quantity = @inventory_item.quantity
        @item_location.save

        @warehouse_location2 = FactoryGirl.create :warehouse_location
        @item_location2 = FactoryGirl.create :item_location
        @item_location2.quantity = @inventory_item.quantity
        @item_location2.save

        @inventory_item.quantity = @inventory_item.quantity.to_i * 2
        @inventory_item.save

        @inventory_item.item_locations << @item_location
        @inventory_item.item_locations << @item_location2
        @warehouse_location.item_locations << @item_location
        @warehouse_location2.item_locations << @item_location2
        @supplier = FactoryGirl.create :supplier
        @withdraw = @inventory_item.withdraw( Time.now, Time.now + 10.days, @supplier.id, 'John Doe', 'This is just a test', 101 )
      end

      it "returns true if withdrawal was sucessful" do
        expect( @withdraw ).to eq true
      end

      it "changes InventoryItem status to Out of Stock" do
        expect( @inventory_item.status ).to eq InventoryItem::IN_STOCK
      end

      it "records the WarehouseTransaction" do
        last_transaction = WarehouseTransaction.last
        expect( last_transaction.quantity ).to eq 1
        expect( WarehouseTransaction.all.count ).to eq 2
      end
    end
  end

  describe ".recent" do
    before(:each) do
      @inventory_item1 = FactoryGirl.create :inventory_item
      @inventory_item2 = FactoryGirl.create :inventory_item
      @inventory_item3 = FactoryGirl.create :inventory_item
      @inventory_item4 = FactoryGirl.create :inventory_item
    end

    it "returns the most updated records" do
      expect(InventoryItem.recent).to match_array([@inventory_item3, @inventory_item2, @inventory_item4, @inventory_item1])
    end
  end  
end