# This is the base Engine class includes handles states,
# initializes SDL and its subsystems and handles basic methods.
# 
# Author::    Steven Davidovitz (mailto:steviedizzle@gmail.com)
# Copyright:: Copyright (c) 2006, The Nebular Gauntlet DEV team
# License::   GPL
#

require 'sdl'
require 'mathn'
require 'getoptlong'
require 'yaml'
require 'lib/core'

# Executes block if $DEBUG is true
def debug
  yield if $DEBUG
end

class Engine
  include Core

  $DEBUG = false

  @@lasttick = 0 # Last frame's tick value

  @@width = 800 # Window width
  @@height = 600 # Window height

  @@quit = false # Has quit been called?

  @@title = "" # Window title

  # Variables for FPS calculation
  @@fpstickcounter = 0 # Tick counter
  @@fpscounter = 0 # Frame rate counter
  @@currentfps = 0 # Last calculated frame rate
  @@elapsedticks = 0 # Elapsed ticks since last frame

  @@states = [] # For storage of states
  @@sounds = [] # For storage of loaded sounds

  # Map structs
  Struct.new("Tileset", :name, :image, :firstgid, :tilewidth, :tileheight)
  Struct.new("Layer", :name, :opacity, :width, :height, :tiles)
  Struct.new("Area", :x, :y, :width, :height)
  Struct.new("Flag", :x, :y, :type)
  Struct.new("Spawn", :x, :y, :width, :height, :team)
  Struct.new("SpawnPoint", :x, :y)
  Struct.new("Entity", :name, :image, :x, :y, :extra)
  Struct.new("Tile", :x, :y, :height, :width)
  Struct.new("Objective", :x, :y)

  # Sets height and width of window
  # - _width_ Width of the base screen
  # - _height_ Height of the base screen
  # - _flags_ Flags to initialize SDL with
  def set_size(width, height, flags = (SDL::HWSURFACE | SDL::DOUBLEBUF))
    $screen = SDL::Screen.open(width, height, 0, flags) 
  end

  # Handle all controller inputs
  def handle_input
    # Poll for events, handle the ones we need
    while event = SDL::Event.poll
      case event
      when SDL::Event::KeyDown
        if event.sym == $keys["Screenshot"] # Take a screenshot
          $screen.save_bmp("data/screenshots/#{next_file_name(Dir.glob("data/screenshots/*"), "screenshot", "bmp")}.bmp")
        else
          @@states.last.key_down(event)
        end
      when SDL::Event::KeyUp
        @@states.last.key_up(event)
      when SDL::Event::Quit
        @@quit = true
      end
    end
  end

  # Initialize SDL, the window, and additional data
  def init
    # Command line options and parser
    @opts = GetoptLong.new(
      [ "--debug",	"-d",	GetoptLong::NO_ARGUMENT],
      [ "--width",	"-w",	GetoptLong::REQUIRED_ARGUMENT],
      [ "--height",	"-h",	GetoptLong::REQUIRED_ARGUMENT]
    )

    @opts.each do |opt, arg|
      case opt
      when "--debug"
        $DEBUG = true
      when "--width"
        @@width = arg.to_i
      when "--height"
        @@height = arg.to_i
      end
    end

    # Initialize SDL subsystems video, font, and music
    SDL.init(SDL::INIT_VIDEO)
    SDL.init(SDL::INIT_AUDIO)
    SDL::TTF.init

    begin
      SDL::Mixer.open
    rescue SDL::Error => e
      puts e
    end

    #  Attempt to create a window with the specified height and width
    set_size(@@width, @@height)

    # Set keyboard key repeat rate
    SDL::Key.enable_key_repeat(500, 30)

    # Global timer class
    $timer = Timer.new

    additional_init()
  end

  # Main loop
  def start
    @@lasttick = SDL.getTicks

    @on_quit = Proc.new do
      @@quit = true
      pop_all()
    end

    # Main loop; Loop until quit
    while !@@quit
      handle_input() # Handle keyboard input

      do_think() # Do calculations/thinking
      do_render() # Render everything

      # To trap interrupt and exit for cleaning up and so server doesn't segfault.
      Signal.trap("INT", @on_quit)
      Signal.trap("EXIT", @on_quit)
    end
  end

  # Changes the current state to the specified one with arguments
  # - _state_ State to change to
  # - _args_ Arguments to next state
  def change_state(state, *args)
    if !@@states.empty?
      pop_state
    end

    @@states << state
    @@states.last.additional_init(*args)
  end

  # Push a state so that when the other one ends, the next one begins
  def push_state(state, *args)
    @@states.last.pause if !@@states.empty?

    @@states << state
    @@states.last.additional_init(*args)
  end

  # End the last state and resume the next one
  def pop_state
    @@states.last.destroy
    @@states.pop

    if !@@states.empty?
      @@states.last.resume
    end
  end

  # Removes all states
  def pop_all
    while !@@states.empty?
      pop_state()
    end
  end

  # Cleanup for the last state before deletion
  def cleanup
    while !@@states.empty?
      @@states.last.cleanup
      @@states.pop
    end
  end

  # Defined by subclasses and called by Init
  def additional_init
  end

  # To be defined by subclass, what to do on pause
  def pause
  end

  # To be defined in subclass, what to do on resume
  def resume
  end

  # Calls last state's Think method and increments tick variables
  def do_think
    @@elapsedticks = SDL.get_ticks - @@lasttick
    @@lasttick = SDL.get_ticks

    $timer.run

    @@states.last.think(@@elapsedticks)

    @@fpstickcounter += @@elapsedticks
  end

  # Calls last state's Render method and calculates FPS
  def do_render
    @@fpscounter += 1

    if @@fpstickcounter >= 1000
      @@currentfps = @@fpscounter
      @@fpscounter = 0
      @@fpstickcounter = 0
    end

    @@states.last.render

    debug {$font.draw_blended_utf8($screen, @@currentfps.to_s, @@width - $font.textSize(@@currentfps.to_s)[0], 0, 255, 255, 255)} # Draw fps
    $screen.flip # Update the whole screen
  end

  # Set the title of the window
  # - _title_ String to set window caption to set to
  def set_title(title)
    @@title = title
    SDL::WM.set_caption(@@title, "")
  end
end
