require 'spec_helper'

class UserLog
  include Loggable
end

describe Loggable do 
  let(:user_log) { UserLog.new }
  subject { user_log }

  describe "#log_action" do
    before do
      @admin = FactoryBot.create :user
      @new_user = FactoryBot.create :user
    end

    it "returns true when the user created was logged" do
      expect(user_log.log_action(@admin.id, 'User', 'Create', @new_user.id)).to eq (true)
    end

  end
end