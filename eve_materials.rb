# Materials
materials = [
{:id => "34", :name => "Tritanium"},
{:id => "35", :name => "Pyerite"},
{:id => "36", :name => "Mexallon"},
{:id => "37", :name => "Isogen"},
{:id => "38", :name => "Nocxium"},
{:id => "39", :name => "Zydrine"},
{:id => "40", :name => "Megacyte"},
{:id => "11399", :name => "Morphite"}
]

puts "Confiming Materials In DB"
materials.each do |mat|
	Material.create( :typeid => mat[:id], :name => mat[:name]);
end