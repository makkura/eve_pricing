class User
	include MongoMapper::Document
	key :username, String, :required => true, :unique => true
	key :password, String
	key :role, String


	def update_password(salt, password)

	end

end


