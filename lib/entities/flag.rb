# This is the class that handles the flag object for CTF games.
#
# Author::    Steven Davidovitz (mailto:steviedizzle@gmail.com)
# Copyright:: Copyright (c) 2006, The Nebular Gauntlet DEV team
# License::   GPL
#

class Flag < Entity
  attr_accessor :carrier, :color

  # Creates a new flag.
  # - _type_ Color of flag
  # - _image_ Image to use for flag
  # - _cMap_ Collision map for flag
  def initialize(image = nil, cMap = nil)
    super

    @color = color
    @x, @y = 0, 0
    @speed = 0
    @carrier = nil
  end

  def move(elapsedtime)
  end

  # Draws flag if there is no carrier.
  def draw
    super if @carrier.nil?
  end

  # Response on collision with another object.
  def collision_with(object)
    if object.class == Ship && @carrier.nil? && object.team != @color
      @carrier = object
      #csend($server, FLAG, PICKUP, @color, object.id)
    elsif object.team == @color
      #csend($server, FLAG, CAPTURE, @color, object.id)
    end
  end

  def dump
  end
end
