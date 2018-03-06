require 'spec_helper'

RSpec.describe Project, type: :model do

  let(:project){ FactoryGirl.create :project }
  subject{ project }


  it { should respond_to(:name) }
  it { should respond_to(:litobel_id) }

  it { should validate_uniqueness_of(:litobel_id) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:litobel_id) }

  it { should have_and_belong_to_many(:users) }
  it { should belong_to(:client) }
  it { should have_many(:inventory_items) }

  it { should be_valid }

  describe ".destroy" do
    before(:each) do
      @project = FactoryGirl.create :project
    end

    context "destroys project if it has no inventory added" do
      before(:each) do
        @project = FactoryGirl.create :project
      end

      it "returns true if project was successfully destroyed" do
        destroyed_project = @project.destroy
        expect( Project.exists?(destroyed_project.id) ).to eq false
      end

      it "removes project managers, account executives and client users from project after destroying" do
        pm = FactoryGirl.create :user 
        pm.role = User::PROJECT_MANAGER
        ae = FactoryGirl.create :user 
        ae.role = User::ACCOUNT_EXECUTIVE

        destroyed_project = @project.destroy
        expect( Project.exists?(destroyed_project.id) ).to eq false
        expect(destroyed_project.users.count).to eq 0
      end
    end

    context "prevents project from being destroyed because it has inventory added" do
      before(:each) do 
        @project = FactoryGirl.create :project
        inventory_item = FactoryGirl.create :unit_item
        @project.inventory_items << inventory_item
      end

      it "does not allow the project to be destroyed because it has inventroy" do
        expect(@project.destroy).to eq false
      end
    end
  end

end
