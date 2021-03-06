# The Entity class is used to represent a generic object in Nebular Gauntlet.
# It handles the basic state of the ship and its attributes, along with the
# display on screen using the game Engine.
#
# Author::    Steven Davidovitz (mailto:steviedizzle@gmail.com)
# Copyright:: Copyright (c) 2006, The Nebular Gauntlet DEV team
# License::   GPL
#

require 'lib/engine'
require 'lib/math'
require 'lib/network'
require 'lib/animation'
require 'lib/constants'

class Entity
  include NGMath
  include Network
  include Constants
  include Core

  attr_accessor :x, :y, :displayx, :displayy, :state, :last_state, :cMap, :angle, :image,
    :speed, :height, :width, :weapon, :id, :damage_modifier


  # Creates a new entity to use in Nebular Gauntlet.
  # - _screen_ The generic display
  # - _map_    the map
  # - _image_  The image to use for the ship
  # - _cMap_   The collision used by SDL to track collisions
  def initialize(image = nil, cMap = nil, weapon = nil)
    @cMap = cMap if cMap
    @weapon = weapon if weapon

    if image
      @image = image
      @height, @width, = image.h, image.w
    end

    @angle = 360
    @speed = 3
    @friction = 0.99
    @state = :alive # Valid values for state can be :alive :exploding :dead
    @id = 0
    @collision_effect = nil
    @damage_modifier = 0
  end


  # Defines whether or not the player is moving.
  def move
    if @state == :exploding && $users
      @explosion.move
    end
  end


  # Implements the actual movement on the screen for the enduser.
  def draw
    return if @state == :dead
    @displayx, @displayy = self != $ship ? calc_display(self) : calc_display()

    case @state
    when :alive
      width_fulcrum = @image.w / 2
      height_fulcrum = @image.h / 2
      SDL::Surface.transform_blit(@image, $screen, @angle, 1.0, 1.0, width_fulcrum,
                        height_fulcrum, @displayx + width_fulcrum,
                        @displayy + height_fulcrum, 1)
    when :exploding
      explode if !@explosion
      @explosion.move
      @explosion.draw
    end

    if @collision_effect
      @collision_effect.move
      @collision_effect.draw
    end
  end


  # Defines the action to perform when a collision occurs
  # between two objects.
  # - _object_ The remote object we are colliding into.
  def collision_with(object)
    if !(object.class == Weapon && object.ship == self) && !object.is_a?(Powerup) 
      explode  
      @health = 0
      @shield = 0
    end
  end

  # Causes a ship to explode.
  def explode
    return if @state == :dead
    @speed = 0
    @state = :exploding
    @explosion = ParticleSystem.new(@x, @y, 250, 0.25, 360, 0, [Proc.new {|x| x.state = :dead}, self])
    play_sound("explosion")
  end

  def weapon=(weapon) 
    @weapon = $weapons[weapon] || $ship.weapon 
  end 

  # Checks for collision between two objects using SGE's collision maps
  def collide?(object2)
    if (@state == :alive && object2.state == :alive) && (@cMap && object2.cMap)
      @cMap.collision_check(@x, @y, object2.cMap, object2.x, object2.y) != nil # Returns true/false
    elsif (!@cMap || object2.cMap)
      # XXX No longer in
      #SDL::CollisionMap.boundingBoxCheck(@x, @y, @width, @height, object2.x, object2.y, object2.width, object2.height)
    end
  end

  def weapon_hit(object)
    shield_dmg = rand(object.damage + object.ship.damage_modifier)
    if shield_dmg > @shield 
      @shield = 0
      shield_dmg = 0
    else
      @shield -= shield_dmg
    end
    @health -= object.damage + object.ship.damage_modifier - shield_dmg
    if @health <= 0
      @health = 0
      explode
    end
    @collision_effect = ParticleSystem.new(object.x, object.y, 25, 0.5, 360, 0, [Proc.new {|x| x = nil}, @collision_effect])
    play_sound("explosion2")
  end

  # Dump state for network sending
  def dump
    {:angle => @angle, :x => @x, :y => @y, :speed => @speed, :id => @id + 10, :state => @state}
  end

  def reset_firetimer
    @fireTimer = Time.now + @weapon["reload"]
  end
end
