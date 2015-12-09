require 'spec_helper'

RSpec.describe Api::V1::ClientContactsController, type: :controller do
  describe "GET #show" do
    before(:each) do
      @client_contact = FactoryGirl.create :client_contact
      get :show, id: @client_contact.id
    end

    it "returns client_contact info in JSON format" do
      client_contact_response = json_response[:client_contact]
      expect(client_contact_response[:first_name]).to eq(@client_contact.first_name)
    end

    it { should respond_with 200 }
  end

  describe "GET #index" do
    before(:each) do
      5.times { FactoryGirl.create :client_contact }
      get :index
    end

    it "returns 5 client_contact records from database" do
      client_contact_response = json_response[:client_contacts]
      expect(client_contact_response.size).to eq(5)
    end

    it { should respond_with 200 }
  end

  describe "POST #create" do
    context "when client contact is successfully created" do
      before(:each) do
        user = FactoryGirl.create :user
        client = FactoryGirl.create :client
        @client_contact_attributes = FactoryGirl.attributes_for :client_contact
        @client_contact_attributes[:client_id] = client.id
        api_authorization_header user.auth_token
        post :create, { client_contact: @client_contact_attributes }
      end

      it "return a JSON representation of the created client contact" do
        client_contact_response = json_response[:client_contact]
        expect(client_contact_response[:first_name]).to eql @client_contact_attributes[:first_name]
      end

      it { should respond_with 201 }
    end

    context "when client contact could not be created" do
      before(:each) do
        user = FactoryGirl.create :user
        client = FactoryGirl.create :client
        @invalid_client_contact_attributes = { last_name: 'Cabral' }
        api_authorization_header user.auth_token
        post :create, { client_id: client.id, client_contact: @invalid_client_contact_attributes } 
      end

      it "render an errors JSON" do  
        client_contact_response = json_response
        expect(client_contact_response).to have_key(:errors)
      end

      it "renders the JSON errors that say that a client contact could not be created" do
        client_contact_response = json_response
        expect(client_contact_response[:errors][:first_name]).to include "can't be blank"
      end

      it { should respond_with 422 }
    end
  end

  describe "PUT/PATCH #update" do
    context "when client contact is updated successfully" do
      before(:each) do
        user = FactoryGirl.create :user
        client_contact = FactoryGirl.create :client_contact
        api_authorization_header user.auth_token
        patch :update, { id: client_contact.id, client_contact: { first_name: 'Miguel', last_name: 'Cabral' } } 
      end

      it "should return a JSON representation of the updated client contact" do
        client_contact_response = json_response[:client_contact]
        expect(client_contact_response[:first_name]).to eql('Miguel')
        expect(client_contact_response[:last_name]).to eql('Cabral')
      end

      it { should respond_with 201 }
    end

    context "when client contact could not be updated" do
      before(:each) do
        user = FactoryGirl.create :user
        client_contact = FactoryGirl.create :client_contact
        invalid_client_contact = FactoryGirl.create :client_contact
        api_authorization_header user.auth_token
        patch :update, { id: invalid_client_contact.id, client_contact: { email: client_contact.email } }
      end     

      it "should render an errors JSON" do 
        client_contact_response = json_response
        expect(client_contact_response).to have_key(:errors)
      end

      it "should render the JSON error that say the client contact could not be updated" do
        client_contact_response = json_response
        expect(client_contact_response[:errors][:email]).to include 'has already been taken'
      end

      it { should respond_with 422 }
    end

    context "when client contact does not belong to a valid client" do
      before(:each) do
        user = FactoryGirl.create :user
        client_contact = FactoryGirl.create :client_contact
        api_authorization_header user.auth_token
        patch :update, { id: client_contact.id, client_contact: { client_id: 'invalid_id' } }
      end     

      it "should render an errors JSON" do 
        client_contact_response = json_response
        expect(client_contact_response).to have_key(:errors)
      end

      it "should render the JSON error that say the client was invalid" do
        client_contact_response = json_response
        expect(client_contact_response[:errors][:client]).to include "can't be blank"
      end

      it { should respond_with 422 }
    end
  end

  describe "DELETE #destroy" do 
    before(:each) do
      user = FactoryGirl.create :user
      client_contact = FactoryGirl.create :client_contact
      api_authorization_header user.auth_token
      delete :destroy, id: client_contact.id
    end

    it { should respond_with 204 }
  end
end
