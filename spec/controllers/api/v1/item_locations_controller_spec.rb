require 'spec_helper'

RSpec.describe Api::V1::ItemLocationsController, type: :controller do
  describe "GET #show" do
    before(:each) do
      @item_location = FactoryBot.create :item_location
      @inventory_item = @item_location.inventory_item
      @location = @item_location.warehouse_location
      get :show, params: { id: @item_location.id }
    end

    it "returns the information about an inventory location on a hash" do
      item_location_response = json_response[:item_location]
      expect(item_location_response[:quantity]).to eql @item_location.quantity
      expect(item_location_response[:inventory_item][:id]).to eql @inventory_item.id
      expect(item_location_response[:warehouse_location][:id]).to eql @location.id
    end

    it { should respond_with 200 }
  end

  describe "GET #index" do
    before(:each) do
      5.times{ FactoryBot.create :item_location }
      get :index
    end

    it "returns 5 item locations from the database" do
      item_locations_response = json_response
      expect(item_locations_response[:item_locations].size).to eq(5)
    end

    it { should respond_with 200 }
  end

  describe "POST #create" do
    context "when is succesfully created" do
      before(:each) do
        user = FactoryBot.create :user
        @inventory_item = FactoryBot.create :inventory_item
        @warehouse_location = FactoryBot.create :warehouse_location
        @item_location_attributes = FactoryBot.attributes_for :item_location

        api_authorization_header user.auth_token
        post :create, params: { inventory_item_id: @inventory_item.id, warehouse_location_id: @warehouse_location.id, quantity: 1 }
      end

      it "renders the json representation for the item location just created" do
        item_location_response = json_response[:item_location]
        expect(item_location_response[:quantity]).to eql 1       
        expect(item_location_response[:inventory_item][:id]).to eql @inventory_item.id
        expect(item_location_response[:warehouse_location][:id]).to eql @warehouse_location.id
      end

      it { should respond_with 201 }
    end

    context "when a unit item is succesfully added to a location" do
      before(:each) do
        user = FactoryBot.create :user
        inventory_item = FactoryBot.create :inventory_item
        @warehouse_location = FactoryBot.create :warehouse_location
        @item_location_attributes = FactoryBot.attributes_for :item_location

        api_authorization_header user.auth_token
        post :create, params: { inventory_item_id: inventory_item.id, warehouse_location_id: @warehouse_location.id, quantity: 1 }
      end

      it "should render the json representation for the unit item and have quantity of 1" do
        item_location_response = json_response[:item_location]
        expect(item_location_response[:quantity]).to eql 1       
      end
    end

    context "when a bundle item is succesfully added to a single location" do
      before(:each) do
        user = FactoryBot.create :user
        inventory_item = FactoryBot.create :inventory_item
        @warehouse_location = FactoryBot.create :warehouse_location
        @item_location_attributes = FactoryBot.attributes_for :item_location

        api_authorization_header user.auth_token
        post :create, params: { inventory_item_id: inventory_item.id, warehouse_location_id: @warehouse_location.id, quantity: 1 }
      end

      it "should render the json representation for the unit item and have quantity of 1" do
        item_location_response = json_response[:item_location]
        expect(item_location_response[:quantity]).to eql 1       
      end
    end

    context "when is not created because inventory item is not present" do
      before(:each) do
        user = FactoryBot.create :user
        api_authorization_header user.auth_token
        post :create, params: { quantity: 1 }
      end

      it "renders an errors json" do
        inventory_item_response = json_response
        expect(inventory_item_response).to have_key(:errors)
      end

      it "renders the json errors on why the item location could not be created" do
        item_location_response = json_response
        expect(item_location_response[:errors]).to include "No se ha encontrado el artículo."
      end

      it { should respond_with 422 }
    end

    context "when is not created because location is not present" do
      before(:each) do
        user = FactoryBot.create :user
        inventory_item = FactoryBot.create :inventory_item
        api_authorization_header user.auth_token
        post :create, params: { quantity: 1, inventory_item_id: inventory_item.id }
      end

      it "renders an errors json" do
        inventory_item_response = json_response
        expect(inventory_item_response).to have_key(:errors)
      end

      it "renders the json errors on why the item location could not be created" do
        item_location_response = json_response
        expect(item_location_response[:errors]).to include "No se ha encontrado la ubicación."
      end

      it { should respond_with 422 }
    end

  end

end
