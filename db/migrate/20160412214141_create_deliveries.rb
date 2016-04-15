class CreateDeliveries < ActiveRecord::Migration
  def change
    create_table :deliveries do |t|
      t.references  :user,              index: true
      t.integer     :delivery_user_id,  null: false
      t.string      :company
      t.string      :addressee
      t.string      :addressee_phone
      t.text        :address
      t.string      :latitude
      t.string      :longitude
      t.string      :status
      t.text        :additional_comments
      t.timestamps null: false
    end
    add_foreign_key :deliveries, :users
  end
end
