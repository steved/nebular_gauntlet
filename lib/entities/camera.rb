# Camera class to view map and track entities.
# 
# Author::    Steven Davidovitz (mailto:steviedizzle@gmail.com)
# Copyright:: Copyright (c) 2006, The Nebular Gauntlet DEV team
# License::   GPL
#


require 'lib/entity'

class Camera < Entity
  attr_accessor :active

  # Create a new Camera instance
  def initialize(track = nil)
    @tracking = track
    @x, @y = $map.w / 2, $map.h / 2
    @displayx, @displayy = @x, @y
    @speed = 3
  end

  # Track a specific object
  # - _object_ Object to track
  def track(object)
    @tracking = object
  end

  # Focus on an object but don't track
  # - _object_ Object to focus on
  def focus(object)
    @x, @y = object.x, object.y
    @displayx, @displayy = calc_display
  end
  
  def unfocus
    @tracking = nil
  end

  def draw
    @displayx, @displayy = calc_display
    backx, backy = calc_back_pos(self)
    SDL::Surface.blit($map.image, backx, backy, $screen.w, $screen.h, $screen, 0, 0) 
  end

  def move(elapsedtime, key)
    if @tracking.nil?
      key.each do |k|
        case k
        when SDL::Key::UP
          @y -= 10
        when SDL::Key::DOWN
          @y += 10
        when SDL::Key::LEFT
          @x -= 10
        when SDL::Key::RIGHT
          @x += 10
        end
      end
    end

    @x = $screen.w / 2 if @x < $screen.w / 2
    @y = $screen.h / 2 if @y < $screen.h / 2
    @x = $map.w - ($screen.w / 2) if @x > $map.w - ($screen.w / 2)
    @y = $map.h - ($screen.h / 2) if @y > $map.h - ($screen.h / 2)
  end
end
