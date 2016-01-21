require 'spec_helper'

describe Api::V1::SuppliersController do
  describe "GET #show" do 
    before(:each) do
      @supplier = FactoryGirl.create :supplier
      get :show, id: @supplier.id
    end

    it "returns the information about a supplier in JSON format" do
      supplier_response = json_response[:supplier]
      expect(supplier_response[:name]).to eql @supplier.name
    end

    it { should respond_with 200 }
  end

  describe "GET #index" do
    before(:each) do
      5.times { FactoryGirl.create :supplier }
      get :index
    end

    it "it should return 5 suppliers from database" do
      suppliers_response = json_response[:suppliers]
      expect(suppliers_response.size).to eq(5)
    end

    it { should respond_with 200 }
  end

  describe "POST #create" do
    context "When supplier is successfully created" do 
      before(:each) do
        user = FactoryGirl.create :user
        @supplier_attributes = FactoryGirl.attributes_for :supplier
        api_authorization_header user.auth_token
        post :create, { supplier: @supplier_attributes }
      end

      it "renders the JSON representation for the supplier record just created" do
        supplier_response = json_response[:supplier]
        expect(supplier_response[:name]).to eql @supplier_attributes[:name]
      end

      it { should respond_with 201 }
    end

    context "when is not created" do 
      before(:each) do
        user = FactoryGirl.create :user
        supplier = FactoryGirl.create :supplier
        @invalid_supplier_attributes = { name: supplier.name }

        api_authorization_header user.auth_token
        post :create, { supplier: @invalid_supplier_attributes }
      end

      it "renders an errors json" do
        supplier_response = json_response
        expect(supplier_response).to have_key(:errors)
      end

      it "renders the json errors that say that supplier could not be created" do
        supplier_response = json_response
        expect(supplier_response[:errors][:name]).to include "has already been taken"
      end

      it { should respond_with 422 }
    end
  end

  describe "PUT/PATCH #update" do
    before(:each) do
      user = FactoryGirl.create :user
      supplier = FactoryGirl.create :supplier
      api_authorization_header user.auth_token

      patch :update, { id: supplier.id, supplier: { name: 'new_name' } }
    end

    context "when is successfully updated" do
      it "renders the json representation for the updated supplier" do
        supplier_response = json_response[:supplier]
        expect(supplier_response[:name]).to eq('new_name')
      end

      it { should respond_with 201 }
    end

  end

  describe "DELETE #destroy" do
    before(:each) do
      user = FactoryGirl.create :user
      supplier = FactoryGirl.create :supplier
      api_authorization_header user.auth_token
      delete :destroy, id: supplier.id
    end

    it { should respond_with 204 }
  end
end
