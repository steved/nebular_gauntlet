# This is a pillbox class, which is a stationary object to fires 
# up on incoming objects.
#
# Author::    Steven Davidovitz (mailto:steviedizzle@gmail.com)
# Copyright:: Copyright (c) 2006, The Nebular Gauntlet DEV team
# License::   GPL
#

require 'lib/group'

class Pillbox < Entity
  attr_accessor :fireTimer

  # Creates new Pillbox object
  # - _image_  The image to use for the ship
  # - _cMap_   The collision used by SDL to track collisions
  def initialize(image = nil, cMap = nil)
    super

    @weapon = $weapons["basic"] 

    reset_firetimer
    @angle = 0
    @range = 200
  end

  # Moves player according to elapsedtime
  # - _elapsedtime_ Ticks since last call
  def move(elapsedtime)
    super()
    return if @state != :alive

    if $users.nil?
      if @fireTimer <= Time.now && check_range($ship)
        add_fire(self)
      end
    else
      $users.each do |user|
        if @fireTimer <= Time.now && check_range(user.ship)
          add_fire(self)
        end
      end
    end
  end

  # Calculates distance and fires upon incoming object.
  # - _object_ Object to fire upon	
  def fire(object)
    return if object.nil?

    object_x, object_y = move_object(object.angle)
    # Seems fairly accurate hitting me ~90% of the time. Turning seems to fool it, but going straight
    # it always hits
    multiplier = object.speed * 20
    x = object.x + (object_x * multiplier)
    y = object.y - (object_y * multiplier)

    @angle = calc_angle(self.x, self.y, x, y)
  end

  # Checks how far object is from pillbox
  # - _object_ Object to check range
  def check_range(object)
    return false if object.nil?

    left_x = @x - @range
    right_x = @x + @range
    top_y = @y + @range
    bottom_y = @y - @range
    if object.class == Group
      object.each do |i|
        return false if i.state == (:dead || :exploding)
        if (left_x..right_x) === i.x && (bottom_y..top_y) === i.y
          fire(i)
          return true
        end
      end
    else
      return false if object.state == (:dead || :exploding)
      if (left_x..right_x) === object.x && (bottom_y..top_y) === object.y
        fire(object)
        return true
      end
    end

    return false
  end

  def dump
    {:angle => @angle, :state => @state, :id => @id + 10}
  end
end
