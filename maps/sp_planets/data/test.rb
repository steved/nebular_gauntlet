require 'yaml'
require 'pp'

Area = Struct.new(:x, :y, :width, :height)
Flag = Struct.new(:x, :y, :type)
Spawn = Struct.new(:x, :y, :width, :height, :team)
SpawnPoint = Struct.new(:x, :y)
Entity = Struct.new(:name, :image, :x, :y, :extra)
Tileset = Struct.new(:name, :image, :firstgid, :tilewidth, :tileheight)
Layer = Struct.new(:name, :opacity, :width, :height, :tiles)
pp YAML::load(File.open("entities.yaml.1_8"))
