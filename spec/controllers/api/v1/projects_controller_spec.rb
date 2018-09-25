require 'spec_helper'

describe Api::V1::ProjectsController do
  describe 'GET #show' do
    before(:each) do
      @project = FactoryBot.create :project
      get :show, id: @project.id
    end

    it 'returns the information about project in JSON format' do
      project_response = json_response[:project]
      expect(project_response[:name]).to eql @project.name
      expect(project_response[:litobel_id]).to eql @project.litobel_id
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
        client_contact = FactoryBot.create :client_contact

        pm = FactoryBot.create :user
        pm.role = User::PROJECT_MANAGER
        ae = FactoryBot.create :user
        ae.role = User::ACCOUNT_EXECUTIVE
        @project_attributes = FactoryBot.attributes_for :project
        @project_attributes[:client_id] = client.id
        api_authorization_header user.auth_token
        post :create, user_id: user.id, client_contact_id: client_contact.id, pm_id: pm.id, ae_id: ae.id, project: @project_attributes
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
        pm = FactoryBot.create :user
        pm.role = User::PROJECT_MANAGER
        ae = FactoryBot.create :user
        ae.role = User::ACCOUNT_EXECUTIVE
        @invalid_project_attributes = { name: 'Proyecto Inválido' }

        api_authorization_header user.auth_token
        post :create, user_id: user.id, pm_id: pm.id, ae_id: ae.id, project: @invalid_project_attributes
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

  describe 'PUT/PATCH #update' do
    context 'when project is successfully updated' do
      before(:each) do
        @user = FactoryBot.create :user
        @project = FactoryBot.create :project
        api_authorization_header @user.auth_token
        patch :update, { id: @project.id,
                         project: { litobel_id: 'hp_new_id', name: 'new_name' } }, format: :json
      end

      it 'renders the json representation for the updated project' do
        project_response = json_response[:project]
        expect(project_response[:litobel_id]).to eql 'hp_new_id'
        expect(project_response[:name]).to eql 'new_name'
      end

      it { should respond_with 200 }
    end

    context 'when is not updated because litobel_id is already taken' do
      before(:each) do
        @user = FactoryBot.create :user
        @project = FactoryBot.create :project
        @invalid_project = FactoryBot.create :project
        api_authorization_header @user.auth_token
        patch :update, { id: @invalid_project.id,
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
        delete :destroy, user_id: user.id, id: project.id
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

      get :project_users, id: project.id
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
      client_contact = FactoryBot.create :client_contact
      @client.client_contacts << client_contact

      get :project_client, id: project.id
    end

    it 'returns the client and client_contact of the given project in JSON format' do
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

      get :by_user, id: @user.id
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
        @pm = FactoryBot.create :user
        @pm.role = User::PROJECT_MANAGER
        @ae = FactoryBot.create :user
        @ae.role = User::ACCOUNT_EXECUTIVE

        @project = FactoryBot.create :project
        api_authorization_header user.auth_token
        post :add_users, new_pm_id: @pm.id, new_ae_id: @ae.id, project_id: @project.id
      end

      it 'renders the project record just created in JSON format' do
        json_response
        expect(@project.users.count).to eql 2
      end

      it { should respond_with 201 }
    end

    context 'when user are not added to project' do
      before(:each) do
        user = FactoryBot.create :user
        @project = FactoryBot.create :project
        api_authorization_header user.auth_token
        post :add_users, project_id: @project.id
      end

      it 'renders an errors message' do
        expect(json_response).to have_key(:errors)
      end

      it 'renders the json errors when there are no users present' do
        expect(json_response[:errors]).to include 'Necesitas agregar al menos un Project Manager, Ejecutivo de Cuenta o Contato Cliente'
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
        post :remove_user, user_id: @ae.id, project_id: @project.id
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
        post :transfer_inventory, from_project_id: from_project.id, to_project_id: to_project.id
      end

      it 'returns true if inventory was transferred' do
        expect(json_response[:success]).to eql 'Se ha transferido el proyecto con éxito'
      end

      it { should respond_with 200 }
    end

    context 'when an Inventory is not transferred' do
      before(:each) do
        api_authorization_header user.auth_token
        post :transfer_inventory, from_project_id: from_project.id, to_project_id: -1
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
        post :transfer_inventory_items, from_project_id: from_project.id, to_project_id: to_project.id, items_ids: [item_to_transfer.id]
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
        post :transfer_inventory_items, from_project_id: from_project.id, to_project_id: -1, items_ids: [item_to_transfer.id]
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

        post :inventory, id: project.id
      end

      it "when Project's inventory is returned correctly" do
        project_response = json_response[:projects]
        expect(project_response.count).to eq 3
      end

      it { should respond_with 200 }
    end
  end
end
