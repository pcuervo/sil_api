require 'spec_helper'

RSpec.describe WarehouseRack, type: :model do
  let(:warehouse_rack) { FactoryBot.create :warehouse_rack }
  subject { warehouse_rack }

  it { should respond_to(:name) }
  it { should respond_to(:row) }
  it { should respond_to(:column) }

  it { should validate_uniqueness_of :name }

  it { should have_many(:warehouse_locations) }

  describe '.add_initial_locations' do
    before(:each) do
      @warehouse_rack = FactoryBot.create :warehouse_rack
      @warehouse_rack.add_initial_locations 10
    end

    it 'matches the number of locations added' do
      num_locations = @warehouse_rack.row * @warehouse_rack.column
      expect(@warehouse_rack.warehouse_locations.count).to eq num_locations
    end
  end

  describe '.empty?' do
    before(:each) do
      @warehouse_rack = FactoryBot.create :warehouse_rack
      @warehouse_rack.add_initial_locations 10
      @location = @warehouse_rack.warehouse_locations.first
      @inventory_item = FactoryBot.create :inventory_item
      @item_location = FactoryBot.create :item_location
    end

    it 'return true if WarehouseRack is empty' do
      expect(@warehouse_rack.empty?).to eq true
    end

    it 'return false if WarehouseRack is not empty' do
      @inventory_item.item_locations << @item_location
      @location.item_locations << @item_location
      expect(@warehouse_rack.empty?).to eq false
    end
  end

  describe '.empty' do
    before(:each) do
      @item_location = FactoryBot.create :item_location
      @location = @item_location.warehouse_location
      @inventory_item = @item_location.inventory_item
      # Add another item
      item = FactoryBot.create :inventory_item
      @location.locate(item, 1)
      @rack = FactoryBot.create :warehouse_rack
      @rack.warehouse_locations << @location
    end

    it 'returns true if WarehouseRack was properly emptied' do
      was_emptied = @rack.empty
      last_transaction = WarehouseTransaction.last

      expect(was_emptied).to eq true
      expect(last_transaction.concept).to eq WarehouseTransaction::EMPTIED
      expect(@rack.empty?).to eq true
    end
  end
end
