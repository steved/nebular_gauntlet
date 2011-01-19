# This is a set of classes that define menus.
#
# Author::    Steven Davidovitz (mailto:steviedizzle@gmail.com)
# Copyright:: Copyright (c) 2006, The Nebular Gauntlet DEV team
# License::   GPL
#

require 'lib/engine'
require 'lib/interface'
require 'lib/game'
require 'lib/single-game'
require 'lib/constants'
require 'lib/natcmp'
require 'lib/network'

# This is the main menu class.
class MainMenu < Engine
  include UI
  include NGMath
  include Network

  def additional_init
    @background = load_image("data/images/menu_background_#{@@width}x#{@@height}.png")
    @interface = Interface.new
    init_interface
  end

  def init_interface
    game = Proc.new do |t,v|
      $hostname = t
      @interface.remove(v)
      change_state(Game.new)
    end

    hostname = Proc.new do
      @interface.add(InputBox.new($screen, $font, $screen.w / 2, $screen.h / 2, "Please enter the IP address or hostname of the server:", game, Proc.new {|v| @interface.remove(v)}))
    end

    credits = Proc.new do
      @interface.add(Prompt.new($screen, $font, $screen.w / 2, $screen.h / 2, Proc.new {|k,v| @interface.remove(v) if k == SDL::Key::ESCAPE}, 
                                ["Steven Davidovitz", "Robert Oliver", "David Gurba"]))
    end 

    nosaves = Proc.new do
      @interface.add(Prompt.new($screen, $font, $screen.w / 2, $screen.h / 2, Proc.new {|k,v| @interface.remove(v) if k == SDL::Key::ESCAPE}, 
                                ["No saved games."]))
    end 

    implement_error = Proc.new do
      change_state(Error.new, "This feature is not implemented in this version.", Proc.new {|k,v| change_state(MainMenu.new)})
    end

    @interface.add(Menu.new($screen, $font, [["New Single Player Game", Proc.new {push_state(LoadMap.new)}], ["Load Single Player Game", (Dir.glob(File.join("**", "*.sav")).empty?) ? nosaves : Proc.new {push_state(LoadGame.new)}],
                            ["New Remote Game", hostname], ["Options", Proc.new {push_state(OptionsMenu.new)}], ["Credits", credits], ["Quit", Proc.new {exit}]]))
  end

  def think(elapsedtime)
  end

  def render
    $screen.fill_rect(0, 0, $screen.w, $screen.h, 0)
    SDL::Surface.blit(@background, 0, 0, 0, 0, $screen, 0, 0)
    @interface.draw
  end

  def pause
  end

  def resume
  end

  def key_down(key)
    if key.sym == SDL::Key::ESCAPE
      if self.is_a?(Menu) && self.class != MainMenu
        pop_state()
      end
    end

    @interface.keypress?(key)
  end	

  def key_up(key)
  end

  def destroy
  end

  # Saves game to a new file with specified name
  # - _name_ String to set save game's name to
  def save_game(name = nil)
    fname = next_file_name(File.join("**", "*.sav"), "save", "sav")

    # Collects data and adds into arrays

    data = { "name" => name,
            "map" => $map.name,
            "ship" => [$ship.name, $ship.x, $ship.y, $ship.state, $ship.angle, $ship.speed],
            "entities" => []}

    $entities.each_with_index do |entity, i|
      data["entities"] << [entity.id, entity.x, entity.y, entity.state, entity.angle, entity.speed]
    end

    File.open("data/savegames/#{fname}.sav", "w+") do |f|
      YAML.dump(data, f)
    end

    pop_state # Pops state back to menu
  end


  # Loads game from specificed filename
  # - _filename_ Filename to load game from
  def load_game(filename)
    tree = YAML.load(File.open(filename))
    ships = YAML.load(File.open("data/ships.yaml"))
    pop_all
    change_state(SingleGame.new, tree["map"], ships.select {|x| x["name"] == tree["ship"][0]}[0])
    # Load ship vars
    $ship.x, $ship.y, $ship.state, $ship.angle, $ship.speed = tree["ship"][1..5] if tree["ship"].length != 1
    $ship.calc_dir

    tree["entities"].each do |entity|
      e = $entities[entity[0]]
      e.x, e.y, e.state, e.angle, e.speed = entity[1..-1]
    end if !tree["entities"].empty?
  end
end

