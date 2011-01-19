# State that handles game introduction.
# 
# Author::    Steven Davidovitz (mailto:steviedizzle@gmail.com)
# Copyright:: Copyright (c) 2006, The Nebular Gauntlet DEV team
# License::   GPL
#

require 'lib/engine'
require 'lib/interface'
require 'lib/menus'

class Intro < Engine
  # Creates new interface and loads intro images.
  def additional_init
    $font = load_font("data/fonts/Diavlo_14e.otf", 20)

    load_config("data/config.yaml")
    load_sounds("data/sounds.yaml")

    @logo = load_image("data/images/logo.bmp")
    @interface = UI::Interface.new
    @interface.add(UI::Intro.new($screen, Proc.new {change_state(MainMenu.new)}, @logo))
  end

  def think(elapsedtime)
  end

  # Draws graphics on screen.
  def render
    @interface.draw
  end

  def pause
  end

  def resume
  end

  # Response on key press.
  def key_down(key)
    @interface.keypress?(key) # Needed for interface events
    change_state(MainMenu.new) if key.sym == SDL::Key::SPACE # Change to a new state when intro when key is pressed
  end	

  def key_up(key)
  end

  # Clean up.
  def destroy
  end
end
