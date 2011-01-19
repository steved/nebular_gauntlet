# This is the ship class that handles player movement.
#  
# Author::    Steven Davidovitz (mailto:steviedizzle@gmail.com)
# Copyright:: Copyright (c) 2006, The Nebular Gauntlet DEV team
# License::   GPL
#

class Ship < Entity
  attr_accessor :fireTimer, :id, :team, :health, :shield, :name, :pings

  # Creates a new Ship entity.
  # - _image_ Image to use for ship
  # - _cMap_ Collision map
  def initialize(image = nil, cMap = nil, weapon = nil)
    super

    @pings = []
    @speed = 3
    reset_firetimer
    @team = nil

    @name = nil

    # Attributes
    @health = 100
    @shield = 0
    @xd, @yd = move_object(@angle)
    @particles = ParticleSystem.new(0, 0, 100, 0.35, 10, @angle, [])
  end

  # Moves ship according to elapsed time and key array.
  def move(elapsedtime, key = [])
    super()
    return if @state != :alive

    @x = 0 if @x <= 0
    @y = 0 if @y <= 0
    @x = $map.w - @image.w if @x >= $map.w - @image.w
    @y = $map.h - @image.h if @y >= $map.h - @image.h

    @xo, @yo = @x, @y

    if key.empty?
      #if @speed < 0.25
      @speed = 0
      #else
      #@speed *= @friction
      #end
    else
      key.each do |k|
        if k == MOVEF
          if @speed < 3
            @speed += 0.2
          end
          calc_dir
          speed_multi = @speed * (elapsedtime / 10)
          @x += @xd * speed_multi
          @y -= @yd * speed_multi
        elsif k == MOVEL || k == MOVER
          angle_rot = 8 * (elapsedtime / 20.0)
          if k == MOVEL
            @angle = rotate(@angle, :left, angle_rot) 
          elsif k == MOVER
            @angle = rotate(@angle, :right, angle_rot)
          end
          #@speed *= @friction
        elsif k == FIRE && @fireTimer <= Time.now
          add_fire(self)
        end
      end
    end
  end

  def calc_dir
    @xd, @yd = move_object(@angle)
  end

  def draw
    super
    return if @state != :alive

    calc_dir
    x = @yd - @xd * @image.w / 2 + (@x + @image.w / 2)
    y = @xd + @yd * @image.h / 2 + (@y + @image.h / 2)
    @particles.move(x, y, 180 + @angle)
    @particles.draw
  end

  def collision_check
    if collide?($map)
      @x, @y = @xo, @yo
      @speed = 0
    end
  end

  # Response to keypress, called inside Game.
  def keypress(elapsedtime, key)
    keys = []
    key.each do |k|
      case k
      when $keys["Move Forward"] 
        keys << MOVEF 
      when $keys["Rotate Left"] 
        keys << MOVEL 
      when $keys["Rotate Right"] 
        keys << MOVER
      when $keys["Fire"]
        keys << FIRE
      end 
    end

    if keys.include?(MOVEF)
      @particles.emit = true
    else
      @particles.emit = false
    end

    if keys.length > 0 && $server
      csend($server, DAT, @id, *keys)
    else
      move(elapsedtime, keys)
    end
  end

  def collision_with(object)
    return if object == self || object.class == Flag
    if object.class == Weapon && object.ship != self
      weapon_hit(object)
    else
      super
    end
  end

  def dump
    data = super
    data[:id] = @id
    data[:team] = @team
    data
  end
end
