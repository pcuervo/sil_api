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
      post :locate_item, { inventory_item_id: @unit_item.id, warehouse_location_id: @warehouse_location.id, quantity: 1, units: 5 }
    end

    context "when item is successfully located" do
      it "returns a JSON of the new ItemLocation" do
        item_location_response = json_response[:item_location]
        expect(item_location_response[:units]).to eq(5)
      end

      it { should respond_with 201 }
    end
  end

  describe "POST #locate_bundle" do 
    before(:each) do
      user = FactoryGirl.create :user
      inventory_item = FactoryGirl.create :inventory_item
      @bundle_item = FactoryGirl.create :bundle_item
      @bundle_item.actable_id = inventory_item.id
      @part1 = FactoryGirl.create :bundle_item_part
      @part2 = FactoryGirl.create :bundle_item_part
      @bundle_item.bundle_item_parts << @part1
      @bundle_item.bundle_item_parts << @part2

      location1 = FactoryGirl.create :warehouse_location
      location2 = FactoryGirl.create :warehouse_location
      @locations = [ location1, location2 ]

      @part_locations = []
      @bundle_item.bundle_item_parts.each_with_index do |part, i|
        @part_locations.push( { :partId => part.id, :units => 3, :locationId => @locations[i].id } )
      end

      api_authorization_header user.auth_token
      post :locate_bundle, { inventory_item_id: @bundle_item.id, part_locations: @part_locations }
    end

    context "when item is successfully located" do
      it "returns a JSON of the new ItemLocation" do
        item_locations_response = json_response[:item_locations]

        expect(item_locations_response[0][:part_id]).to eq(@part1.id)
        expect(item_locations_response[1][:part_id]).to eq(@part2.id)
      end

      it { should respond_with 201 }
    end
  end

  describe "PUT/PATCH #update" do

    context "when is successfully updated" do
      before(:each) do
        user = FactoryGirl.create :user
        api_authorization_header user.auth_token
        @warehouse_location = FactoryGirl.create :warehouse_location
        post :update, { id: @warehouse_location.id, name: "NewNameBro", units: 50 }, format: :json
      end

      it "renders the json representation for the updated WarehouseLocation" do
        warehouse_location_response = json_response[:warehouse_location]
        expect(warehouse_location_response[:name]).to eql "NewNameBro"
      end

      it { should respond_with 200 }
    end

    context "when is not updated" do
      before(:each) do
        user = FactoryGirl.create :user
        api_authorization_header user.auth_token
        @warehouse_location = FactoryGirl.create :warehouse_location
        post :update, { id: @warehouse_location.id, name: "NewNameBro", units: -50 }, format: :json
      end

      it "renders an errors json" do
        warehouse_location_response = json_response
        expect(warehouse_location_response).to have_key(:errors)
      end

      it "renders the json errors when the email is invalid" do
        warehouse_location_response = json_response
        puts json_response.to_yaml
        expect(warehouse_location_response[:errors][:units]).to include "must be greater than 0"
      end

      it { should respond_with 422 }
    end
  end

end
