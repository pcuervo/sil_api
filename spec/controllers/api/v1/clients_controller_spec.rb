require 'spec_helper'

describe Api::V1::ClientsController do
  describe "GET #show" do 
    before(:each) do
      @client = FactoryGirl.create :client
      get :show, id: @client.id
    end

    it "returns the information about a client in JSON format" do
      client_response = json_response[:client]
      expect(client_response[:name]).to eql @client.name
    end

    it { should respond_with 200 }
  end

  describe "GET #index" do
    before(:each) do
      5.times { FactoryGirl.create :client }
      get :index
    end

    it "it should return 5 clients from database" do
      clients_response = json_response[:clients]
      expect(clients_response.size).to eq(5)
    end

    it { should respond_with 200 }
  end

  describe "POST #create" do
    context "When client is successfully created" do 
      before(:each) do
        user = FactoryGirl.create :user
        @client_attributes = FactoryGirl.attributes_for :client
        api_authorization_header user.auth_token
        post :create, { client: @client_attributes }
      end

      it "renders the JSON representation for the client record just created" do
        client_response = json_response[:client]
        expect(client_response[:name]).to eql @client_attributes[:name]
      end

      it { should respond_with 201 }
    end

    context "when is not created" do 
      before(:each) do
        user = FactoryGirl.create :user
        client = FactoryGirl.create :client
        @invalid_client_attributes = { name: client.name }

        api_authorization_header user.auth_token
        post :create, { client: @invalid_client_attributes }
      end

      it "renders an errors json" do
        client_response = json_response
        expect(client_response).to have_key(:errors)
      end

      it "renders the json errors that say that client could not be created" do
        client_response = json_response
        expect(client_response[:errors][:name]).to include "has already been taken"
      end

      it { should respond_with 422 }
    end
  end

  describe "PUT/PATCH #update" do
    before(:each) do
      user = FactoryGirl.create :user
      client = FactoryGirl.create :client
      api_authorization_header user.auth_token

      patch :update, { id: client.id, client: { name: 'new_name' } }
    end

    context "when is successfully updated" do
      it "renders the json representation for the updated client" do
        client_response = json_response[:client]
        expect(client_response[:name]).to eq('new_name')
      end

      it { should respond_with 201 }
    end

    context "when is not successfully updated because project name already exists" do
      before(:each) do
        user = FactoryGirl.create :user
        client = FactoryGirl.create :client
        invalid_client = FactoryGirl.create :client
        api_authorization_header user.auth_token

        patch :update, { id: invalid_client.id, client: { name: client.name } }
      end

      it "renders an errors json" do
        client_response = json_response
        expect(client_response).to have_key(:errors)
      end

      it "renders the errors json when the name already exists" do
        client_response = json_response
        expect(client_response[:errors][:name]).to include "has already been taken"
      end

      it { should respond_with 422 }
    end
  end

  describe "DELETE #destroy" do
    before(:each) do
      user = FactoryGirl.create :user
      client = FactoryGirl.create :client
      api_authorization_header user.auth_token

      delete :destroy, id: client.id
    end

    it { should respond_with 204 }
  end
end
