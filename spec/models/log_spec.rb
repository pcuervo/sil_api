require 'spec_helper'

describe Log, type: :model do
  let(:log) { FactoryGirl.build :log }
  subject { log }

  it { should respond_to(:sys_module) }
  it { should respond_to(:action) }
  it { should respond_to(:actor_id) }

  it { should validate_presence_of :sys_module }
  it { should validate_presence_of :action }
  it { should validate_presence_of :actor_id }

  it { should belong_to :user }
end
