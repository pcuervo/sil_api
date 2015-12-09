require 'spec_helper'

describe Api::V1::UsersController do
  describe "GET #show" do
    before(:each) do
      @user = FactoryGirl.create :user
      get :show, id: @user.id, format: :json
    end

    it "returns the information about a user on a hash" do
      user_response = json_response[:user]
      expect(user_response[:email]).to eql @user.email
    end

    it { should respond_with 200 }
  end

  describe "POST #create" do

    context "when is successfully created" do
      before(:each) do
        @user_attributes = FactoryGirl.attributes_for :user
        @user = FactoryGirl.create :user
        api_authorization_header @user.auth_token
        post :create, { id: @user.id,
                        user: @user_attributes }, format: :json
      end

      it "renders the json representation for the user record just created" do
        user_response = json_response[:user]
        expect(user_response[:email]).to eql @user_attributes[:email]
      end

      it { should respond_with 201 }
    end

    context "when is not created" do
      before(:each) do
        @invalid_user_attributes = { password: "12345678",
                                     password_confirmation: "12345678" }
        @user = FactoryGirl.create :user
        api_authorization_header @user.auth_token
        post :create, { id: @user.id,
                        user: @invalid_user_attributes }, format: :json
      end

      it "renders an errors json" do
        user_response = json_response
        expect(user_response).to have_key(:errors)
      end

      it "renders the json errors when no email is present" do
        user_response = json_response
        expect(user_response[:errors][:email]).to include "can't be blank"
      end

      it "renders the json errors when the role is invalid" do
        @invalid_user_attributes = { email: "test@test.com", first_name: 'Mic', last_name: 'Cab', password: 'holama123', password_confirmation: 'holama123', role: 8 }
        post :create, { user: @invalid_user_attributes }, format: :json
        user_response = json_response
        expect(user_response[:errors][:role]).to include "#{@invalid_user_attributes[:role]} is not a valid role"
      end

      it "renders the json errors when the name is missing" do
        @invalid_user_attributes = { email: "test@test.com", last_name: 'Cab', password: 'holama123', password_confirmation: 'holama123', role: 2 }
        post :create, { user: @invalid_user_attributes }, format: :json
        user_response = json_response
        expect(user_response[:errors][:first_name]).to include "can't be blank"
      end

      it "renders the json errors when the last name is missing" do
        @invalid_user_attributes = { email: "test@test.com", first_name: 'Mig', password: 'holama123', password_confirmation: 'holama123', role: 2 }
        post :create, { user: @invalid_user_attributes }, format: :json
        user_response = json_response
        expect(user_response[:errors][:last_name]).to include "can't be blank"
      end

      it { should respond_with 422 }
    end
  end

  describe "PUT/PATCH #update" do

    context "when is successfully updated" do
      before(:each) do
        @user = FactoryGirl.create :user
        api_authorization_header @user.auth_token
        patch :update, { id: @user.id,
                         user: { email: "newmail@example.com" } }, format: :json
      end

      it "renders the json representation for the updated user" do
        user_response = json_response[:user]
        expect(user_response[:email]).to eql "newmail@example.com"
      end

      it { should respond_with 200 }
    end

    context "when is not updated" do
      before(:each) do
        @user = FactoryGirl.create :user
        api_authorization_header @user.auth_token
        patch :update, { id: @user.id,
                         user: { email: "bademail.com", role: 5 } }, format: :json
      end

      it "renders an errors json" do
        user_response = json_response
        expect(user_response).to have_key(:errors)
      end

      it "renders the json errors when the email is invalid" do
        user_response = json_response
        expect(user_response[:errors][:email]).to include "is invalid"
      end

      it { should respond_with 422 }
    end
  end

  describe "DELETE #destroy" do
    before(:each) do
      @user = FactoryGirl.create :user
      api_authorization_header @user.auth_token #we added this line
      delete :destroy, id: @user.auth_token
    end

    it { should respond_with 204 }

  end
end
