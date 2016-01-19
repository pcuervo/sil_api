require 'spec_helper'

RSpec.describe Api::V1::WarehouseRacksController, type: :controller do
  describe "GET #show" do 
    before(:each) do
      @warehouse_rack = FactoryGirl.create :warehouse_rack
      get :show, id: @warehouse_rack.id
    end

    it "returns the information about a warehouse_rack in JSON format" do
      warehouse_rack_response = json_response[:warehouse_rack]
      expect(warehouse_rack_response[:name]).to eql @warehouse_rack.name
      expect(warehouse_rack_response[:row]).to eql @warehouse_rack.row
      expect(warehouse_rack_response[:column]).to eql @warehouse_rack.column
    end

    it { should respond_with 200 }
  end

  describe "GET #index" do 
    before(:each) do
      3.times { FactoryGirl.create :warehouse_rack }
      get :index
    end

    it "returns 5 unit items from the database" do
      bulk_items_response = json_response
      expect(bulk_items_response[:warehouse_racks].size).to eq(3)
    end

    it { should respond_with 200 }
  end

  describe "GET #get_available_locations" do
    before(:each) do
      warehouse_rack = FactoryGirl.create :warehouse_rack
      5.times do 
        location = FactoryGirl.create :warehouse_location
        warehouse_rack.warehouse_locations << location
      end

      get :get_available_locations, id: warehouse_rack.id
    end

    it "return 5 WarehouseLocations in JSON format" do
      locations_response = json_response
      expect(locations_response[:available_locations].size).to eq(5)
    end
  end
end
