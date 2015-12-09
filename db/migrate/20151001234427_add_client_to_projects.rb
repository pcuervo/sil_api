class AddClientToProjects < ActiveRecord::Migration
  def change
    add_reference :projects, :client, index: true
    add_foreign_key :projects, :clients
  end
end
