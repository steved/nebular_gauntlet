# This is a map class that parses
# and renders a TMX (xml) file
#
# Author::    Steven Davidovitz (mailto:steviedizzle@gmail.com)
# Copyright:: Copyright (c) 2006, The Nebular Gauntlet DEV team
# License::   GPL
#

require 'lib/engine'
require 'lib/math'
require 'enumerator' # For each_slice

class Map < Engine
  include NGMath

  attr_reader :image, :cMap, :state, :x, :y, :height, :width, :name, :config, :tile_width, :tile_height
  alias :h :height
  alias :w :width

  # Create a new map instance
  # - _file_ TMX File from which to load
  def initialize(file)
    @name = file.split("/")[-1].split(".")[0]
    @filename = file
    @map_file = YAML::load(File.open(@filename))["map"]
    
    suffix = "/data/entities.yaml"
    suffix += ".1_8" if RUBY_VERSION =~ /1.8/
    @config = YAML::load(File.open(File.dirname(@filename) + suffix))

    @x = @y = 0

    @tilesets = []

    @state = :alive # For collision compat

    @solids = [] # Array of solid tiles

    @spawns = [] # Spawn points

    # Variable for holding variables
    @layers = []

    @tile_width = @tile_height = 16
  end

  # Loads basic map attributes
  def load_map
    # Get height and width in tiles
    @map_width = @map_file["width"]
    @map_height = @map_file["height"]

    # Get tilewidth and height
    @tilewidth = @map_file["tilewidth"]
    @tileheight = @map_file["tileheight"]

    # Set width/height
    @width = @map_width * @tilewidth
    @height = @map_height * @tileheight
  end

  # Loads tilesets and rows
  def load_tiles
    if @map_file["tilesets"]
      @map_file["tilesets"].each do |name, values|
        srccolorkey = @config["settings"]["srccolorkey"].delete(",").split.map {|x| x.to_i} if @config["settings"]["srccolorkey"]
        image = load_image(File.dirname(@filename) + "/images/" + values["image"].split("/")[-1], false, srccolorkey || [0, 0, 0])
        @tilesets << Struct::Tileset.new(name, image, values["firstgid"], values["tilewidth"], values["tileheight"])
      end
      @tilesets.sort! {|a,b| a.firstgid <=> b.firstgid}
    end

    if @map_file["layers"]
      @map_file["layers"].each do |name, values|
        @layers << Struct::Layer.new(name, values["opacity"], values["width"], values["height"], values["data"])
      end
    end

    @background = load_image(File.dirname(@filename) + "/images/" + @map_file["background"]) if @map_file["background"]

    @tiles = []
    (0..@height - 1).each_slice(@tile_height) do |y|
      x_tiles = []
      (0..@width - 1).each_slice(@tile_width) do |x|
        x_tiles << Struct::Tile.new(x[0], y[0], @tile_width, @tile_height)
      end
      @tiles << x_tiles
    end

    @image = SDL::Surface.new(SDL::HWSURFACE, @width, @height, $screen)
    @image.put(@background, 0, 0) if @map_file["background"]
  end

  # Renders tiles on map surface
  def render
    load_tiles
    puts "Starting render"
    @layers.each do |layer|
      (0..layer.height - 1).each do |y|
        (0..layer.width - 1).each do |x|
          tile = layer.tiles[y][x]

          if tile == 0
            next
          elsif tile > 0
            ttileset = nil
            @tilesets.each do |tileset|
              ttileset = tileset if ttileset.nil?
              if tile >= tileset.firstgid
                ttileset = tileset
              end
            end
            tile -= ttileset.firstgid
            yimage = tile % (ttileset.image.w / @tilewidth)
            ximage = (tile - yimage) / (ttileset.image.h / @tileheight)
            SDL::Surface.blit(ttileset.image, yimage * ttileset.tilewidth, ximage * ttileset.tileheight, ttileset.tilewidth, ttileset.tileheight, @image, x * ttileset.tilewidth, y * ttileset.tileheight)
          end
        end
      end
    end

    @cMap = @image.make_collision_map

    # Set all the solid tiles...
    @cMap.clear(0, 0, @image.w, @image.h) # Clear the whole map

    @config['solid'].each do |solid|
      @cMap.set(solid.x, solid.y, solid.width, solid.height)
      @image.draw_rect(solid.x, solid.y, solid.width, solid.height, [255, 255, 255])
    end

    @image.set_color_key(SDL::RLEACCEL, @image.colorkey)
    @image = @image.displayFormatAlpha
  end

  def collide?(object)
    @config['solid'].each do |solid|
      return true if SDL::CollisionMap.boundingBoxCheck(solid.x, solid.y, solid.width, solid.height, object.x, object.y, object.width, object.height)
      # XXX
    end
    false
  end

  def collision_with(obj)
  end

  def tile(x, y)
    tile = @tiles[(y / @tile_height).to_i][(x / @tile_width).to_i]
    if tile.nil?
      raise "No tile at #{x}, #{y}"
    else
      tile
    end
  end
end
