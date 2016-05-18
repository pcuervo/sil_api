require 'spec_helper'

RSpec.describe Api::V1::WithdrawRequestsController, type: :controller do
  describe "GET #index" do
    before(:each) do
      user = FactoryGirl.create :user
      5.times { FactoryGirl.create :withdraw_request }
      get :index
    end

    it "returns 5 records from the database" do
      withdraw_request_response = json_response[:withdraw_requests]
      expect(withdraw_request_response.size).to eq( 5 )
    end

    it { should respond_with 200 }
  end

  describe "POST #create" do
    context "when is succesfully created" do
      before(:each) do
        user = FactoryGirl.create :user
        item = FactoryGirl.create :inventory_item
        @withdraw_request_attributes = FactoryGirl.attributes_for :withdraw_request
        @withdraw_request_items = FactoryGirl.attributes_for :withdraw_request_item
        @withdraw_request_items[:inventory_item_id] = item.id
        @withdraw_request_attributes[:inventory_items] = []
        @withdraw_request_attributes[:inventory_items].push( @withdraw_request_items )
        api_authorization_header user.auth_token
        post :create, { withdraw_request: @withdraw_request_attributes }
      end

      it "renders the json representation for the WithdrawRequest just created" do
        withdraw_request_response = json_response[:withdraw_request]
        expect( withdraw_request_response[:pickup_company_id] ).to eql @withdraw_request_attributes[:pickup_company_id]
        expect( withdraw_request_response[:withdraw_request_items].count ).to eql 1
      end

      it { should respond_with 201 }
    end

    # context "when is not created" do
    #   before(:each) do
    #     user = FactoryGirl.create :user
    #     @invalid_withdraw_request_attributes = { user_id: user.id }

    #     api_authorization_header user.auth_token
    #     post :create, { user_id: user.id, withdraw_request: @invalid_withdraw_request_attributes, item_img_ext: 'jpg' }
    #   end

    #   it "renders an errors json" do
    #     withdraw_request_response = json_response
    #     expect(withdraw_request_response).to have_key(:errors)
    #   end

    #   it "renders the json errors on why the inventory item could not be created" do
    #     withdraw_request_response = json_response

    #     expect(withdraw_request_response[:errors][:name]).to include "can't be blank"
    #   end

    #   it { should respond_with 422 }
    # end
  end

  describe "POST #authorize_withdrawal" do
    context "when is succesfully created" do
      before(:each) do
        user = FactoryGirl.create :user
        @withdraw_request = FactoryGirl.create :withdraw_request
        @withdraw_request_item = FactoryGirl.create :withdraw_request_item
        @unit_item = FactoryGirl.create :unit_item
        @inventory_item = FactoryGirl.create :inventory_item
        @inventory_item.actable_type = 'UnitItem'
        @inventory_item.actable_id = @unit_item.id
        @inventory_item.save
        @withdraw_request_item.inventory_item = @inventory_item
        @withdraw_request_item.save
        @withdraw_request.withdraw_request_items << @withdraw_request_item
        @withdraw_request.update_items_status_to_pending
        @withdraw_request.save

        api_authorization_header user.auth_token
        post :authorize_withdrawal, { id: @withdraw_request.id, pickup_company_contact: 'El rober', additional_comments: 'adicionales' }
      end

      it "renders the json representation for the WithdrawRequest just created" do
        authorize_request_response = json_response
        expect( authorize_request_response ).to have_key(:success)
      end

      it { should respond_with 201 }
    end
  end
end
