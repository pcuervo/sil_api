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

  describe "POST #create" do
    context "when rack is succesfully created" do
      before(:each) do
        user = FactoryGirl.create :user
        @rack_attributes = FactoryGirl.attributes_for :warehouse_rack

        api_authorization_header user.auth_token
        post :create, { user_id: user.id, warehouse_rack: @rack_attributes, units: 50  }
      end

      it "renders the WarehouseRack just created in JSON format" do
        rack_response = json_response[:warehouse_rack]
        expect(rack_response[:name]).to eql @rack_attributes[:name]
        expect(rack_response[:warehouse_locations].count).to eql ( @rack_attributes[:row] * @rack_attributes[:column] )
      end

      it { should respond_with 201 }
    end

    # context "when project is not created" do
    #   before(:each) do
    #     user = FactoryGirl.create :user
    #     pm = FactoryGirl.create :user
    #     pm.role = User::PROJECT_MANAGER
    #     ae = FactoryGirl.create :user
    #     ae.role = User::ACCOUNT_EXECUTIVE
    #     @invalid_project_attributes = { name: "Proyecto Inválido" }

    #     api_authorization_header user.auth_token
    #     post :create, { user_id: user.id, pm_id: pm.id, ae_id: ae.id, project: @invalid_project_attributes }
    #   end

    #   it "renders an errors json" do 
    #     project_response = json_response
    #     expect(project_response).to have_key(:errors)
    #   end

    #   it "renders the json errors when there is no client present" do
    #     project_response = json_response
    #     expect(project_response[:errors][:client]).to include "can't be blank"
    #   end

    #   it { should respond_with 422 }
    # end
  end

end
