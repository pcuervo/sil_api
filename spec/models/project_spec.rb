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

end
