class WithdrawRequestItem < ActiveRecord::Base
  belongs_to  :withdraw_request
  belongs_to  :inventory_item
end
