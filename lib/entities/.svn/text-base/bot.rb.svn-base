# This is the bot class controlled by custom AI.
#  
# Author::    Steven Davidovitz (mailto:steviedizzle@gmail.com)
# Copyright:: Copyright (c) 2006, The Nebular Gauntlet DEV team
# License::   GPL
#

class Bot < Entity
  attr_accessor :fireTimer, :team, :health, :shield

  def initialize(image = nil, cMap = nil)
    super(image, cMap)

    @speed = 1.5
    @team = nil

    @weapon = $ship.weapon if !$ship.nil?
    reset_firetimer

    # Attributes
    @health = 100
    @shield = 0

    @xd, @yd = move_object(@angle)
  end

  def fire
    if @fireTimer <= Time.now
      add_fire(self)
    end
  end 

  # Find the closest enemy from a specific set.
  def find_enemies
    enemies = $entities.select{|x| (x.is_a?(Bot) || x.is_a?(Pillbox)) && x != self}
    if $ships
      $ships.each {|x| enemies << x}
    else
      enemies << $ship
    end

    enemies.each do |enemy|
      next if enemy.nil? || enemy.state == :dead

      distance = calc_dist(@x, @y, enemy.x, enemy.y)
      #if enemies.select{|x| next if enemy.nil?; x.state != :dead}.length == 1 || (@closest_enemy && @closest_enemy.state == :dead) || !@closest_enemy || distance < @closest_enemy_distance
        @closest_enemy = enemy
        @closest_enemy_distance = distance
        @closest_enemy_angle = calc_angle(@x, @y, @closest_enemy.x, @closest_enemy.y).to_i % 360
      #end
    end
  end

  def move(elapsedtime)
    super()
    return if @state != :alive

    @x = 0 if @x <= 0
    @y = 0 if @y <= 0
    @x = $map.w - @image.w if @x >= $map.w - @image.w
    @y = $map.h - @iamge.h if @y >= $map.h - @image.h

    angle_rot = 8 * (elapsedtime / 20)
    find_enemies
    if @closest_enemy_distance > 100	  		
      @xo, @yo = @x, @y

      if @angle != @closest_enemy_angle
        turn_towards(angle_rot)
        @xd, @yd = move_object(@angle)
      end

      speed_multi = @speed * (elapsedtime / 10)
      @x += @xd * speed_multi
      @y -= @yd * speed_multi
    else
      if @angle != @closest_enemy_angle
        turn_towards(angle_rot)
      else
        fire
      end
    end
  end

  def turn_towards(angle_rot)
    if (@angle - @closest_enemy_angle).abs < angle_rot
      @angle = @closest_enemy_angle
    else
      @angle = rotate(@angle, line_of_sight(@angle, @closest_enemy_angle), angle_rot)
    end
  end

  def collision_with(object)
    if object.is_a?(Map)
      @x, @y = @xo, @yo
    elsif object.is_a?(Weapon) && object.ship != self 
      weapon_hit(object)
    else
      super
    end
  end
end
