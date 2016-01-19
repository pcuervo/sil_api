require 'spec_helper'

RSpec.describe Api::V1::WarehouseLocationsController, type: :controller do
  describe "GET #show" do 
    before(:each) do
      @warehouse_location = FactoryGirl.create :warehouse_location
      get :show, id: @warehouse_location.id
    end

    it "returns the information about a warehouse_location in JSON format" do
      warehouse_location_response = json_response[:warehouse_location]
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

  describe "POST #locate_item" do 
    before(:each) do
      user = FactoryGirl.create :user
      inventory_item = FactoryGirl.create :inventory_item
      @unit_item = FactoryGirl.create :unit_item
      @unit_item.actable_id = inventory_item.id
      @warehouse_location = FactoryGirl.create :warehouse_location

      api_authorization_header user.auth_token
      post :locate_item, { inventory_item_id: @unit_item.actable_id, warehouse_location_id: @warehouse_location.id, quantity: 1, units: 5 }
    end

    context "when item is successfully located" do
      it "returns a JSON of the new ItemLocation" do
        item_location_response = json_response[:item_location]
        expect(item_location_response[:units]).to eq(5)
      end

      it { should respond_with 201 }
    end

    
  end

end
