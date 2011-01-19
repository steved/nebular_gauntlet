# This class cycles through images in animation style.
#
# Author::    Steven Davidovitz (mailto:steviedizzle@gmail.com)
# Copyright:: Copyright (c) 2006, The Nebular Gauntlet DEV team
# License::   GPL
#

require 'lib/engine'
require 'lib/math'

class Animation
  attr_accessor :x, :y

  include NGMath

  # Creates a new animation.
  # - _object_ Ship or object that is exploding
  # - _x_  X Position
  # - _y_  Y position
  # - _images_ Images to display
  def initialize(x, y, loop, *images)
    @x, @y = x, y
    @time = -1
    @images = images
    @loop = loop
  end

  # Draws animation.
  def draw
    return if !(@time % 3)
    @displayx, @displayy = calc_display(self)
    image = @images[@time / 3]
    width_fulcrum = image.w / 2 - @object.image.w / 2
    height_fulcrum = image.h / 2 - @object.image.h / 2
    SDL::Surface.blit(image, 0, 0, 0, 0, $screen, @displayx - width_fulcrum, @displayy - height_fulcrum)
  end

  # Moves up animation timer.
  def move
    if @time < (@images.length - 1) * 3
      @time += 1
    elsif @loop
      reset
    end
  end

  # Resets timer
  def reset
    @time = -1
  end
end
