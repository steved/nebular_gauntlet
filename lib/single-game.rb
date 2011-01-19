require 'lib/engine'
require 'lib/math'
require 'lib/mission'
require 'lib/menus'
require 'lib/group'
require 'lib/constants'
require 'lib/console/console'
require 'lib/entity'

Dir.glob("lib/entities/*.rb").each do |file|
  require file
end

class SingleGame < Engine
  include NetGame
  include Constants

  def additional_init(map, ship)
    $weapons = YAML::load(File.open("data/weapons.yaml"))

    @keys_down = []

    @interface = UI::Interface.new
    loadingBar = UI::ProgressBar.new($screen, 1, 100, $screen.w / 2, $screen.h / 2)
    @interface.add(loadingBar)

    $fires = Group.new
    $entities = Group.new

    loadingBar.update(10)

    puts "Loading images"
    @shipImage, @shipMap = load_image(ship["image"], true)

    loadingBar.update(15)

    puts "Loading map"

    begin
      $map = Mission.new("maps/sp_#{map}/#{map}.yaml")
      $map.render
    rescue => e
      change_state(Error.new, "Could not load map: #{map}", Proc.new {|k,v| change_state(MainMenu.new)})
      puts "Error loading map:"
      puts e
      return
    end

    spawn_num = rand($map.config["spawns"].length)
    begin
      x, y = $map.config["spawns"][spawn_num].x, $map.config["spawns"][spawn_num].y
    rescue
      x = rand($map.width)
      y = rand($map.height)
    end

    $weapons.each_key do |weapon|
      image, cmap = load_image($weapons[weapon]["image"], true)
      $weapons[weapon]["limage"] = image
      $weapons[weapon]["cmap"] = cmap 
    end 

    loadingBar.update(50)

    puts "Loading Ship"
    $ship = Ship.new(@shipImage, @shipMap, $weapons[ship["weapon"]]) # Get new Ship class
    $ship.x, $ship.y, $ship.name = x, y, ship["name"]
    $camera = Camera.new($ship)

    loadingBar.update(80)

    puts "Loading objects"

    $map.config["entities"].each_with_index do |entity, index|
      image, cmap = load_image(entity.image, true) if entity.image != "nil"
      $entities << Object.const_get(entity.name).new(image, cmap)
      $entities[-1].x, $entities[-1].y = entity.x, entity.y
      $entities[-1].id = index

      if !entity.extra.nil?
        entity.extra.each do |k,v|
          temp = $entities[-1].method("#{k}=")
          temp.call(v)
        end
      end
    end

    @fireBar = UI::FireBar.new($screen)
    @interface.add(@fireBar)
    @interface.add(UI::Radar.new($screen, 15, $ship, *$entities))
    loadingBar.update(90)

    puts "Loading interface"
    console_font = load_font("data/fonts/VeraMono.ttf", 15)
    @console = Console.new($screen, console_font, console_font.height * 4) # Get new console (active = false by default)

    puts "Finished loading"
    loadingBar.update(100)
    @interface.remove(loadingBar)
  end

  def think(elapsedtime)
    return if elapsedtime > 100

    $map.check_objs

    $ship.keypress(elapsedtime, @keys_down)
    $camera.move(elapsedtime, @keys_down)

    $fires.move(elapsedtime)
    $fires.collide_with($ship)
    $fires.collide_with($map)
    $fires.collide_with($entities)

    $entities.move(elapsedtime)
    $entities.collide_with($fires)
    $entities.collide_with($ship)
    $entities.collide_with($entities)
    $entities.collide_with($map)

    if $ship.state == :dead
      $camera.unfocus
    else
      $camera.focus($ship)
    end
  end

  def render	
    $camera.draw
    $ship.draw
    $ship.collision_check
    $fires.draw
    $entities.draw
    @interface.draw
    @console.draw

    # Draw info
    $font.draw_blended_utf8($screen, "Health: #{$ship.health} Shield: #{$ship.shield} Dmg: #{$ship.weapon["damage"] + $ship.damage_modifier}", 0, $screen.h - $font.height, 255, 255, 255)
    str = "x: #{$ship.x.round}, y: #{$ship.y.round}"
    debug {$font.draw_blended_utf8($screen, str, $screen.w - $font.textSize(str)[0], $font.height, 255, 255, 255)} # Draw current ship position
  end

  def pause
  end

  def resume
  end

  def key_down(key)
    @console.keypress?(key)

    if !@console.active
      @keys_down << key.sym if !@keys_down.include?(key.sym)
      if key.sym == SDL::Key::P
        push_state(SinglePauseMenu.new)
      end
    end
  end

  def key_up(key)
    @keys_down.delete(key.sym)
  end

  def destroy
  end
end
