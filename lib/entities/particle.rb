# Particle system for use with particle effects.
#
# Author::    Steven Davidovitz (mailto:steviedizzle@gmail.com)
# Copyright:: Copyright (c) 2006, The Nebular Gauntlet DEV team
# License::   GPL
#



require 'lib/entity'

Struct.new("Particle", :x, :y, :angle, :color, :alive, :energy, :speed)

class ParticleSystem < Entity
  attr_accessor :x, :y, :angle, :emit

  def initialize(x, y, max, max_energy = 0.5, width = 10, angle = 10, final = [])
    @particles = []
    @max = max
    @x, @y = x, y
    @angle = angle
    @width = width
    @emit = false
    @final = final
    @max_energy = max_energy

    reset
  end

  def draw
    @particles.each do |particle|
      next if !particle.alive
      x, y = calc_display(particle)
      $screen.draw_circle(x, y, 1, particle.color, true) 
    end
  end

  def move(x = nil, y = nil, angle = nil)
    x ||= @x
    y ||= @y
    angle ||= @angle
    @particles.each do |particle|
      if !particle.alive && @emit
        particle.x = x
        particle.y = y
        particle.angle = rand(@width) + angle
        particle.color = [255, 255 * (0.2 + rand() * 1000 % 50 / 100), 0]
        particle.energy = (@max_energy - rand)
        particle.alive = true
      else
        xd, yd = move_object(particle.angle)
        particle.x += xd * particle.speed
        particle.y -= yd * particle.speed
        particle.energy -= 0.05
        particle.alive = false if particle.energy < 0
      end
    end
    if @particles.select {|x| !x.alive}.length == @particles.length && !@final.empty?
      @final[0].call(@final[1])
    end
  end

  # Reset particle array with _max_ particles.
  def reset
    (0..@max).each do |i|
      @particles[i] = Struct::Particle.new(x, y, rand(@width) + @angle, [255, 255 * (0.2 + rand() * 1000 % 50 / 100), 0], true, (@max_energy - rand).abs, rand*3+1.floor)
    end
  end

  def collision_with(o)
  end
end

