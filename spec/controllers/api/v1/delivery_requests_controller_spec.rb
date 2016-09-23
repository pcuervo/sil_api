require 'spec_helper'

RSpec.describe Api::V1::DeliveryRequestsController, type: :controller do
  describe "GET #index" do
    before(:each) do
      user = FactoryGirl.create :user
      5.times { FactoryGirl.create :delivery_request }
      get :index
    end

    it "returns 5 records from the database" do
      delivery_request_response = json_response[:delivery_requests]
      expect(delivery_request_response.size).to eq( 5 )
    end

    it { should respond_with 200 }
  end

  describe "POST #create" do
    context "when is succesfully created" do
      before(:each) do
        user = FactoryGirl.create :user
        item = FactoryGirl.create :inventory_item
        @delivery_request_attributes = FactoryGirl.attributes_for :delivery_request

        inventory_items = []
        inventory_items.push( { :item_id => item.id, :quantity => 1 } )
        api_authorization_header user.auth_token
        post :create, { delivery_request: @delivery_request_attributes, inventory_items: inventory_items }
      end

      it "renders the json representation for the WithdrawRequest just created" do
        delivery_request_response = json_response[:delivery_request]
        expect( delivery_request_response[:address] ).to eql @delivery_request_attributes[:address]
        expect( delivery_request_response[:delivery_request_items].count ).to eql 1
      end

      it { should respond_with 201 }
    end
  end

  describe "POST #authorize_delivery" do
    context "when is succesfully authorized" do
      before(:each) do
        user = FactoryGirl.create :user
        @delivery_request = FactoryGirl.create :delivery_request
        @delivery_request_item = FactoryGirl.create :delivery_request_item
        @unit_item = FactoryGirl.create :unit_item
        @inventory_item = FactoryGirl.create :inventory_item
        @inventory_item.actable_type = 'UnitItem'
        @inventory_item.actable_id = @unit_item.id
        @inventory_item.save
        @delivery_request_item.inventory_item = @inventory_item
        @delivery_request_item.save
        @delivery_request.delivery_request_items << @delivery_request_item
        @delivery_request.update_items_status_to_pending
        @delivery_request.save

        supplier = FactoryGirl.create :supplier
        supplier.name = 'Litobel'
        supplier.save

        api_authorization_header user.auth_token
        post :authorize_delivery, { id: @delivery_request.id, delivery_user_id: -1, supplier_id: -1, additional_comments: 'adicionales', quantities: [] }
      end

      it "renders the json representation for the DeliveryRequest just created" do
        authorize_request_response = json_response
        expect( authorize_request_response ).to have_key(:success)
      end

      it { should respond_with 201 }
    end
  end

  describe "POST #reject_delivery" do
    context "when is succesfully rejected" do
      before(:each) do
        user = FactoryGirl.create :user
        @delivery_request = FactoryGirl.create :delivery_request
        @delivery_request_item = FactoryGirl.create :delivery_request_item
        @unit_item = FactoryGirl.create :unit_item
        @inventory_item = FactoryGirl.create :inventory_item
        @inventory_item.actable_type = 'UnitItem'
        @inventory_item.actable_id = @unit_item.id
        @inventory_item.save
        @delivery_request_item.inventory_item = @inventory_item
        @delivery_request_item.save
        @delivery_request.delivery_request_items << @delivery_request_item
        @delivery_request.update_items_status_to_pending
        @delivery_request.save

        supplier = FactoryGirl.create :supplier
        supplier.name = 'Litobel'
        supplier.save

        api_authorization_header user.auth_token
        post :reject_delivery, { id: @delivery_request.id }
      end

      it "return a success message about the rejection of the DeliveryRequest" do
        authorize_request_response = json_response
        expect( authorize_request_response ).to have_key(:success)
      end

      it { should respond_with 201 }
    end
  end
end
