class Material
	include MongoMapper::Document
	key :typeid, String, :unique => true, :required => true
	key :name, String

	many :history
end

class History
	include MongoMapper::EmbeddedDocument
	
	key :timestamp, Time
	key :volume, Integer
	key :avg, Float
	key :max, Float
	key :min, Float
	key :stddev, Float
	key :median, Float
	key :percentile, Float
end

class Item
	include MongoMapper::Document
	key :typeid, String, :unique => true, :required => true
	key :name, String
	key :quantity, Integer

	many :history
	many :recipe

	before_create :init
	def init
		self.quantity ||= 1
	end
end

# Recipes are all made with only the material list [recipes are not complex]
class Recipe
	include MongoMapper::Document
	
	key :item_id, ObjectId
	key :material, ObjectId
  #key :metial, ObjectId
	#belongs_to :item, :required => true
	#one :material, :required => true
	key :quantity, Integer

	validates_uniqueness_of :item_id, scope: :material_id

	before_create :init
	def init
		self.quantity ||= 0
	end
end

# Not a schema but a hash for pivoting materials since they are pretty specific at this point
AllMaterials = {
        :tritanium => "34",
        :pyerite   => "35",
        :mexallon  => "36",
        :isogen    => "37",
        :nocxium   => "38",
        :zydrine   => "39",
        :megacyte  => "40",
        :morphite  => "11399"
}
