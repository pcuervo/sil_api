require 'spec_helper'

RSpec.describe Client, type: :model do
  let(:client){ FactoryGirl.create :client }
  subject{ client }

  it { should validate_presence_of :name }
  it { should validate_uniqueness_of :name }

  it { should have_many :client_contacts }

  describe "#client_contacts association" do
    before do
      3.times { FactoryGirl.create :client_contact, client: client }
    end

    it "destroys the associated client_contacts on self destruct" do
      client_contacts = client.client_contacts
      client.destroy

      client_contacts.each do |cc|
        puts cc.to_json
        expect(ClientContact.find(cc.id)).to raise_error ActiveRecord::RecordNotFound
      end
    end
  end
end
