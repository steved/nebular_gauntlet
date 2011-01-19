# This module simplifies some of the common
# math operations used in the game
#
# Author::    Steven Davidovitz (mailto:steviedizzle@gmail.com)
# Copyright:: Copyright (c) 2006, The Nebular Gauntlet DEV team
# License::   GPL
#

module NGMath
  require 'mathn'

  # Convert radians to degrees
  # - _radians_ Radians to convert
  def to_degrees(radians) 
    radians * 57.2957 # Hardcoded (180/Math::PI)
  end

  # Convert to radians
  # - _degrees_ Degrees to convert
  def to_radians(degrees) 
    degrees * 0.0174533 # Hardcoded (Math::PI/180)
  end

  # Rotates angle according to options
  # - _angle_ Starting angle to rotate
  # - _direction_ Direction which to rotate
  # - _rotationAmount_ Amount to rotate every call
  def rotate(angle, direction, rotationAmount)
    temp_angle = angle
    temp_angle -= rotationAmount if direction == :left
    temp_angle += rotationAmount if direction == :right
    temp_angle %= 360
  end

  # Moves object according to game logic
  # - _angle_ Angle which to return vector for
  def move_object(angle) 	
    theta = to_radians(angle) # Angle must be in radians

    return Math.sin(theta), Math.cos(theta)
  end

  # Calculates display position of object
  # - _object_ Ship object
  def calc_display(object = nil)
    center = $ship.state != :alive ? $camera : $ship
    halfw = $screen.w / 2
    halfh = $screen.h / 2

    if object.nil?
      temp_x, temp_y = center.x, center.y
      if temp_x > halfw
        temp_x = $screen.w - ($map.w - center.x)
        if center.x < $map.w - halfw
          temp_x = halfw
        end
      end
      if temp_y > halfh
        temp_y = $screen.h - ($map.image.h - center.y)
        if center.y < $map.image.h - halfh
          temp_y = halfh
        end
      end
    else
      temp_x = object.x - (center.x - center.displayx)
      temp_y = object.y - (center.y - center.displayy)
    end

    return temp_x, temp_y
  end

  # Calculates background screen position
  def calc_back_pos(obj)
    backx = obj.x - ($screen.w / 2)
    backx = 0 if backx < 0
    backx = $map.image.w - $screen.w if backx > $map.image.w - $screen.w

    backy = obj.y - ($screen.h / 2)
    backy = 0 if backy < 0
    backy = $map.image.h - $screen.h if backy > $map.image.h - $screen.h

    return backx, backy
  end

  # Calculates angle between 2 points
  def calc_angle(x1, y1, x2, y2)
    90 + to_degrees(Math.atan2(y2 - y1, x2 - x1))
  end

  # Calculate distance between two points
  def calc_dist(x1, y1, x2, y2)
    Math.hypot(x2 - x1, y2 - y1)
  end

  # Calculate which side of object to rotate to face other object
  def line_of_sight(object1_angle, object2_angle)
    ia = object1_angle - 180
    ia %= 360 if ia < 0

    a = object1_angle - (object1_angle > 180 ? 360 : 0)
    ea = object2_angle - (object2_angle >= ia ? 360 : 0)

    (([a, ia].min)..([a, ia].max)).include?(ea) ? :right : :left
  end
end	
