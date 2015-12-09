require 'spec_helper'

describe ClientContact do
  before { @client_contact = FactoryGirl.build(:client_contact) }

  it { should respond_to(:first_name) }
  it { should respond_to(:last_name) }
  it { should respond_to(:phone) }
  it { should respond_to(:phone_ext) }
  it { should respond_to(:email) }
  it { should respond_to(:business_unit) }

  it { should validate_presence_of(:first_name)}
  it { should validate_presence_of(:last_name)}
  it { should validate_presence_of(:email)}
  it { should validate_presence_of(:client)}

  it { should validate_uniqueness_of(:email)}

  it{ should belong_to :client }
end