# This is the menu that is called mid-game.
class PauseMenu < MainMenu
  include Constants
  def init_interface
    disconnect = Proc.new do
      $hostname = nil
      pop_state(); pop_state()
      push_state(MainMenu.new)
    end

    @interface.add(Menu.new($screen, $font, [["Resume", Proc.new {pop_state()}], ["Options", Proc.new {push_state(OptionsMenu.new)}], 
                            ["Disconnect", disconnect], ["Quit", Proc.new {exit}]]))
  end
end

class SinglePauseMenu < MainMenu
  include Constants
  def init_interface
    savegame = Proc.new do 
      @interface.add(InputBox.new($screen, $font, $screen.w / 2, $screen.h / 2, "Please enter a name for your game:", 
                                  Proc.new {|t,v| save_game(t)}, Proc.new {|v| @interface.remove(v)}))
    end

    disconnect = Proc.new do
      pop_state(); pop_state()
      push_state(MainMenu.new)
    end

    @interface.add(Menu.new($screen, $font, [["Resume", Proc.new {pop_state()}],
                            ["Save Game", savegame],
                            ["Load Game", Proc.new {push_state(LoadGame.new)}],
                            ["Options", Proc.new {push_state(OptionsMenu.new)}], 
                            ["Disconnect", disconnect], 
                            ["Quit", Proc.new {exit}]]
                           ))
  end
end


# Displays options menu
class OptionsMenu < MainMenu
  def init_interface
    fps_lambda = Proc.new do |text, key|
      $DEBUG = true if key == SDL::Key::RIGHT
      $DEBUG = false if key == SDL::Key::LEFT
      text.text = "Debug: #{$DEBUG}"
    end

    @interface.add(Menu.new($screen, $font, [["Debug: #{$DEBUG}", fps_lambda], ["Change Profile", Proc.new {push_state(ProfileMenu.new)}],
                            ["Back", Proc.new {pop_state()}]]))
  end
end

# Displays options to change profile settings
class ProfileMenu < MainMenu
  def init_interface
    @old_nick = $config['user']['name']
    @old_sound = $config['user']['sound']
    @old_volume = $config['user']['volume']

    save_config = Proc.new do |t,v|
      $config['user']['name'] = t
      @interface.remove(v)
    end

    nickname = Proc.new do 
      @interface.add(InputBox.new($screen, $font, $screen.w / 2, $screen.h / 2, "Enter your desired nickname:", 
                                  save_config, Proc.new {|v| @interface.remove(v)}))
    end

    sound = Proc.new do |t,v|
      $config['user']['sound'] = 'on' if v == SDL::Key::RIGHT
      $config['user']['sound'] = 'off' if v == SDL::Key::LEFT
      t.text = "Sound: #{$config['user']['sound']}"
    end

    volume = Proc.new do |t,v|
      $config['user']['volume'] += 1 if v == SDL::Key::RIGHT && $config['user']['volume'] < 128
      $config['user']['volume'] -= 1 if v == SDL::Key::LEFT && $config['user']['volume'] > 0
      t.text = "Volume: #{$config['user']['volume']}"
    end

    cancel = Proc.new do
      $config['user']['name'] = @old_nick
      $config['user']['sound'] = @old_sound
      $config['user']['volume'] = @old_volume
      save_config("data/config.yaml")
      pop_state
    end

    @interface.add(Menu.new($screen, $font, [["Change nickname", nickname], ["Sound: #{$config['user']['sound']}", sound], ["Volume: #{$config['user']['volume']}", volume], ["Keyboard Settings", Proc.new {push_state(KeySettings.new())}],
                            ["Apply", Proc.new {save_config("data/config.yaml"); pop_state}], ["Cancel", cancel]]))
  end
end

