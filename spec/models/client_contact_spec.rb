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

  describe ".inventory_items" do
    before(:each) do
      @client = FactoryGirl.create :client
      @client_contact = FactoryGirl.create :client_contact
      @client.client_contacts << @client_contact
      project = FactoryGirl.create :project
      3.times do |i|
        item = FactoryGirl.create :inventory_item 
        project.inventory_items << item
      end 
      @client.projects << project
    end

    it "return an array containing inventory items belonging to client_contact" do
      items = @client_contact.inventory_items
      expect(items.count).to eq 3
    end
  end
end
