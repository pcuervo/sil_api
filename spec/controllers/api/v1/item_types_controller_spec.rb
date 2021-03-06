require 'spec_helper'

RSpec.describe Api::V1::ItemTypesController, type: :controller do
  describe "GET #show" do
    before(:each) do
      @item_type = FactoryBot.create :item_type
      get :show, params: { id: @item_type.id }
    end

    it "returns the information about item_type in JSON format" do
      item_type_response = json_response[:item_type]
      expect(item_type_response[:name]).to eql @item_type.name
    end

    it { should respond_with 200 }
  end

  describe "GET #index" do
    before(:each) do
      FactoryBot.create :item_type
      get :index
    end

    it "returns all records from the database" do
      item_type_response = json_response[:item_types]
      expect(item_type_response.size).to eq(1)
    end

    it { should respond_with 200 }
  end

  describe "POST #create" do
    context "when item_type is succesfully created" do
      before(:each) do
        user = FactoryBot.create :user
        @item_type_attributes = FactoryBot.attributes_for :item_type
        api_authorization_header user.auth_token

        post :create, params: { user_id: user.id, item_type: @item_type_attributes }
      end

      it "renders the item_type record just created in JSON format" do
        item_type_response = json_response[:item_type]
        expect(item_type_response[:name]).to eql @item_type_attributes[:name]
      end

      it { should respond_with 201 }
    end

    context "when item_type is not created" do
      before(:each) do
        user = FactoryBot.create :user
        @invalid_item_type_attributes = { name: '' }
        api_authorization_header user.auth_token

        post :create, params: { user_id: user.id, item_type: @invalid_item_type_attributes }
      end

      it "renders an errors json" do 
        item_type_response = json_response
        expect(item_type_response).to have_key(:errors)
      end

      it "renders the json errors when there is no name" do
        item_type_response = json_response
        expect(item_type_response[:errors][:name]).to include "El tipo de mercancía es obligatorio"
      end

      it { should respond_with 422 }
    end
  end

  describe "POST #update" do
    context "when item_type is successfully updated" do
      before(:each) do
        @user = FactoryBot.create :user
        @item_type = FactoryBot.create :item_type
        api_authorization_header @user.auth_token
        post :update, params: { id: @item_type.id,
                        item_type: { name: 'new_name' } }, 
                        format: :json
      end

      it "renders the json representation for the updated item_type" do
        item_type_response = json_response[:item_type]
        expect(item_type_response[:name]).to eql "new_name"
      end

      it { should respond_with 200 }
    end

    context "when is not updated because name is not present" do
      before(:each) do
        @user = FactoryBot.create :user
        @item_type = FactoryBot.create :item_type
        api_authorization_header @user.auth_token
        patch :update, params: { id: @item_type.id,
                          item_type: { name: '' } }, format: :json
      end

      it "renders an errors json" do
        item_type_response = json_response
        expect(item_type_response).to have_key(:errors)
      end

      it "renders the json errors when the name is invalid" do
        user_response = json_response
        expect(user_response[:errors][:name]).to include "El tipo de mercancía es obligatorio"
      end
    end
  end

  describe "DELETE #destroy" do
    context "when is destroyed correctly" do
      before(:each) do
        user = FactoryBot.create :user
        item_type = FactoryBot.create :item_type
        api_authorization_header user.auth_token
        delete :destroy, params: { user_id: user.id, id: item_type.id }
      end

      it { should respond_with 201 }
    end
  end
end
