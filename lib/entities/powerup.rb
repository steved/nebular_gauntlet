# This is a powerup class which effects entities.
#
# Author::    Steven Davidovitz (mailto:steviedizzle@gmail.com)
# Copyright:: Copyright (c) 2006, The Nebular Gauntlet DEV team
# License::   GPL
#

require 'lib/entity'
require 'lib/timer'

class Powerup < Entity
  def self.get_effect
    @effect
  end

  def self.effect(&e)
    @effect = e
  end

  def move(elapsedtime)
  end

  def collision_with(object)
    begin
      self.class.get_effect.call(object)
    rescue => e
      puts "Could not put effect on object: #{object}:\n#{e}"
    end
    @state = :dead
  end
end

class StrengthPowerup < Powerup
  effect {|object| $timer.add(5000, Proc.new {object.damage_modifier += 5}, Proc.new {object.damage_modifier -= 5})}
end

class HealthPowerup < Powerup
  effect {|object| object.health += 10}
end

class ShieldPowerup < Powerup
  effect {|object| object.shield += 10}
end

class RandomPowerup < Powerup
  effect {|object| object.health = 0}
end
