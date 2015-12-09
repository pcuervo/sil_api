require 'spec_helper'

describe User do
  before { @user = FactoryGirl.build(:user) }

  subject { @user }

  it { should respond_to(:first_name) }
  it { should respond_to(:last_name) }
  it { should respond_to(:role) }
  it { should respond_to(:email) }
  it { should respond_to(:password) }
  it { should respond_to(:password_confirmation) }

  it { should validate_presence_of(:first_name) }
  it { should validate_presence_of(:last_name) }
  it { should validate_inclusion_of(:role).in_array([1, 2, 3]) }
	it { should validate_uniqueness_of(:email) }
	it { should validate_confirmation_of(:password) }
	it { should allow_value('example@domain.com').for(:email) }

  it { should be_valid }

  # test the user actually respond to this attribue
  it { should respond_to( :auth_token ) }

  # test the auth_token is unique
  it { should validate_uniqueness_of( :auth_token )}

  describe "#generate_authentication_token!" do
    it "generates a unique token" do
      allow(Devise).to receive(:friendly_token).and_return("auniquetoken123")
      @user.generate_authentication_token!
      expect(@user.auth_token).to eql "auniquetoken123"
    end

    it "generates another token when one already has been taken" do
      existing_user = FactoryGirl.create( :user, auth_token: "auniquetoken123" )
      @user.generate_authentication_token!
      expect( @user.auth_token ).not_to eql existing_user.auth_token
    end
  end

  it { should have_many(:inventory_items) }
  it { should have_and_belong_to_many(:projects) }
  it { should have_many(:logs) }

end
