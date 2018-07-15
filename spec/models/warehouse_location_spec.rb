require 'spec_helper'

describe WarehouseLocation, type: :model do
  let(:warehouse_location) { FactoryGirl.create :warehouse_location }

  it { should respond_to(:name) }
  it { should respond_to(:status) }

  it { should belong_to(:warehouse_rack) }
  it { should have_many(:item_locations) }
  it { should validate_uniqueness_of :name }
  it { should validate_presence_of :name }

  describe '.locate_in_new' do
    let(:inventory_item) { FactoryGirl.create :inventory_item }
    
    context 'when InventoryItem is fully located in new WarehouseLocation' do
      it 'returns the ID of new ItemLocation and records a new WarehouseTransaction' do
        item_location_id = warehouse_location.locate_in_new(inventory_item, inventory_item.quantity)
        item_location = ItemLocation.find(item_location_id)
        warehouse_transaction = WarehouseTransaction.last
        warehouse_location.reload

        expect(item_location.quantity).to eq inventory_item.quantity
        expect(item_location[:quantity]).to eq warehouse_transaction.quantity
        expect(warehouse_location.status).to eq WarehouseLocation::PARTIAL_SPACE
      end
    end

    context 'when InventoryItem is partially located in new WarehouseLocation' do
      it 'returns the ID of new ItemLocation and records a new WarehouseTransaction' do
        item_location_id = warehouse_location.locate_in_new(inventory_item, inventory_item.quantity-10)
        item_location = ItemLocation.find(item_location_id)
        warehouse_transaction = WarehouseTransaction.last
        warehouse_location.reload

        expect(item_location.quantity).to be < inventory_item.quantity
        expect(item_location[:quantity]).to eq inventory_item.quantity-10
        expect(warehouse_location.status).to eq WarehouseLocation::PARTIAL_SPACE
      end
    end

    context 'when InventoryItem is not located' do
      it "raises an error when quantity to locate is greater than InventoryItem's quantity" do
        invalid_quantity = inventory_item.quantity + 100

        expect{warehouse_location.locate_in_new(inventory_item, invalid_quantity)}.to raise_error(SilExceptions::InvalidQuantityToLocate)
      end
    end
  end
  
  describe '.locate_in_existing' do
    let(:inventory_item) { FactoryGirl.create(:inventory_item, quantity: 500) }
    before { warehouse_location.locate_in_new(inventory_item, 200) }
    let(:item_location) { ItemLocation.last }
    
    context 'locates an InventoryItem successfully in an existing WarehouseLocation' do
      it 'returns the ID of new ItemLocation and records a new WarehouseTransaction' do
        warehouse_location.locate_in_existing(item_location, 300)
        warehouse_transactions = WarehouseTransaction.where(
          'inventory_item_id = ? AND warehouse_location_id = ?', 
          inventory_item.id, 
          warehouse_location.id
        )

        expect(item_location.quantity).to eq 500
        expect(warehouse_transactions.count).to eq 2
      end
    end

    context 'when InventoryItem is not located' do
      it "raises an error when the sum of the quantity to locate and the quantity already located is greater than InventoryItem's quantity" do
        expect{ warehouse_location.locate_in_existing(item_location, 301) }.to raise_error(SilExceptions::InvalidQuantityToLocate)
      end
    end
  end

  describe '.in_location?' do
    let(:inventory_item) { FactoryGirl.create(:inventory_item, quantity: 500) }
    
    context 'when InventoryItem is not located in WarehouseLocation' do
      it 'returns false' do
        expect(warehouse_location.in_location?(inventory_item.id)).to eq false
      end
    end

    context 'when InventoryItem is located in WarehouseLocation' do
      before { warehouse_location.locate_in_new(inventory_item, 200) }

      it 'returns true' do
        expect(warehouse_location.in_location?(inventory_item.id)).to eq true
      end
    end
  end

  describe '.locate' do
    let(:inventory_item) { FactoryGirl.create(:inventory_item, quantity: 500) }
    
    context 'locates an InventoryItem successfully in a new WarehouseLocation' do
      it 'returns the ID of new ItemLocation and records a new WarehouseTransaction' do
        item_location_id = warehouse_location.locate(inventory_item, inventory_item.quantity)
        item_location = ItemLocation.find(item_location_id)
        warehouse_transaction = WarehouseTransaction.last

        expect(item_location.quantity).to eq inventory_item.quantity
        expect(item_location.quantity).to eq warehouse_transaction.quantity
        expect(warehouse_location.status).to eq WarehouseLocation::PARTIAL_SPACE
      end
    end

    context 'locates an InventoryItem successfully in an existing WarehouseLocation' do
      before { warehouse_location.locate_in_new(inventory_item, 200) }
      let(:item_location) { ItemLocation.last }

      it 'returns ItemLocation and records a new WarehouseTransaction' do
        warehouse_location.locate(inventory_item, 300)
        warehouse_transaction = WarehouseTransaction.last

        item_location.reload
        expect(item_location.quantity).to eq 500
        expect(warehouse_location.item_locations.count).to eq 1
        expect(warehouse_transaction.quantity).to eq 300
      end
    end

    context 'locates InventoryItem in two WarehouseLocations successfully' do
      let(:another_warehouse_location) { FactoryGirl.create :warehouse_location }

      it 'records each WarehouseTransaction' do
        warehouse_location.locate(inventory_item, 200)
        another_warehouse_location.locate(inventory_item, 300)

        warehouse_transactions = WarehouseTransaction.where('inventory_item_id = ?', inventory_item.id)

        expect(warehouse_transactions.count).to eq 2
        expect(warehouse_transactions.first.quantity).to eq 200
        expect(warehouse_transactions.last.quantity).to eq 300
      end
    end

    context 'cannot locate InventoryItem' do
      let(:another_warehouse_location) { FactoryGirl.create :warehouse_location }

      it 'raises an error when trying to locate a zero or less pieces' do
        expect{ warehouse_location.locate(inventory_item, 0) }.to raise_error(SilExceptions::InvalidQuantityToLocate)
      end
      
      it 'raises an error when trying to locate more pieces than possible' do
        expect{ warehouse_location.locate(inventory_item, 1000) }.to raise_error(SilExceptions::InvalidQuantityToLocate)
      end

      it 'raises an error when trying to locate in multiple locations more pieces than possible' do
        warehouse_location.locate(inventory_item, 200)
        another_warehouse_location.locate(inventory_item, 500)

        expect{ another_warehouse_location.locate(inventory_item, 500) }.to raise_error(SilExceptions::InvalidQuantityToLocate)
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
      inventory_item = @item_location.inventory_item
      # Add another item
      item = FactoryGirl.create :inventory_item
      @location.locate(item, 1)
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
      inventory_item = @item_location.inventory_item
      # Add another item
      item = FactoryGirl.create :inventory_item
      @location.locate(item, 1)
    end

    it 'returns true if WarehouseLocation was marked as full' do
      @location.mark_as_full

      expect(@location.status).to eq WarehouseLocation::NO_SPACE
    end
  end
end
