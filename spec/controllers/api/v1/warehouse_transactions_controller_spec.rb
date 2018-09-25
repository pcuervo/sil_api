require 'spec_helper'

RSpec.describe Api::V1::WarehouseTransactionsController, type: :controller do
  describe "GET #index" do 
    before(:each) do
      3.times { FactoryBot.create :warehouse_transaction }
      get :index
    end

    it "returns 3 unit items from the database" do
      warehouse_transaction_response = json_response
      expect(warehouse_transaction_response[:warehouse_transactions].size).to eq( 3 )
    end

    it { should respond_with 200 }
  end
end
