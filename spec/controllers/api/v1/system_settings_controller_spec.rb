require 'spec_helper'

RSpec.describe Api::V1::SystemSettingsController, type: :controller do
  describe "GET #show" do
    before(:each) do
      @system_settings = FactoryBot.create :system_setting
      get :show, params: { id: @system_settings.id }, format: :json
    end

    it "returns the SystemSettings in JSON format" do
      system_settings_response = json_response[:system_setting]
      expect( system_settings_response[:cost_per_location] ).to eql @system_settings.cost_per_location.to_s
      expect( system_settings_response[:units_per_location] ).to eql @system_settings.units_per_location
    end

    it { should respond_with 200 }
  end

  describe "POST #update" do
    context "when SystemSettings are successfully updated" do
      before(:each) do
        @user = FactoryBot.create :user
        @system_settings = FactoryBot.create :system_setting
        api_authorization_header @user.auth_token
        patch :update, params: { id: @system_settings.id, system_settings: { cost_per_location: 650, units_per_location: 100, cost_high_value: 50 } }, format: :json
      end

      it "renders the json representation for the updated SystemSettings" do
        system_settings_response = json_response[:system_setting]
        expect( system_settings_response[:cost_per_location].to_f ).to eql 650.to_f
        expect( system_settings_response[:units_per_location] ).to eql 100
      end

      it { should respond_with 200 }
    end
  end

end
