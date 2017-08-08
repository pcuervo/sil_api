class ClientContact < ActiveRecord::Base
  acts_as :user
  belongs_to :client

  validates :client, presence: true

  def inventory_items in_stock_only=false
    projects = self.client.projects
    items = []
    projects.each do |project| 
      project.inventory_items.each_with_index do |item| 
        if in_stock_only
          next if item.status != InventoryItem::IN_STOCK && item.status != InventoryItem::PARTIAL_STOCK
          items.push(item)
        else
          items.push(item)
        end
      end
    end
    items
  end

  def inventory_items_id
    projects = self.client.projects
    ids = []
    projects.each do |project| 
      projects_ids = project.inventory_items.pluck(:id)
      ids = ids + projects_ids
    end
    ids
  end

  def total_high_value_items
    projects = self.client.projects
    total = 0
    projects.each do |project| 
      puts 'project '

      total = total + project.inventory_items.total_high_value_items
      puts total.to_s
    end
    total
  end

  # Get the rent of current month from all ClientContacts
  # * *Returns:* 
  #   - decimal current_rent
  def self.get_clients_current_rent
    current_rent = 0
    ClientContact.all.each do |c|
      current_rent = current_rent + c.get_rent( Time.now.month, Time.now.year )
    end

    current_rent
  end

  # Get the rent of current user by month
  # * *Params:* 
  #   - +month+ -> Number of month
  #   - +year+ ->  Year
  # * *Returns:* 
  #   - decimal rent
  def get_rent month, year
    occupied_units = self.get_occuppied_units( month, year )
    return 0 if occupied_units == 0

    return 0 if self.discount.nil?
    
    settings = SystemSetting.select(:units_per_location, :cost_per_location).first
    rounded_units = occupied_units / settings.units_per_location * settings.units_per_location + settings.units_per_location
    high_value_rent = get_high_value_rent( month, year )
    rent = rounded_units / settings.units_per_location.to_f  * settings.cost_per_location + high_value_rent
    return ( rent * self.discount ).round(2)
  end

  # Get the number of occupied space in units by month
  # * *Params:* 
  #   - +month+ -> Number of month
  #   - +year+ ->  Year
  # * *Returns:* 
  #   - integer occuppied_units
  def get_occuppied_units month, year
    rent_date = DateTime.new(year, month, 1)
    projects_ids = self.projects.pluck(:id)
    inventory_items_ids = InventoryItem.select( 'id' ).where( 'project_id IN (?)', project_ids  ).pluck(:id)
    occupied_units_current_month = WarehouseTransaction.select("to_char(created_at, 'MM-YY') as mon, sum(units) as units").where( 'concept = 1 AND inventory_item_id IN (?) and created_at BETWEEN ? AND ?', inventory_items_ids, rent_date.beginning_of_month, rent_date.end_of_month ).group('mon').order("to_char(created_at, 'MM-YY') ")
    current_month_inventory_items = WarehouseTransaction.select("inventory_item_id").where( 'concept = 1 AND inventory_item_id IN (?) and created_at BETWEEN ? AND ?', inventory_items_ids, rent_date.beginning_of_month, rent_date.end_of_month ).distinct.pluck(:inventory_item_id)

    inventory_items_ids = inventory_items_ids - current_month_inventory_items
    existing_inventory_items_units = InventoryItem.joins(:item_locations).where( 'inventory_items.id in (?) and inventory_items.created_at < ? AND status IN (?)', inventory_items_ids, rent_date.beginning_of_month, [InventoryItem::IN_STOCK, InventoryItem::PARTIAL_STOCK] ).sum(:units)

    return occupied_units_current_month.first.units + existing_inventory_items_units if occupied_units_current_month.present?

    return existing_inventory_items_units
  end

  # Get the rent for high value items in current month
  # * *Returns:* 
  #   - decimal high_value_rent
  def get_high_value_rent month, year
    projects_ids = self.projects.pluck(:id)
    inventory_items_ids = InventoryItem.select( 'id' ).where( 'project_id IN (?)', project_ids  ).pluck(:id)
    high_value_items = InventoryItem.where( 'id IN (?) AND status IN (?) AND is_high_value = ?', inventory_items_ids, [InventoryItem::IN_STOCK, InventoryItem::PARTIAL_STOCK], 1 ).count
    cost_high_value = SystemSetting.select(:cost_high_value).pluck(:cost_high_value).first

    return high_value_items * cost_high_value
  end

  # Get the past and current rent per month for all clients
  # * *Params:* 
  #   - +month+ -> Number of month
  # * *Returns:* 
  #   - integer occuppied_units
  def self.get_rent_history
    monthly_rents = []
    occupied_units_per_month = WarehouseTransaction.select("to_char(created_at, 'MM-YYYY') as month_year, sum(units) as units").where( 'concept = 1' ).group('month_year').order("to_char(created_at, 'MM-YYYY') ")

    return 0 if ! occupied_units_per_month.present?

    occupied_units_per_month.each do |o| 
      monthly_rent = {}
      month = o.month_year.split('-').first
      year = o.month_year.split('-').last
      current_month_rent = 0
      ClientContact.all.each do |c| 
        current_month_rent = current_month_rent + c.get_rent( month.to_i, year.to_i )
      end
      monthly_rent['date'] = o.month_year
      monthly_rent['rent'] = current_month_rent
      monthly_rents.push( monthly_rent )
    end

    monthly_rents
  end

  # Get the past and current rent per month for all clients
  # * *Params:* 
  #   - +month+ -> Number of month
  # * *Returns:* 
  #   - integer occuppied_units
  def get_contact_rent_history
    monthly_rents = []
    occupied_units_per_month = WarehouseTransaction.select("to_char(created_at, 'MM-YYYY') as month_year, sum(units) as units").where( 'concept = 1' ).group('month_year').order("to_char(created_at, 'MM-YYYY') ")

    return 0 if ! occupied_units_per_month.present?

    self.projects.each do |p|
      puts p.inventory_items.to_yaml
    end
    occupied_units_per_month.each do |o| 
      monthly_rent = {}
      month = o.month_year.split('-').first
      year = o.month_year.split('-').last
      current_month_rent = 0
      puts 'get_contact_rent_history'
      puts month + '/' + year
      current_month_rent = current_month_rent + self.get_rent( month.to_i, year.to_i )
      next if current_month_rent == 0
      
      monthly_rent['date'] = o.month_year
      monthly_rent['rent'] = current_month_rent
      monthly_rents.push( monthly_rent )
    end

    monthly_rents
  end

  # Get the rent of current month from all ClientContacts
  # * *Returns:* 
  #   - decimal current_rent
  def get_current_rent
    current_rent = 0
    current_rent + self.get_rent( Time.now.month, Time.now.year )
    current_rent
  end


end
