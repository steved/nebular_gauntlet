# Entity grouping class based on Array.
#
# Author::    Steven Davidovitz (mailto:steviedizzle@gmail.com)
# Copyright:: Copyright (c) 2006, The Nebular Gauntlet DEV team
# License::   GPL
#

require 'lib/engine'

class Group < Array
  include Core

  # Initializes new group.	
  def initialize
    super

    @score = 0
  end

  # Calls method _draw_ on objects.
  def draw
    self.each do |i|
      i.draw if !i.nil?
    end
  end

  # Calls method _move_ on objects.
  # - _elapsedtime_ Elapsed ticks since last call
  def move(elapsedtime)
    self.each do |i|
      i.move(elapsedtime)
    end
  end

  # Collides all objects with specified.
  # - _object_ Object colliding with Group
  def collide_with(object)
    if object.is_a?(Group)
      self.each do |i|
        object.each do |x|
          next if (i.nil? || x.nil?) || (i == x)
          if i.collide?(x)
            i.collision_with(x)
            x.collision_with(i)
          end if x.state == :alive && i.state == :alive 
        end
      end
    else
      self.each do |i|
        next if i.nil?
        if i.collide?(object)
          i.collision_with(object)
          object.collision_with(i)
        end if object.state == :alive && i.state == :alive
      end
    end
  end
end
