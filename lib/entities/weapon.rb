# This is the weapon class that can be
# subclassed to create different weapon types.
#
# Author::    Steven Davidovitz (mailto:steviedizzle@gmail.com)
# Copyright:: Copyright (c) 2006, The Nebular Gauntlet DEV team
# License::   GPL
#

class Weapon < Entity
  attr_accessor :ship, :damage, :reload

  # Create a new weapon.
  # - _ship_ Object that fires weapon
  # - _image_ Image to use for weapon
  # - _cMap_ Collision map for weapon
  def initialize(ship, weapon, id, angle = nil)
    super(weapon["limage"], weapon["cmap"])

    @ship = ship
    @damage = weapon["damage"]
    @tracking = weapon["tracking"]
    @reload = weapon["reload"]

    # Doesn't work with netork games.
    #xd, yd = move_object(@ship.angle)
    @x = @ship.x + @image.w / 2
    @y = @ship.y + @image.h / 2
    @angle = angle || @ship.angle
    @xd, @yd = move_object(@angle)

    @fx = weapon["fx"]
    @particles = ParticleSystem.new(-100, -100, 100, 0.15, 10, @angle, []) # Start off screen. Recalculated in draw
    @particles.emit = true

    @speed = 5
    @id = id
  end

  # Moves weapon based on elapsedtime.
  def move(elapsedtime)
    return if @state != :alive

    speed_multi = @speed * (elapsedtime / 10)

    if @x <= 0 || @y <= 0 || @x >= $map.w || @y >= $map.h 
      @state = :dead
      @particles.emit = false
    end

    angle_rot = 10 * (elapsedtime / 20)

    if @tracking
      find_enemies
      if @closest_enemy 
        @closest_enemy_angle = calc_angle(@x, @y, @closest_enemy.x, @closest_enemy.y)
        if @angle != @closest_enemy_angle
          if (@angle - @closest_enemy_angle).abs <= angle_rot
            @angle = @closest_enemy_angle
          else
            @angle = rotate(@angle, line_of_sight(@angle, @closest_enemy_angle), angle_rot)
          end
          @xd, @yd = move_object(@angle)
        end
      end
    end

    @x += @xd * speed_multi
    @y -= @yd * speed_multi
  end

  def draw
    super
    return if @state != :alive

    if @fx
      x = @yd - @xd * @image.w / 2 + (@x + @image.w / 2)
      y = @xd + @yd * @image.h / 2 + (@y + @image.h / 2)
      @particles.move(x, y, 180 + @angle)

      @particles.draw 
    end
  end


  def find_enemies
    if @closest_enemy && @closest_enemy.state == :dead
      @closest_enemy = nil
      @closest_enemy_angle = nil
    end

    enemies = $entities.select {|x| x.class == Bot || x.class == Pillbox}
    if $ships
      $ships.each {|x| enemies << x}
    else
      enemies << $ship
    end
    enemies.delete(@ship)

    enemies.each do |enemy|
      next if enemy.nil? || enemy.state == :dead

      if !@closest_enemy || (@closest_enemy && @closest_enemy.state == :dead)
        @closest_enemy = enemy
        @closest_enemy_angle = calc_angle(@x, @y, @closest_enemy.x, @closest_enemy.y)
      end
    end
  end

  # Removes weapon on collision with another object.
  def collision_with(object)
    if object != @ship
      @state = :dead
      @particles.emit = false
    end
  end
end		

