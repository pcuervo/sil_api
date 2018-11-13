require 'spec_helper'

RSpec.describe Api::V1::LogsController, type: :controller do
  describe "GET #index" do
    before(:each) do
      FactoryBot.create_list(:log, 5)
      get :index
    end

    it "returns all records from the database" do
      puts json_response.to_yaml
      logs_response = json_response[:logs]
      expect(logs_response.size).to eq(5)
    end

    it { should respond_with 200 }
  end
end