# Menu to change key settings
class KeySettings < MainMenu
  def init_interface
    @mkeys = []
    $config['keys'].each do |desc, keyval|
      @mkeys << ["#{desc}: #{keyval}", Proc.new {|text, key| change_key(text)}]
    end

    @mkeys << ["Apply", Proc.new {apply_keys}]
    @mkeys << ["Cancel", Proc.new {pop_state()}]
    @interface.add(Menu.new($screen, $font, @mkeys))
  end

  # Changes key setting
  def change_key(text)
    desc = text.text.split(":")[0]
    key_lambda = Proc.new do |key, window| 
      if key != SDL::Key::RETURN
        #$config['keys'][desc] = SDL::Key.getKeyName(key)
        @mkeys.each_with_index do |k, index|
          if k[0].split(":")[0] == desc
            #@mkeys[index][0] = text.text = "#{desc}: #{$config['keys'][desc].upcase}"
            @mkeys[index][0] = text.text = "#{desc}: #{SDL::Key.get_key_name(key).upcase}"
          end
        end
        @interface.remove(window)
      end
    end

    @interface.add(Prompt.new($screen, $font, $screen.w / 2, $screen.h / 2, key_lambda, ["Press a key."]))
  end

  # Applies and saves key settings
  def apply_keys
    @mkeys[0..-3].each_with_index do |key, index|
      $config['keys'][key[0].split(": ")[0]] = key[0].split(": ")[1].upcase
    end

    save_config("data/config.yaml")
    pop_state()
  end	
end

# Displays a menu with all save games listed.
class LoadGame < MainMenu
  def init_interface
    savdirs = File.join("**", "*.sav")
    @savefiles = Dir.glob(savdirs)
    @saves = []

    @savefiles.sort! {|a,b| String.natcmp(a, b)}
    @savefiles.each do |save|
      tree = YAML.load(File.new(save))
      @saves << [tree["name"], Proc.new {load_game(save)}]
    end
    @saves << ["Back", Proc.new {pop_state()}]

    @interface.add(Menu.new($screen, $font, @saves))
  end
end

# Displays menu with maps listed for local games
class LoadMap < MainMenu
  def init_interface
    @maps = []
    @mapnames = []

    find_maps

    @maps.unshift(["Choose a map:", Proc.new {}])
    @maps << ["Back", Proc.new {pop_state()}]
    @interface.add(Menu.new($screen, $font, @maps))
  end

  def find_maps
    mapfiles = Dir.glob("maps/sp_*/*.yaml")
    mapfiles.each {|map| @mapnames << map.split('/')[-1].split('.')[0]}
    @mapnames.each {|map| @maps << ["#{map}", Proc.new {push_state(ChooseShip.new, map)}]}
  end
end

# Displays error prompt/menu
class Error < MainMenu
  def additional_init(err, action)
    @err, @action = err, action
    super()
  end

  def init_interface
    @interface.add(Prompt.new($screen, $font, $screen.w / 2, $screen.h / 2, @action, ["Error:", @err]))
  end
end

# Chooses ship
class ChooseShip < MainMenu
  def additional_init(map)
    @map = map
    super()
  end

  def init_interface
    @ships = YAML::load(File.open("data/ships.yaml"))

    @maps = []
    @ships.each do |ship|
      @maps << ["#{ship["name"]}", Proc.new {change_state(SingleGame.new, @map, ship)}]
    end
    @maps.unshift(["Choose a ship:", Proc.new {}])
    @maps << ["Back", Proc.new {pop_state()}]
    @interface.add(Menu.new($screen, $font, @maps))
  end
end


class MissionEnd < MainMenu
  def additional_init(next_map)
    @next = next_map
    super()
  end

  def init_interface
    @interface = UI::Interface.new

    savegame = Proc.new do |name, v|
      fname = next_file_name(File.join("**", "*.sav"), "save", "sav")

      # Collects data and adds into arrays

      data = { "name" => name,
            "map" => @next,
            "ship" => [$ship.name],
            "entities" => []}

      File.open("data/savegames/#{fname}.sav", "w+") do |f|
        YAML.dump(data, f)
      end

      @interface.remove(v)
    end

    saveprompt = Proc.new do
      @interface.add(InputBox.new($screen, $font, $screen.w / 2, $screen.h / 2, "Please enter a name for your game:", 
                                  Proc.new {|t,v| savegame.call(t, v)}, Proc.new {|v| @interface.remove(v)}))
    end

    disconnect = Proc.new do
      pop_state(); pop_state()
      push_state(MainMenu.new)
    end

    menu = []
    if !@next.nil? && !@next.empty?
      menu << ["Continue", Proc.new {push_state(ChooseShip.new, @next)}]
    end

    menu << ["Save", saveprompt] << ["Load", Proc.new {push_state(LoadGame.new)}] << ["Return to menu", disconnect] << ["Quit", Proc.new {exit}] 

    @interface.add(Menu.new($screen, $font, menu))
  end
end
