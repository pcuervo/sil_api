require 'spec_helper'

describe Api::V1::ProjectsController do
  describe "GET #show" do
    before(:each) do
      @project = FactoryGirl.create :project
      get :show, id: @project.id
    end

    it "returns the information about project in JSON format" do
      project_response = json_response[:project]
      expect(project_response[:name]).to eql @project.name
      expect(project_response[:litobel_id]).to eql @project.litobel_id
    end

    it { should respond_with 200 }
  end

  describe "GET #index" do
    before(:each) do
      5.times { FactoryGirl.create :project }
      get :index
    end

    it "returns 5 records from the database" do
      project_response = json_response[:projects]
      expect(project_response.size).to eq(5)
    end

    it { should respond_with 200 }
  end

  describe "POST #create" do
    context "when project is succesfully created" do
      before(:each) do
        user = FactoryGirl.create :user
        client = FactoryGirl.create :client
        client_contact = FactoryGirl.create :client_contact

        pm = FactoryGirl.create :user
        pm.role = User::PROJECT_MANAGER
        ae = FactoryGirl.create :user
        ae.role = User::ACCOUNT_EXECUTIVE
        @project_attributes = FactoryGirl.attributes_for :project
        @project_attributes[:client_id] = client.id
        api_authorization_header user.auth_token
        post :create, { user_id: user.id, client_contact_id: client_contact.id, pm_id: pm.id, ae_id: ae.id,  project: @project_attributes }
      end

      it "renders the project record just created in JSON format" do
        project_response = json_response[:project]
        expect(project_response[:name]).to eql @project_attributes[:name]
      end

      it { should respond_with 201 }
    end

    context "when project is not created" do
      before(:each) do
        user = FactoryGirl.create :user
        pm = FactoryGirl.create :user
        pm.role = User::PROJECT_MANAGER
        ae = FactoryGirl.create :user
        ae.role = User::ACCOUNT_EXECUTIVE
        @invalid_project_attributes = { name: "Proyecto Inválido" }

        api_authorization_header user.auth_token
        post :create, { user_id: user.id, pm_id: pm.id, ae_id: ae.id, project: @invalid_project_attributes }
      end

      it "renders an errors json" do 
        project_response = json_response
        expect(project_response).to have_key(:errors)
      end

      it "renders the json errors when there is no client present" do
        project_response = json_response
        expect(project_response[:errors][:client]).to include "can't be blank"
      end

      it { should respond_with 422 }
    end
  end

  describe "PUT/PATCH #update" do
    context "when project is successfully updated" do
      before(:each) do
        @user = FactoryGirl.create :user
        @project = FactoryGirl.create :project
        api_authorization_header @user.auth_token
        patch :update, { id: @project.id,
                          project: { litobel_id: 'hp_new_id', name: 'new_name' } }, format: :json
      end

      it "renders the json representation for the updated project" do
        project_response = json_response[:project]
        expect(project_response[:litobel_id]).to eql "hp_new_id"
        expect(project_response[:name]).to eql "new_name"
      end

      it { should respond_with 200 }
    end

    context "when is not updated because litobel_id is already taken" do
      before(:each) do
        @user = FactoryGirl.create :user
        @project = FactoryGirl.create :project
        @invalid_project = FactoryGirl.create :project
        api_authorization_header @user.auth_token
        patch :update, { id: @invalid_project.id,
                          project: { litobel_id: @project.litobel_id } }, format: :json
      end

      it "renders an errors json" do
        project_response = json_response
        expect(project_response).to have_key(:errors)
      end

      it "renders the json errors when the email is invalid" do
        user_response = json_response
        expect(user_response[:errors][:litobel_id]).to include "has already been taken"
      end
    end
  end

  describe "DELETE #destroy" do
    before(:each) do
      user = FactoryGirl.create :user
      project = FactoryGirl.create :project
      api_authorization_header user.auth_token
      delete :destroy, { user_id: user.id, id: project.id }
    end

    it { should respond_with 204 }
  end

  describe "GET #get_project_users" do
    before(:each) do
      project = FactoryGirl.create :project

      3.times do
        user = FactoryGirl.create :user
        project.users << user
      end

      get :get_project_users, id: project.id
    end

    it "returns the users of the given project in JSON format" do
      project_users_response = json_response[:users]
      expect(project_users_response.size).to eq 3
    end

    it { should respond_with 200 }
  end

  describe "GET #get_project_client" do
    before(:each) do
      project = FactoryGirl.create :project
      @client = project.client
      client_contact = FactoryGirl.create :client_contact
      @client.client_contacts << client_contact

      get :get_project_client, id: project.id
    end

    it "returns the client and client_contact of the given project in JSON format" do
      project_client_response = json_response[:client]
      expect(project_client_response[:name]).to eq @client.name
    end

    it { should respond_with 200 }
  end

  describe "GET #by_user" do
    before(:each) do
      project_a = FactoryGirl.create :project
      project_b = FactoryGirl.create :project
      @user = FactoryGirl.create :user
      @user.projects << project_a
      @user.projects << project_b

      get :by_user, id: @user.id
    end

    it "returns the projects for a given user" do
      project_response = json_response[:projects]
      expect(project_response.count).to eq 2
    end

    it { should respond_with 200 }
  end

  describe "POST #add_users" do
    context "when user are added to project" do
      before(:each) do
        user = FactoryGirl.create :user
        @pm = FactoryGirl.create :user
        @pm.role = User::PROJECT_MANAGER
        @ae = FactoryGirl.create :user
        @ae.role = User::ACCOUNT_EXECUTIVE

        @project = FactoryGirl.create :project
        api_authorization_header user.auth_token
        post :add_users, { new_pm_id: @pm.id, new_ae_id: @ae.id, project_id: @project.id }
      end

      it "renders the project record just created in JSON format" do
        project_response = json_response
        expect(@project.users.count).to eql 2
      end

      it { should respond_with 201 }
    end

    context "when user are not added to project" do
      before(:each) do
        user = FactoryGirl.create :user
        @project = FactoryGirl.create :project
        api_authorization_header user.auth_token
        post :add_users, { project_id: @project.id }
      end

      it "renders an errors message" do
        project_response = json_response
        expect(project_response).to have_key(:errors)
      end

      it "renders the json errors when there are no users present" do
        project_response = json_response
        expect(project_response[:errors]).to include "Necesitas agregar al menos un Project Manager o Ejecutivo de Cuenta"
      end
    end
  end

  describe "POST #remove_user" do
    context "when a user is removed from project" do
      before(:each) do
        user = FactoryGirl.create :user
        @ae = FactoryGirl.create :user
        @ae.role = User::ACCOUNT_EXECUTIVE
        @project = FactoryGirl.create :project
        @project.users << @ae
        @project.save

        api_authorization_header user.auth_token
        post :remove_user, { user_id: @ae.id, project_id: @project.id }
      end

      it "removes the user from the project" do
        project_response = json_response
        expect( @project.users.count ).to eql 0
      end

      it "renders a success message" do
        project_response = json_response
        expect( json_response ).to have_key(:success)
      end

      it { should respond_with 200 }
    end

  end

end
