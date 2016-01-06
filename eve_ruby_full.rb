require 'mongo_mapper'
require 'nokogiri'
require 'open-uri'
require 'active_support'
MongoMapper.connection = Mongo::Connection.new('localhost')
MongoMapper.database = 'rbtest'

I18n.enforce_available_locales = false

# Schema & Model
require '/var/ruby_web/eve/eve_schema'

# Inserts should be uncommented for FIRST RUN ONLY
# Leaving it uncommented may overwrite existing data
## Insert all items into the database
#require './eve_materials'
#require './eve_items'
#require './eve_recipes'

# Test find
list = Array.new
Material.all.each do |material|
	list.push material.typeid
end

items = Array.new
Item.all.each do |itm|
	items.push itm.typeid
	itm.recipe.each do |rec|
		puts "Item: #{Item.find_by_id(rec.item_id).typeid} Material: #{Material.find_by_id(rec.material_id).typeid} Quantity: #{rec.quantity}"
	end
end


path = 'typeid=' + list.join('&typeid=')
path = path + '&typeid=' + items.join('&typeid=') unless items.length == 0

puts path

#XML
url = 'http://api.eve-central.com/api/marketstat?'
types = path
resources = '&regionlimit=10000036&regionlimit=10000033&regionlimit=10000052&regionlimit=10000016&regionlimit=10000043&regionlimit=10000002'
full_url = url + types + resources
doc = Nokogiri::HTML(open(full_url))

doc.xpath('//evec_api/marketstat/type').each do |type|
entry = Hash.from_xml(type.to_xml)
	entry = entry["type"]
	id = entry["id"]

	record = list.include?(id) ? Material.find_by_typeid(id) : Item.find_by_typeid(id)

	record.history.push History.new(
		:timestamp   => DateTime.now,
		:volume     => entry["sell"]["volume"],
		:avg        => entry["sell"]["avg"],
		:min        => entry["sell"]["min"],
		:max        => entry["sell"]["max"],
		:stddev     => entry["sell"]["stddev"],
		:median     => entry["sell"]["median"],
		:percentile => entry["sell"]["percentile"]
		)
	record.save
end

Material.all.each do |record|
	puts 'ID: ' + record.typeid + ' History Entries: ' + String(record.history.length)
end
Item.all.each do |record|
	puts 'ID: ' + record.typeid + ' History Entries: ' + String(record.history.length)
end
