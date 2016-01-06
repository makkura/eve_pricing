require 'rubygems'
require 'sinatra'
require 'mongo_mapper'

require 'haml'
require 'sass'

require 'json'


## Simple User Control
#enable :sessions
#require './user_schema.rb'


## Database
# Schema and Model
require './eve_schema.rb'

# Database Selection
configure do
	MongoMapper.database = 'rbtest'
end

## Routes
get '/test' do
	@materials = Material.all
	erb :materials, :layout => false
end

get '/materials'  do
	@title = "Materials"
	@list = Material.all
	p @list
	erb :grouplist
end

get '/items' do
	@title = "Items Information (Each 1)"
	@list = Item.all
	@prices = {}
	@list.each do |item|
		@prices[item.typeid] = 0
		total = 0
		materials = Material.all
        	materials.each do |mat|
                	rec = item.recipe.find_by_material_id(mat.id)
                	if !rec.nil? and rec.quantity > 0
                	       	mat = Material.find_by_id(rec.material_id)
	        	        price = rec.quantity * mat.history.last.avg
                	        total = total + price
                	end
	   	end
		# We have the total price, divide it out to 1 unit
		@prices[item.typeid] = total / item.quantity
	end

	#erb :grouplist
	erb :itemlist
end

get '/items/new' do
	erb :new_item
end

post '/items/new', :provides => :json do
        data = JSON.parse(request.body.read.to_s)
        # item data
        new_id = data["id"].strip
        new_name = data["name"].strip
        new_quantity = data["quantity"].strip

	item = Item.find_by_typeid(new_id)
	if !item.nil?
		return { "Error" => "TypeID Already In Use!" }.to_json
	else
		item = Item.create({ :typeid => new_id, :name => new_name, :quantity => new_quantity })
		item.save
		return { "Success" => "Redirect" }.to_json
		#redirect to("/items/manage/#{item.typeid}")
	end
end

post '/items/delete/:id' do |id|
	item = Item.find_by_typeid(id)
	temp_id = item.id
	Recipe.where(:item_id => temp_id).destroy_all
	item.destroy

	return { "Success" => "Record Removed" }.to_json
end

get '/items/manage/:id' do |id|
	@item = Item.find_by_typeid(id)

	redirect to('../') unless @item

	@recipe = {}
	# Quick fill of 0 to default them
	AllMaterials.each do |key, val|
		@recipe[key] = 0
	end

	for recipe in @item.recipe
		@recipe[:tritanium] = recipe.quantity if Material.find_by_id(recipe.material_id).typeid == AllMaterials[:tritanium]
		@recipe[:pyerite]   = recipe.quantity if Material.find_by_id(recipe.material_id).typeid == AllMaterials[:pyerite]
		@recipe[:mexallon]  = recipe.quantity if Material.find_by_id(recipe.material_id).typeid == AllMaterials[:mexallon]
		@recipe[:isogen]    = recipe.quantity if Material.find_by_id(recipe.material_id).typeid == AllMaterials[:isogen]
		@recipe[:nocxium]   = recipe.quantity if Material.find_by_id(recipe.material_id).typeid == AllMaterials[:nocxium]
		@recipe[:zydrine]   = recipe.quantity if Material.find_by_id(recipe.material_id).typeid == AllMaterials[:zydrine]
		@recipe[:megacyte]  = recipe.quantity if Material.find_by_id(recipe.material_id).typeid == AllMaterials[:megacyte]
		@recipe[:morphite]  = recipe.quantity if Material.find_by_id(recipe.material_id).typeid == AllMaterials[:morphite]
	end
	
	erb :manage_item
end

