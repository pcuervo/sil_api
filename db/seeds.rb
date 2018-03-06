# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

if SystemSetting.count == 0
  SystemSetting.create( :units_per_location => 50, :cost_per_location => 500.00, :cost_high_value => 100.00 )
end

if ItemType.count == 0 
  ItemType.create( name: 'Laptop')
  ItemType.create( name: 'Desktop')
  ItemType.create( name: 'Impresora')
  ItemType.create( name: 'Celular')
  ItemType.create( name: 'Pantalla')
  ItemType.create( name: 'POP')
  ItemType.create( name: 'POS')
  ItemType.create( name: 'Promocional')
  ItemType.create( name: 'Mobiliario')
  ItemType.create( name: 'Perecedero')
  ItemType.create( name: 'Dispositivos de red')
end

