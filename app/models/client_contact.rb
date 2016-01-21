class ClientContact < ActiveRecord::Base
  acts_as :user
  belongs_to :client

  validates :client, presence: true

  def inventory_items
    projects = self.client.projects
    items = []
    projects.each do |project| 
      project.inventory_items.each_with_index { |item| items.push(item)}
    end
    items
  end
end
