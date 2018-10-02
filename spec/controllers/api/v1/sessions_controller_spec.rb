require 'spec_helper'

describe Api::V1::SessionsController do
	describe "POST #create" do
		let(:user) { FactoryBot.create(:user) }

		context "when the credentials are correct" do
			let(:credentials) { { email: user.email, password: "holama123" } }
			before(:each){ post :create, params: { session: credentials } }

			it "returns the user record corresponding to the given credentials" do
				user.reload
				expect(json_response[:user][:auth_token]).to eql user.auth_token
			end

			it { should respond_with 200 }
		end

		context "when the credentials are incorrect" do
			let(:credentials) { { email: user.email, password: "invalid" } }
			before(:each){ post :create, params: { session: credentials } }

			it "returns a json with an error" do
				expect(json_response[:errors]).to eql "Invalid email or password"
			end

			it { should respond_with 422 }
		end
	end

	describe "DELETE #destroy" do
		before(:each) do
			@user = FactoryBot.create :user
			sign_in @user
			delete :destroy, params: { id: @user.auth_token }
		end

		it { should respond_with 204 }
	end
end
