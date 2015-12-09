require 'spec_helper'

describe CheckInTransaction, type: :model do
  it { should respond_to(:entry_date) }
  it { should respond_to(:estimated_issue_date) }
  it { should respond_to(:delivery_company) }
  it { should respond_to(:delivery_company_contact) }

  it { should validate_presence_of :entry_date }

end
