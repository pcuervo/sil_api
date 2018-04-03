require 'spec_helper'

describe WarehouseLocation, type: :model do
  before { @warehouse_location = FactoryGirl.build(:warehouse_location) }


  it { should respond_to(:name) }
  it { should respond_to(:units) }
  it { should respond_to(:status) }

  it { should belong_to(:warehouse_rack) }
  it { should have_many(:item_locations) }
  it { should validate_uniqueness_of :name }
  it { should validate_presence_of :name }

  describe ".locate" do
    before(:each) do
      @inventory_item = FactoryGirl.create :inventory_item
      @warehouse_location = FactoryGirl.create :warehouse_location
    end

    context "locates a unit item successfully" do
      it "return a hash containing the information of the item location" do
        unit_item = FactoryGirl.create :unit_item
        unit_item.actable_id = @inventory_item.id
        item_location = ItemLocation.find( @warehouse_location.locate( unit_item.actable_id, 5, 5 ) )
        warehouse_transaction = WarehouseTransaction.last
        expect(item_location[:units]).to eq 5 
        expect(item_location[:units]).to eq warehouse_transaction.units
      end
    end

    context "locates all parts of bundle item successfully into one location" do
      it "returns a hash containing the information of the item location" do
        bundle_item = FactoryGirl.create :bundle_item
        bundle_item.actable_id = @inventory_item.id
        part1 = FactoryGirl.create :bundle_item_part
        part2 = FactoryGirl.create :bundle_item_part
        bundle_item.bundle_item_parts << part1
        bundle_item.bundle_item_parts << part2
        
        item_location = ItemLocation.find( @warehouse_location.locate( bundle_item.actable_id, bundle_item.bundle_item_parts.count, bundle_item.bundle_item_parts.count ) )
        expect(item_location[:units]).to eq bundle_item.bundle_item_parts.count
        expect(item_location.inventory_item.name).to eq @inventory_item.name
      end
    end

    context "locates all pieces of bulk item successfully into one location" do
      it "return a hash containing the information of the item location" do
        bulk_item = FactoryGirl.create :bulk_item
        bulk_item.actable_id = @inventory_item.id
        item_location = ItemLocation.find( @warehouse_location.locate( bulk_item.actable_id, bulk_item.quantity, bulk_item.quantity ) )
        expect(item_location[:units]).to eq bulk_item.quantity
        expect(item_location.inventory_item.name).to eq @inventory_item.name
      end
    end

    context "locates all parts of bundle item successfully into multiple locations" do
      it "return a hash containing the information of the item location" do
        # add parts to bundle item
        bundle_item = FactoryGirl.create :bundle_item
        bundle_item.actable_id = @inventory_item.id
        part1 = FactoryGirl.create :bundle_item_part
        part2 = FactoryGirl.create :bundle_item_part
        bundle_item.bundle_item_parts << part1
        bundle_item.bundle_item_parts << part2
        # create multiple locations
        wh_location1 = FactoryGirl.create :warehouse_location
        wh_location2 = FactoryGirl.create :warehouse_location
        # locate item
        item_location1 = ItemLocation.find( wh_location1.locate( bundle_item.actable_id, 1, 1, part1.id ) )
        item_location2 = ItemLocation.find( wh_location2.locate( bundle_item.actable_id, 1, 1, part2.id ) )
        # tests
        expect(item_location1[:units]).to eq 1
        expect(item_location2[:units]).to eq 1
        expect(item_location1.inventory_item.name).to eq @inventory_item.name
        expect(item_location2.inventory_item.name).to eq @inventory_item.name
        expect(item_location1[:part_id]).to eq part1.id
        expect(item_location2[:part_id]).to eq part2.id
        expect( item_location1[:quantity].to_i + item_location2[:quantity].to_i ).to eq bundle_item.bundle_item_parts.count
      end
    end

    context "locates all pieces of bulk item successfully into multiple locations" do
      it "return a hash containing the information of the item location" do
        bulk_item = FactoryGirl.create :bulk_item
        bulk_item.actable_id = @inventory_item.id
        # create multiple locations
        wh_location1 = FactoryGirl.create :warehouse_location
        wh_location2 = FactoryGirl.create :warehouse_location
        # locate itemss
        item_location1 = ItemLocation.find( wh_location1.locate( bulk_item.actable_id, 70, 70 ) )
        item_location2 = ItemLocation.find( wh_location2.locate( bulk_item.actable_id, 30, 30 ) )
        # tests
        expect(item_location1[:units]).to eq 70
        expect(item_location2[:units]).to eq 30
        expect(item_location1.inventory_item.name).to eq @inventory_item.name
        expect(item_location2.inventory_item.name).to eq @inventory_item.name
        expect( item_location1[:quantity].to_i + item_location2[:quantity].to_i ).to eq 100
      end
    end

    context "relocates existing BulkItems in existing location combining them" do
      it "return a hash containing the information of the item location" do
        bulk_item = FactoryGirl.create :bulk_item
        bulk_item.actable_id = @inventory_item.id
        # create multiple locations
        wh_location1 = FactoryGirl.create :warehouse_location
        wh_location2 = FactoryGirl.create :warehouse_location
        # locate itemss
        item_location1 = ItemLocation.find( wh_location1.locate( bulk_item.actable_id, 70, 70 ) )
        wh_location1.locate( bulk_item.actable_id, 30, 30 )

        new_item_location = ItemLocation.find( item_location1.id )
        expect(new_item_location.units).to eq 70

      end
    end
  end

  describe ".relocate" do
    before(:each) do
      @item_location = FactoryGirl.create :item_location
      @new_location = FactoryGirl.create :warehouse_location
    end

    context "relocates a unit item successfully" do
      it "return a hash containing the information of the new item location" do
        item_location = ItemLocation.find( @new_location.relocate( @item_location.id, @item_location.units, 1 ) )
        warehouse_transaction = WarehouseTransaction.last
        expect(item_location[:units]).to eq @item_location.units 
        expect(item_location[:units]).to eq warehouse_transaction.units
      end
    end
  end

  describe ".remove_item" do
    before(:each) do
      @item_location = FactoryGirl.create :item_location
      @location = @item_location.warehouse_location
    end

    context "remove an UnitItem from current location" do
      it "return a true if UnitItem was removed successfully" do
        was_removed = @location.remove_item( @item_location.inventory_item )
        #warehouse_transaction = WarehouseTransaction.last
        expect( was_removed ).to eq true
        #expect(item_location[:units]).to eq warehouse_transaction.units
      end
    end
  end

  describe ".remove_quantity" do
    before(:each) do
      @item_location = FactoryGirl.create :item_location
      @item_location.quantity = 100
      @item_location.save
      @location = @item_location.warehouse_location
    end

    context "remove a quantity from current location" do
      it "return new quantity if quantity was removed successfully" do
        new_quantity = @location.remove_quantity( @item_location.inventory_item_id, 50, 5 )
        expect( new_quantity ).to eq 50
      end

      it "saves WarehouseTransaction" do
        new_quantity = @location.remove_quantity( @item_location.inventory_item_id, 50, 5 )
        warehouse_transaction = WarehouseTransaction.last
        expect( warehouse_transaction.quantity ).to eq 50
        item_location = ItemLocation.find( @item_location.id )
        expect( item_location.present? ).to eq true
      end
    end

    context "remove full quantity from current location" do
      it "return new quantity if quantity was removed successfully" do
        new_quantity = @location.remove_quantity( @item_location.inventory_item_id, 100, 5 )
        expect( new_quantity ).to eq 0
      end

      it "saves WarehouseTransaction" do
        new_quantity = @location.remove_quantity( @item_location.inventory_item_id, 100, 5 )
        warehouse_transaction = WarehouseTransaction.last
        expect( warehouse_transaction.quantity ).to eq 100
        item_location = ItemLocation.find_by_id( @item_location.id )
        expect( item_location.present? ).to eq false
      end
    end

    context "cannot remove quantity because there are not enough stocks" do
      it "return an error code when not enough stocks" do
        new_quantity = @location.remove_quantity( @item_location.inventory_item_id, 200, 5 )
        expect( new_quantity ).to eq WarehouseLocation::NOT_ENOUGH_STOCKS
      end
    end
  end

  describe ".empty" do
    before(:each) do
      @item_location = FactoryGirl.create :item_location
      @location = @item_location.warehouse_location
      @inventory_item = @item_location.inventory_item
      # Add another item
      item = FactoryGirl.create :inventory_item
      @location.locate( item.id, 1, 1 )
    end

    context "emtpy WarehouseLocation and register transaction" do
      it "returns true if WarehouseLocation was properly emptied" do
        was_emptied = @location.empty()
        last_transaction = WarehouseTransaction.last

        expect( was_emptied ).to eq true
        expect(last_transaction.concept).to eq WarehouseTransaction::EMPTIED
        expect(@location.item_locations.count).to eq 0
      end
    end
  end

  describe ".mark_as_full" do
    before(:each) do
      @item_location = FactoryGirl.create :item_location
      @location = @item_location.warehouse_location
      @inventory_item = @item_location.inventory_item
      # Add another item
      item = FactoryGirl.create :inventory_item
      @location.locate( item.id, 1, 1 )
    end

    it "returns true if WarehouseLocation was marked as full" do
      @location.mark_as_full

      expect( @location.status ).to eq WarehouseLocation::NO_SPACE
    end
  end
end