post '/items/manage/:id', :provides => :json do |id|
	data = JSON.parse(request.body.read.to_s)
	# item data
	new_id = data["id"].strip
	new_name = data["name"].strip
	new_quantity = data["quantity"].strip
	# material data
	tritanium = data["tritanium"].strip
	pyerite = data["pyerite"].strip
	mexallon = data["mexallon"].strip
	isogen = data["isogen"].strip
	nocxium = data["nocxium"].strip
	zydrine = data["zydrine"].strip
	megacyte = data["megacyte"].strip
	morphite = data["morphite"].strip

	item = Item.find_by_typeid(id)
	# Confirm new ID is good
	if item.typeid != new_id
		new_item = Item.find_by_typeid(new_id)
		if !new_item.nil?
			# This item exists, do not save
			return { "Error" => "New Item ID Already Exists" }.to_json
		end
	end

	item.name = new_name || item.name
	item.typeid = new_id || item.typeid
	item.quantity = new_quantity || item.quantity
	item.save

	AllMaterials.each do |key, val|
		found = false
		for recipe in item.recipe
			if Material.find_by_id(recipe.material_id).typeid == val
				found = true
				break
			end		
		end
		if !found
			mat = Material.find_by_typeid(val)
			item.recipe.push Recipe.create( :item_id => item.id, :material_id => mat.id, :quantity => 0 )
		end
	end

	for recipe in item.recipe
		recipe.quantity = tritanium if Material.find_by_id(recipe.material_id).typeid == AllMaterials[:tritanium]
                recipe.quantity = pyerite   if Material.find_by_id(recipe.material_id).typeid == AllMaterials[:pyerite]
                recipe.quantity = mexallon  if Material.find_by_id(recipe.material_id).typeid == AllMaterials[:mexallon]
                recipe.quantity = isogen    if Material.find_by_id(recipe.material_id).typeid == AllMaterials[:isogen]
                recipe.quantity = nocxium   if Material.find_by_id(recipe.material_id).typeid == AllMaterials[:nocxium]
                recipe.quantity = zydrine   if Material.find_by_id(recipe.material_id).typeid == AllMaterials[:zydrine]
                recipe.quantity = megacyte  if Material.find_by_id(recipe.material_id).typeid == AllMaterials[:megacyte]
                recipe.quantity = morphite  if Material.find_by_id(recipe.material_id).typeid == AllMaterials[:morphite]
		recipe.save
	end
	
	return data.to_json
end

get '/history/:id' do |id|
	# Get the indicated material or item
	#material = Material.where(:typeid => id).first

	lookup = Material.find_by_typeid(id) || Item.find_by_typeid(id)	

	# Get the History list
	histories = lookup.history

	# Create a list of each stat being tracked
	@data = 
	{
		:volume => { :name => "Volume", :data => Array.new}, 
		:avg => { :name => "Average", :data => Array.new},
		:max => { :name => "Max", :data => Array.new},
		:min => { :name => "Min", :data => Array.new},
		:stddev => { :name => "StdDev", :data => Array.new},
		:median => { :name => "Median", :data => Array.new},
		:percentile => { :name => "Percentile", :data => Array.new}
	}

	histories.each do |entry|
		# alter timestamp for a more local time
		cst_time = entry.timestamp.localtime("-06:00")
		# alter timestamp visible formatting
		cst_time = cst_time.strftime "%Y-%m-%d %H:%M:%S"

		@data[:volume][:data].push( { :timestamp => cst_time, :data => entry.volume } )
		@data[:avg][:data].push( { :timestamp => cst_time, :data => entry.avg } )
		@data[:max][:data].push( { :timestamp => cst_time, :data => entry.max } )
		@data[:min][:data].push( { :timestamp => cst_time, :data => entry.min } )
		@data[:stddev][:data].push( { :timestamp => cst_time, :data => entry.stddev } )
		@data[:median][:data].push( { :timestamp => cst_time, :data => entry.median } )
		@data[:percentile][:data].push( { :timestamp => cst_time, :data => entry.percentile } )
	end

	erb :history
end

get '/price/:id' do |id|
	@item = Item.find_by_typeid(id)
	@title = @item.name
	@current_average = @item.history.last.avg * @item.quantity

	@total = 0
	@list = []
	materials = Material.all
	materials.each do |mat|
		entry = {}

		rec = @item.recipe.find_by_material_id(mat.id)
		if rec.quantity > 0
			mat = Material.find_by_id(rec.material_id)
			entry[:name] = mat.name
			entry[:average] = mat.history.last.avg
			entry[:quantity] = rec.quantity
	
			price = rec.quantity * mat.history.last.avg
			entry[:price] = price
			@total = @total + price
			@list.push entry
		end
	end
	
	erb :price
end

get '/quote' do
	# Prepare a list of price information and a smaller list of just the item names
	@item_details = {}
	@item_names = []
	Item.all.each do |item|
		# handle items without history
		if item.history.nil? or item.history.length == 0
			@item_names.push item.name
			
			@item_details[item.name] = {}
			@item_details[item.name]["purchase"] = 0
			@item_details[item.name]["build"] = 0
			@item_details[item.name]["quantity"] = 1
			next
		end

			
        	total = 0
        	materials = Material.all
        	materials.each do |mat|
                	entry = {}

                	rec = item.recipe.find_by_material_id(mat.id)
			if !rec.nil? and rec.quantity > 0
                        	mat = Material.find_by_id(rec.material_id)
                        	price = rec.quantity * mat.history.last.avg
                        	total = total + price
                	end
        	end

		@item_names.push item.name
		@item_details[item.name] = {}
		@item_details[item.name]["purchase"] = "%.2f" % item.history.last.avg * item.quantity
		@item_details[item.name]["build"] = "%.2f" % total
		@item_details[item.name]["quantity"] = item.quantity
	end
	@item_names.sort_by! { |name| name.downcase }

	erb :quote
end

get '/' do
	redirect to ('/quote')
	#erb :index
end
