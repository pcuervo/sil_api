class DeliveryRequests < ActiveRecord::Migration
  def change
    create_table :delivery_requests do |t|  
      t.references  :user,              index: true
      t.string      :company
      t.string      :addressee
      t.string      :addressee_phone
      t.text        :address
      t.string      :latitude
      t.string      :longitude
      t.text        :additional_comments
      t.timestamps  null: false
    end
    add_foreign_key :delivery_requests, :users
  end

end
