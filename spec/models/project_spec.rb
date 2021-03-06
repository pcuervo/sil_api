require 'spec_helper'

RSpec.describe Project, type: :model do
  let(:project) { FactoryBot.create :project }
  subject { project }

  it { should respond_to(:name) }
  it { should respond_to(:litobel_id) }

  it { should validate_uniqueness_of(:litobel_id) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:litobel_id) }

  it { should have_and_belong_to_many(:users) }
  it { should belong_to(:client) }
  it { should have_many(:inventory_items) }

  it { should be_valid }

  describe '.destroy' do
    before(:each) do
      @project = FactoryBot.create :project
    end

    context 'destroys project if it has no inventory added' do
      before(:each) do
        @project = FactoryBot.create :project
      end

      it 'returns true if project was successfully destroyed' do
        destroyed_project = @project.destroy
        expect(Project.exists?(destroyed_project.id)).to eq false
      end

      it 'removes account executives and client users from project after destroying' do
        ae = FactoryBot.create :user
        ae.role = User::ACCOUNT_EXECUTIVE

        destroyed_project = @project.destroy
        expect(Project.exists?(destroyed_project.id)).to eq false
        expect(destroyed_project.users.count).to eq 0
      end
    end

  end

  describe '.transfer_inventory' do
    let(:project_from) { create_project_with_items(5) }
    let(:project_to) { FactoryBot.create(:project) }

    context 'when inventory is transferred successfully' do
      it 'transfers all InventoryItems from one Project to another' do
        project_from.transfer_inventory(project_to)

        expect(project_from.inventory_items.count).to eq 0
        expect(project_to.inventory_items.count).to eq 5
      end
    end
  end

  describe '.transfer_inventory_items' do
    let(:project_from) { create_project_with_items(5) }
    let(:project_to) { FactoryBot.create(:project) }
    let(:items_ids) { [project_from.inventory_items.first.id, project_from.inventory_items.last.id] }

    context 'when inventory is transferred successfully' do
      it 'transfers all InventoryItems from one Project to another' do
        project_from.transfer_inventory_items(project_to, items_ids)

        expect(project_from.inventory_items.count).to eq 3
        expect(project_to.inventory_items.count).to eq 2
      end
    end

    context 'when inventory is not transferred successfully' do
      let(:random_item) { FactoryBot.create(:inventory_item) }
      it 'raises an error when InventoryItems to transfer are not found in source Project' do
        project_from.transfer_inventory_items(project_to, [random_item.id])
        expect(project_from.inventory_items.count).to eq 5
        expect(project_to.inventory_items.count).to eq 0
      end
    end
  end
end
