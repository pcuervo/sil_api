require 'spec_helper'

describe Api::V1::InventoryTransactionsController do
  describe "GET #show" do
    before(:each) do
      check_in = FactoryBot.create :check_in_transaction
      @inventory_transaction = check_in.acting_as
      get :show, params: { id: @inventory_transaction.id }
    end

    it "returns the information about an inventory transaction on a hash" do
      inventory_transaction_response = json_response[:inventory_transaction]
      expect(inventory_transaction_response[:concept]).to eql @inventory_transaction.concept
    end

    it { should respond_with 200 }
  end

  describe "GET #index" do
    before(:each) do
      user = FactoryBot.create(:user)
      5.times { FactoryBot.create(:check_in_transaction) }

      api_authorization_header user.auth_token
      get :index
    end

    it "returns 5 records from the database" do
      inventory_transaction_response = json_response[:inventory_transactions]
      expect(inventory_transaction_response.size).to eq(5)
    end

    it { should respond_with 200 }
  end

  describe "GET #check_ins" do
    before(:each) do
      3.times { FactoryBot.create :check_in_transaction }
      user = FactoryBot.create(:user)

      api_authorization_header user.auth_token
      get :check_ins
    end

    it "returns 3 entry_transaction records" do
      inventory_transaction_response = json_response[:inventory_transactions]
      expect(inventory_transaction_response.size).to eq(3)
    end
  end

  describe "GET #check_outs" do
    before(:each) do
      @user = FactoryBot.create(:user, role: User::ADMIN)
      3.times { FactoryBot.create :check_out_transaction }

      api_authorization_header @user.auth_token
      get :check_outs
    end

    it "returns 3 entry_transaction records" do
      inventory_transaction_response = json_response[:inventory_transactions]
      expect(inventory_transaction_response.size).to eq(3)
    end
  end


  describe "GET #last_checkout_folio" do
    before(:each) do
      FactoryBot.create :check_out_transaction
    end

    context "when there are no new folios" do
      before do 
        get :last_checkout_folio
      end
      it "returns the first folio since no previous folios have been created" do
        folio_response = json_response[:folio]
        expect(folio_response).to eq('FS-0000001')
      end

      it { should respond_with 200 }
    end

    context "when there are existing folios" do
      before do 
        last_checkout = CheckOutTransaction.last
        last_checkout.folio = 'FS-0000010'
        last_checkout.save
        get :last_checkout_folio
      end
      it "returns the last folio" do
        folio_response = json_response[:folio]
        expect(folio_response).to eq('FS-0000010')
      end

      it { should respond_with 200 }
    end
  end

  describe "POST #latest" do
    let(:user) { FactoryBot.create(:user, role: User::ADMIN) }

    before do
      3.times { FactoryBot.create :check_in_transaction }
      3.times { FactoryBot.create :check_out_transaction }
    end
      
    context 'when returning latest CheckIns' do
      before(:each) do
        api_authorization_header user.auth_token
        get :latest, params: { type: 'check_in', num_transactions: 10 }
      end

      it "returns 3 CheckIn transactions" do
        inventory_transaction_response = json_response[:check_in_transactions]
        expect(inventory_transaction_response.size).to eq(3)
      end
    end

    context 'when returning latest CheckOuts' do
      before(:each) do
        api_authorization_header user.auth_token
        get :latest, params: { type: 'check_out', num_transactions: 10 }
      end

      it "returns 3 CheckOut transactions" do
        inventory_transaction_response = json_response[:check_out_transactions]
        expect(inventory_transaction_response.size).to eq(3)
      end
    end
  end

  describe "POST #latest_by_user" do
    let(:project) { create_project_with_items(5) }
    let(:user) { FactoryBot.create(:user, role: User::ADMIN) }

    before { add_users_to_project(project) }
  end

  describe "POST #cancel_folio" do
    let(:user) { FactoryBot.create(:user, role: User::ADMIN) }
    let(:num_items){ 5 }
    let(:user){ FactoryBot.create(:user) }
    let(:item_data) { csv_load_attributes(num_items) }
    let(:inventory_loader){ InventoryLoad.new(user, item_data) }
    let(:litobel){ Supplier.find_or_create_by(name: 'Litobel') }

    before { inventory_loader.load }

    context 'when successful with CheckOut folio' do
      let(:folio){ InventoryTransaction.next_checkout_folio }

      before do
        InventoryItem.all.each do |item|
          item.withdraw(
            Date.today, 
            '', 
            litobel.id, 
            '', 
            'This is a test', 
            item.quantity, 
            folio
          )
        end
      end

      before(:each) do
        api_authorization_header user.auth_token
        post :cancel_folio, params: { folio: folio }
      end

      it 'should return success message' do
        expect(json_response).to have_key(:success)
        expect(json_response[:items]).to eq 5
      end

      it { should respond_with 200 }
    end

    context 'when successful with CheckIn folio' do
      before(:each) do
        folio = CheckInTransaction.last.folio
        api_authorization_header user.auth_token
        post :cancel_folio, params: { folio: folio }
      end

      it 'should return success message' do
        expect(json_response).to have_key(:success)
        expect(json_response[:items]).to eq 5
      end

      it { should respond_with 200 }
    end

    context 'when not successful' do
      before(:each) do
        api_authorization_header user.auth_token
        post :cancel_folio, params: { folio: 'fakefolio' }
      end

      it 'should return success message' do
        expect(json_response).to have_key(:error)
        expect(json_response[:error]).to eq 'No se encontró el folio'
      end

      it { should respond_with 422 }
    end
  end

  describe "POST #by_project" do
    let(:project) { create_project_with_items(5) }
    let(:user) { FactoryBot.create(:user, role: User::ADMIN) }
      
    before(:each) do
      api_authorization_header user.auth_token
      post :by_project, params: { project_id: project.id, type: 'checkin', start_date: 2.days.ago }
    end

    it "returns transactions by project" do
      inventory_transaction_response = json_response[:inventory_transactions]
      expect(inventory_transaction_response.size).to eq(5)
    end

  end
end
