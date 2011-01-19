# This is a mission subclass that adds
# objective functionality to maps
#
# Author::    Steven Davidovitz (mailto:steviedizzle@gmail.com)
# Copyright:: Copyright (c) 2006, The Nebular Gauntlet DEV team
# License::   GPL
#

require 'lib/map'

class Mission < Map
  attr_reader :objectives

  # Creates a new mission instance
  # - _file_ File from which to load map from
  # - _linear_ Whether or not map is linear
  def initialize(file, linear = true)
    super(file)

    suffix = "/data/mission.yaml"
    suffix += ".1_8" if RUBY_VERSION =~ /1.8/
    @mission = YAML::load(File.open(File.dirname(@filename) + suffix))

    @linear = @mission["linear"] || linear
    @objectives = @mission["objectives"]

    # Types of objectives
    # "tile" for if object.x/y == x,y is inside tile(x, y)

    load_map
  end

  # Checks whether objective has been hit
  # - _obj_ If non-linear deletes objective
  def hit_objective(obj)
    @objectives.delete(obj)

    if @objectives.empty?
      change_state(MissionEnd.new, @mission["next"])
    end
  end

  # Checks each objective to see if it has been fulfilled
  def check_objs
    return if @objectives.empty?

    if @linear
      hit_objective(@objectives[0]) if tile($ship.x, $ship.y) == tile(@objectives[0].x, @objectives[0].y)
    else
      @objectives.each do |obj|
        hit_objective(obj) if tile($ship.x, $ship.y) == tile(obj.x, obj.y)
      end
    end
  end
end
