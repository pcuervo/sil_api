require 'spec_helper'

describe WarehouseLocation, type: :model do
  before { @warehouse_location = FactoryGirl.build(:warehouse_location) }

  it { should respond_to(:name) }
  it { should respond_to(:status) }

  it { should belong_to(:warehouse_rack) }
  it { should have_many(:item_locations) }
  it { should validate_uniqueness_of :name }
  it { should validate_presence_of :name }

  describe '.locate' do
    before(:each) do
      @inventory_item = FactoryGirl.create :inventory_item
      @warehouse_location = FactoryGirl.create :warehouse_location
    end

    context 'locates an InventoryItem successfully' do
      it 'returns the ID of new ItemLocation and records a new WarehouseTransaction' do
        item_location_id = @warehouse_location.locate(@inventory_item.id, @inventory_item.quantity)
        item_location = ItemLocation.find(item_location_id)
        warehouse_transaction = WarehouseTransaction.last

        expect(item_location.quantity).to eq @inventory_item.quantity
        expect(item_location[:quantity]).to eq warehouse_transaction.quantity
      end
    end

    context 'locates all pieces of bulk item successfully into multiple locations' do
      it 'return a hash containing the information of the item location' do
        wh_location1 = FactoryGirl.create :warehouse_location
        wh_location2 = FactoryGirl.create :warehouse_location
        # locate items
        item_location1 = ItemLocation.find(wh_location1.locate(@inventory_item.id, 70))
        item_location2 = ItemLocation.find(wh_location2.locate(@inventory_item.id, 30))

        # tests
        expect(item_location1.quantity).to eq 70
        expect(item_location2.quantity).to eq 30
        expect(item_location1.inventory_item.name).to eq @inventory_item.name
        expect(item_location2.inventory_item.name).to eq @inventory_item.name
        expect(item_location1.quantity.to_i + item_location2.quantity.to_i).to eq 100
      end
    end
  end

  describe '.remove_item' do
    before(:each) do
      @item_location = FactoryGirl.create :item_location
      @location = @item_location.warehouse_location
    end

    context 'remove an UnitItem from current location' do
      it 'return a true if UnitItem was removed successfully' do
        was_removed = @location.remove_item(@item_location.inventory_item)

        expect(was_removed).to eq true
      end
    end
  end

  describe '.remove_quantity' do
    before(:each) do
      @item_location = FactoryGirl.create :item_location
      @item_location.quantity = 100
      @item_location.save
      @location = @item_location.warehouse_location
    end

    context 'remove a quantity from current location' do
      it 'return new quantity if quantity was removed successfully' do
        new_quantity = @location.remove_quantity(@item_location.inventory_item_id, 50, 5)
        expect(new_quantity).to eq 50
      end

      it 'saves WarehouseTransaction' do
        @location.remove_quantity(@item_location.inventory_item_id, 50, 5)
        warehouse_transaction = WarehouseTransaction.last
        expect(warehouse_transaction.quantity).to eq 50
        item_location = ItemLocation.find(@item_location.id)
        expect(item_location.present?).to eq true
      end
    end

    context 'remove full quantity from current location' do
      it 'return new quantity if quantity was removed successfully' do
        new_quantity = @location.remove_quantity(@item_location.inventory_item_id, 100, 5)
        expect(new_quantity).to eq 0
      end

      it 'saves WarehouseTransaction' do
        @location.remove_quantity(@item_location.inventory_item_id, 100, 5)
        warehouse_transaction = WarehouseTransaction.last
        expect(warehouse_transaction.quantity).to eq 100
        item_location = ItemLocation.find_by_id(@item_location.id)
        expect(item_location.present?).to eq false
      end
    end

    context 'cannot remove quantity because there are not enough stocks' do
      it 'return an error code when not enough stocks' do
        new_quantity = @location.remove_quantity(@item_location.inventory_item_id, 200, 5)
        expect(new_quantity).to eq WarehouseLocation::NOT_ENOUGH_STOCKS
      end
    end
  end

  describe '.empty' do
    before(:each) do
      @item_location = FactoryGirl.create :item_location
      @location = @item_location.warehouse_location
      @inventory_item = @item_location.inventory_item
      # Add another item
      item = FactoryGirl.create :inventory_item
      @location.locate(item.id, 1)
    end

    context 'emtpy WarehouseLocation and register transaction' do
      it 'returns true if WarehouseLocation was properly emptied' do
        was_emptied = @location.empty
        last_transaction = WarehouseTransaction.last

        expect(was_emptied).to eq true
        expect(last_transaction.concept).to eq WarehouseTransaction::EMPTIED
        expect(@location.item_locations.count).to eq 0
      end
    end
  end

  describe '.mark_as_full' do
    before(:each) do
      @item_location = FactoryGirl.create :item_location
      @location = @item_location.warehouse_location
      @inventory_item = @item_location.inventory_item
      # Add another item
      item = FactoryGirl.create :inventory_item
      @location.locate(item.id, 1)
    end

    it 'returns true if WarehouseLocation was marked as full' do
      @location.mark_as_full

      expect(@location.status).to eq WarehouseLocation::NO_SPACE
    end
  end
end
