# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::ProjectsController do
  describe 'GET #show' do
    before(:each) do
      @project = FactoryBot.create :project
      5.times{ create_item_with_location(100, @project) }

      get :show, params: { id: @project.id }
    end

    it 'returns the information about project in JSON format' do
      project_response = json_response[:project]
      expect(project_response[:name]).to eql @project.name
      expect(project_response[:litobel_id]).to eql @project.litobel_id
    end

    it 'returns all InventoryItem data' do
      project_response = json_response[:project]

      expect(project_response[:inventory_items].count).to eql 5
    end

    it { should respond_with 200 }
  end

  describe 'GET #lean_index' do
    before{ FactoryBot.create_list(:project, 5) }
    before(:each) { get :lean_index }

    it 'returns Projects in JSON format' do
      project_response = json_response[:projects]
      expect(project_response.count).to eq 5
    end

    it 'should include Client' do
      project_response = json_response[:projects]
      first_project = project_response.first

      expect(first_project).to have_key(:client)
    end

    it { should respond_with 200 }
  end

  describe 'GET #index' do
    before(:each) do
      5.times { FactoryBot.create :project }
      get :index
    end

    it 'returns 5 records from the database' do
      project_response = json_response[:projects]
      expect(project_response.size).to eq(5)
    end

    it { should respond_with 200 }
  end

  describe 'POST #create' do
    context 'when project is succesfully created' do
      before(:each) do
        user = FactoryBot.create :user
        client = FactoryBot.create :client

        ae = FactoryBot.create :user
        ae.role = User::ACCOUNT_EXECUTIVE
        @project_attributes = FactoryBot.attributes_for :project
        @project_attributes[:client_id] = client.id
        api_authorization_header user.auth_token
        post :create, params: { user_id: user.id, ae_id: ae.id, project: @project_attributes }, format: :json
      end

      it 'renders the project record just created in JSON format' do
        project_response = json_response[:project]
        expect(project_response[:name]).to eql @project_attributes[:name]
      end

      it { should respond_with 201 }
    end

    context 'when project is not created' do
      before(:each) do
        user = FactoryBot.create :user
        ae = FactoryBot.create :user
        ae.role = User::ACCOUNT_EXECUTIVE
        invalid_project_attributes = FactoryBot.attributes_for(:project, name: nil)

        api_authorization_header user.auth_token
        post :create, params: { user_id: user.id, ae_id: ae.id, project: invalid_project_attributes }, format: :json
      end

      it 'renders an errors json' do
        project_response = json_response
        expect(project_response).to have_key(:errors)
      end

      it 'renders the json errors when there is no client present' do
        project_response = json_response
        expect(project_response[:errors][:client]).to include 'El cliente no puede estar vacío'
      end

      it { should respond_with 422 }
    end
  end

  describe 'POST #update' do
    let(:user) { FactoryBot.create(:user) }
    let(:project) { FactoryBot.create(:project) }
    let(:client) { FactoryBot.create(:client, name: 'Miggy') }

    context 'when successful' do
      before(:each) do
        api_authorization_header user.auth_token
        post :update, params: { id: project.id,
                                project: { litobel_id: 'hp_new_id', name: 'new_name', client_id: client.id } }, format: :json
      end

      it 'renders the json representation for the updated project' do
        project_response = json_response[:project]
        expect(project_response[:litobel_id]).to eql 'hp_new_id'
        expect(project_response[:name]).to eql 'new_name'
        expect(project_response[:client][:name]).to eql 'Miggy'
      end

      it { should respond_with 200 }
    end

    context 'when not successful' do
      before(:each) do
        @user = FactoryBot.create :user
        @project = FactoryBot.create :project
        @invalid_project = FactoryBot.create :project
        api_authorization_header @user.auth_token
        patch :update, params: { id: @invalid_project.id,
                                 project: { litobel_id: @project.litobel_id } }, format: :json
      end

      it 'renders an errors json' do
        project_response = json_response
        expect(project_response).to have_key(:errors)
      end

      it 'renders the json errors when the email is invalid' do
        user_response = json_response
        expect(user_response[:errors][:litobel_id]).to include 'Ya existe un proyecto con esa clave de proyecto'
      end
    end
  end

  describe 'DELETE #destroy' do
    context 'when is destroyed correctly' do
      before(:each) do
        user = FactoryBot.create :user
        project = FactoryBot.create :project
        api_authorization_header user.auth_token
        delete :destroy, params: { user_id: user.id, id: project.id }
      end

      it { should respond_with 201 }
    end
  end

  describe 'GET #project_users' do
    before(:each) do
      project = FactoryBot.create :project

      3.times do
        user = FactoryBot.create :user
        project.users << user
      end

      get :project_users, params: { id: project.id }
    end

    it 'returns the users of the given project in JSON format' do
      project_users_response = json_response[:users]
      expect(project_users_response.size).to eq 3
    end

    it { should respond_with 200 }
  end

  describe 'GET #project_client' do
    before(:each) do
      project = FactoryBot.create :project
      @client = project.client

      get :project_client, params: { id: project.id }
    end

    it 'returns the client of the given project in JSON format' do
      project_client_response = json_response[:client]
      expect(project_client_response[:name]).to eq @client.name
    end

    it { should respond_with 200 }
  end

  describe 'GET #by_user' do
    before(:each) do
      project_a = FactoryBot.create :project
      project_b = FactoryBot.create :project
      @user = FactoryBot.create :user
      @user.projects << project_a
      @user.projects << project_b

      get :by_user, params: { id: @user.id }
    end

    it 'returns the projects for a given user' do
      project_response = json_response[:projects]
      expect(project_response.count).to eq 2
    end

    it { should respond_with 200 }
  end

  describe 'POST #add_users' do
    context 'when user are added to project' do
      before(:each) do
        user = FactoryBot.create :user
        @ae = FactoryBot.create :user
        @ae.role = User::ACCOUNT_EXECUTIVE

        @project = FactoryBot.create :project
        api_authorization_header user.auth_token
        post :add_users, params: { new_ae_id: @ae.id, project_id: @project.id }
      end

      it 'renders the project record just created in JSON format' do
        json_response
        expect(@project.users.count).to eql 1
      end

      it { should respond_with 201 }
    end

    context 'when user are not added to project' do
      before(:each) do
        user = FactoryBot.create :user
        @project = FactoryBot.create :project
        api_authorization_header user.auth_token
        post :add_users, params: { project_id: @project.id }
      end

      it 'renders an errors message' do
        expect(json_response).to have_key(:errors)
      end

      it 'renders the json errors when there are no users present' do
        expect(json_response[:errors]).to include 'Necesitas agregar al menos un Ejecutivo de Cuenta'
      end
    end
  end

  describe 'POST #remove_user' do
    context 'when a user is removed from project' do
      before(:each) do
        user = FactoryBot.create :user
        @ae = FactoryBot.create :user
        @ae.role = User::ACCOUNT_EXECUTIVE
        @project = FactoryBot.create :project
        @project.users << @ae
        @project.save

        api_authorization_header user.auth_token
        post :remove_user, params: { user_id: @ae.id, project_id: @project.id }
      end

      it 'removes the user from the project' do
        json_response
        expect(@project.users.count).to eql 0
      end

      it 'renders a success message' do
        expect(json_response).to have_key(:success)
      end

      it { should respond_with 200 }
    end
  end

  describe 'POST #transfer_inventory' do
    let(:user) { FactoryBot.create(:user) }
    let(:from_project) { create_project_with_items(5) }

    context 'when an Inventory is transferred successfully between Projects' do
      let(:to_project) { FactoryBot.create(:project) }
      before(:each) do
        api_authorization_header user.auth_token
        post :transfer_inventory, params: { from_project_id: from_project.id, to_project_id: to_project.id }
      end

      it 'returns true if inventory was transferred' do
        expect(json_response[:success]).to eql 'Se ha transferido el proyecto con éxito'
      end

      it { should respond_with 200 }
    end

    context 'when an Inventory is not transferred' do
      before(:each) do
        api_authorization_header user.auth_token
        post :transfer_inventory, params: { from_project_id: from_project.id, to_project_id: -1 }
      end

      it 'returns true if inventory was transferred' do
        expect(json_response[:errors]).to eql 'No existe el proyecto fuente o destino'
      end

      it { should respond_with 422 }
    end
  end

  describe 'POST #transfer_inventory_items' do
    let(:user) { FactoryBot.create(:user) }
    let(:from_project) { create_project_with_items(5) }
    let(:item_to_transfer) { from_project.inventory_items.first }

    context 'when an Inventory is transferred successfully between Projects' do
      let(:to_project) { FactoryBot.create(:project) }
      before(:each) do
        api_authorization_header user.auth_token
        post :transfer_inventory_items, params: { from_project_id: from_project.id, to_project_id: to_project.id, items_ids: [item_to_transfer.id] }
      end

      it 'returns true if inventory was transferred' do
        expect(json_response[:success]).to eql 'Se ha transferido el inventario con éxito'
        expect(to_project.inventory_items.count).to eq 1
        expect(from_project.inventory_items.count).to eq 4
      end

      it { should respond_with 200 }
    end

    context 'when an Inventory is not transferred' do
      before(:each) do
        api_authorization_header user.auth_token
        post :transfer_inventory_items, params: { from_project_id: from_project.id, to_project_id: -1, items_ids: [item_to_transfer.id] }
      end

      it 'returns true if inventory was transferred' do
        expect(json_response[:errors]).to eql 'No existe el proyecto fuente o destino'
      end

      it { should respond_with 422 }
    end
  end

  describe 'POST #inventory' do
    let(:user) { FactoryBot.create(:user) }
    let(:project) { create_project_with_items(3) }

    context 'when successful' do
      before(:each) do
        api_authorization_header user.auth_token

        post :inventory, params: { id: project.id }
      end

      it "when Project's inventory is returned correctly" do
        project_response = json_response[:inventory_items]
        expect(project_response.count).to eq 3
      end

      it { should respond_with 200 }
    end
  end

  describe 'POST #clean_inventory' do
    let(:user) { FactoryBot.create(:user) }
    let(:project){ FactoryBot.create(:project) }
    let(:item) { 10.times { create_item_with_location(100, project) } }

    context 'when successful' do
      before(:each) do
        api_authorization_header user.auth_token

        post :clean_inventory, params: { id: project.id }
      end

      it "when Project's inventory is cleaned" do
        project_response = json_response[:success]

        expect(project_response).to eq "¡Se ha reiniciado el inventario del proyecto #{project.name} correctamente!"
        expect(project.inventory_items.count).to eq 0
      end

      it { should respond_with 200 }
    end
  end
end
