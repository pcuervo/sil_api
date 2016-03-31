require 'spec_helper'

RSpec.describe WarehouseRack, type: :model do
  let(:warehouse_rack) { FactoryGirl.create :warehouse_rack }
  subject { warehouse_rack }

  it { should respond_to(:name) }
  it { should respond_to(:row) }
  it { should respond_to(:column) }

  it { should validate_uniqueness_of :name }

  it { should have_many(:warehouse_locations) }

  describe ".available_locations" do
    before(:each) do
      @warehouse_rack = FactoryGirl.create :warehouse_rack
      5.times do |i|

        location = FactoryGirl.create :warehouse_location
        if i == 1
          location.status = 3
        end
        @warehouse_rack.warehouse_locations << location

      end
    end

    context "successfully retrieve available locations" do
      it "return a hash containing available locations" do
        locations_response = @warehouse_rack.available_locations
        expect( locations_response['available_locations'].count ).to eq 4
      end
    end
  end

  describe ".add_initial_locations" do
    before(:each) do
      @warehouse_rack = FactoryGirl.create :warehouse_rack
      @warehouse_rack.add_initial_locations 10
    end

    it "matches the number of locations added" do
      num_locations = @warehouse_rack.row * @warehouse_rack.column
      expect( @warehouse_rack.warehouse_locations.count ).to eq num_locations
    end
  end

  describe ".is_empty?" do
    before(:each) do
      @warehouse_rack = FactoryGirl.create :warehouse_rack
      @warehouse_rack.add_initial_locations 10
      @location = @warehouse_rack.warehouse_locations.first
      @inventory_item = FactoryGirl.create :inventory_item
      @item_location = FactoryGirl.create :item_location
    end

    it "return true if WarehouseRack is empty" do
      expect( @warehouse_rack.is_empty? ).to eq true
    end

    it "return false if WarehouseRack is not empty" do
      @inventory_item.item_locations << @item_location
      @location.item_locations << @item_location
      expect( @warehouse_rack.is_empty? ).to eq false
    end
  end

end
