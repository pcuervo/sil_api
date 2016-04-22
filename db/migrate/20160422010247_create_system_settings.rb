class CreateSystemSettings < ActiveRecord::Migration
  def change
    create_table :system_settings do |t|
      t.integer     :units_per_location,  :default => 50
      t.decimal     :cost_per_location,   :precision => 8, :scale => 2, :default => 0.0
      t.decimal     :cost_high_value,     :precision => 8, :scale => 2, :default => 0.0
      t.timestamps  null: false
    end
  end
end
