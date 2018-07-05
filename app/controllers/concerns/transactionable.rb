module Transactionable

  def log_checkin_transaction entry_date, inventory_item_id, concept, estimated_issue_date, additional_comments, delivery_company, delivery_company_contact, quantity, folio

    checkin_transaction = CheckInTransaction.new( :inventory_item_id => inventory_item_id, :concept => concept, :additional_comments => additional_comments, :entry_date => entry_date, :estimated_issue_date => estimated_issue_date, :delivery_company => delivery_company, :delivery_company_contact => delivery_company_contact, :quantity => quantity, :folio => folio)
    checkin_transaction.save!
  end  

  def log_checkout_transaction exit_date, inventory_item_id, concept, estimated_return_date, additional_comments, pickup_company, pickup_company_contact, quantity

    checkin_transaction = CheckOutTransaction.new( :inventory_item_id => inventory_item_id, :concept => concept, :additional_comments => additional_comments, :exit_date => exit_date, :estimated_return_date => estimated_return_date, :pickup_company => pickup_company, :pickup_company_contact => pickup_company_contact, :quantity => quantity )
    return checkin_transaction.save!

  end  
  
end