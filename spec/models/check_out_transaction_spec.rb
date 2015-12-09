require 'spec_helper'

describe CheckOutTransaction, type: :model do
  it { should respond_to(:exit_date) }
  it { should respond_to(:estimated_return_date) }
  it { should respond_to(:pickup_company) }
  it { should respond_to(:pickup_company_contact) }

  it { should validate_presence_of :exit_date }

end
