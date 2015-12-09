class CreateProjects < ActiveRecord::Migration
  def change
    create_table :projects do |t|
      t.string      :name
      t.string      :litobel_id,  default: "-" 
      t.timestamps
    end
  end
end
