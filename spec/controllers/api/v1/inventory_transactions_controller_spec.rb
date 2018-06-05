require 'spec_helper'

describe Api::V1::InventoryTransactionsController do
  describe "GET #show" do
    before(:each) do
      @inventory_transaction = FactoryGirl.create :inventory_transaction
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
      5.times { FactoryGirl.create :check_in_transaction }
      get :index
    end

    it "returns 5 records from the database" do
      inventory_transaction_response = json_response[:inventory_transactions]
      expect(inventory_transaction_response.size).to eq(5)
    end

    it { should respond_with 200 }
  end

  describe "GET #get_check_ins" do
    before(:each) do
      3.times { FactoryGirl.create :check_in_transaction }
      get :get_check_ins
    end

    it "returns 3 entry_transaction records" do
      inventory_transaction_response = json_response[:inventory_transactions]
      expect(inventory_transaction_response.size).to eq(3)
    end
  end

  describe "GET #get_check_outs" do
    before(:each) do
      3.times { FactoryGirl.create :check_out_transaction }
      get :get_check_outs
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
        expect(folio_response).to eq('FS-0000000')
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
end
