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
  ItemType.create('Laptop')
  ItemType.create('Desktop')
  ItemType.create('Impresora')
  ItemType.create('Celular')
  ItemType.create('Pantalla')
  ItemType.create('POP')
  ItemType.create('POS')
  ItemType.create('Promocional')
  ItemType.create('Mobiliario')
  ItemType.create('Perecedero')
  ItemType.create('Dispositivos de red')
end

