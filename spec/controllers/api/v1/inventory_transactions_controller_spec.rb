require 'spec_helper'

describe Api::V1::InventoryTransactionsController do
  describe "GET #show" do
    before(:each) do
      check_in = FactoryGirl.create :check_in_transaction
      @inventory_transaction = check_in.acting_as
      get :show, id: @inventory_transaction.id
    end

    it "returns the information about an inventory transaction on a hash" do
      inventory_transaction_response = json_response[:inventory_transaction]
      expect(inventory_transaction_response[:concept]).to eql @inventory_transaction.concept
    end

    it { should respond_with 200 }
  end

  describe "GET #index" do
    before(:each) do
      user = FactoryGirl.create(:user)
      5.times { FactoryGirl.create(:check_in_transaction) }

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
      3.times { FactoryGirl.create :check_in_transaction }
      user = FactoryGirl.create(:user)

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
      @user = FactoryGirl.create(:user, role: User::ADMIN)
      3.times { FactoryGirl.create :check_out_transaction }

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
      FactoryGirl.create :check_out_transaction
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
    let(:user) { FactoryGirl.create(:user, role: User::ADMIN) }

    before do
      3.times { FactoryGirl.create :check_in_transaction }
      3.times { FactoryGirl.create :check_out_transaction }
    end
      
    context 'when returning latest CheckIns' do
      before(:each) do
        api_authorization_header user.auth_token
        get :latest, { type: 'check_in', num_transactions: 10 }
      end

      it "returns 3 CheckIn transactions" do
        inventory_transaction_response = json_response[:inventory_transactions]
        expect(inventory_transaction_response.size).to eq(3)
      end
    end

    context 'when returning latest CheckOuts' do
      before(:each) do
        api_authorization_header user.auth_token
        get :latest, { type: 'check_out', num_transactions: 10 }
      end

      it "returns 3 CheckOut transactions" do
        inventory_transaction_response = json_response[:inventory_transactions]
        expect(inventory_transaction_response.size).to eq(3)
      end
    end
  end

  describe "POST #latest_by_user" do
    let(:project) { create_project_with_items(5) }
    let(:user) { FactoryGirl.create(:user, role: User::ADMIN) }

    before { add_users_to_project(project) }
      
    context 'when retrieving by Client' do
      let(:client_user) { project.users.where('role = ?', User::CLIENT).first }

      before(:each) do
        api_authorization_header user.auth_token
        post :latest_by_user, { user_id: client_user.id, type: 'check_in', num_transactions: 3 }
      end

      it "returns 3 CheckIn transactions" do
        inventory_transaction_response = json_response[:inventory_transactions]
        expect(inventory_transaction_response.size).to eq(3)
      end
    end
  end
end
