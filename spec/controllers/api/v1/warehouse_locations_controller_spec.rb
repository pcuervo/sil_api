require 'spec_helper'

RSpec.describe Api::V1::WarehouseLocationsController, type: :controller do
  describe "GET #show" do 
    before(:each) do
      @warehouse_location = FactoryGirl.create :warehouse_location
      get :show, id: @warehouse_location.id
    end

    it "returns the information about a warehouse_location in JSON format" do
      warehouse_location_response = json_response[:warehouse_location]
      puts warehouse_location_response.to_yaml
      expect(warehouse_location_response[:name]).to eql @warehouse_location.name
      expect(warehouse_location_response[:units]).to eql @warehouse_location.units
      expect(warehouse_location_response[:status]).to eql @warehouse_location.status
    end

    it { should respond_with 200 }
  end

  describe "GET #index" do 
    before(:each) do
      3.times { FactoryGirl.create :warehouse_location }
      get :index
    end

    it "returns 5 unit items from the database" do
      bulk_items_response = json_response
      expect(bulk_items_response[:warehouse_locations].size).to eq(3)
    end

    it { should respond_with 200 }
  end
end
