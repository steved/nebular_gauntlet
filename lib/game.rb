require 'lib/engine'
require 'lib/math'
require 'lib/menus'
require 'lib/group'
require 'lib/constants'
require 'lib/network'
require 'lib/console/console'
require 'lib/console/chat'
require 'lib/entity'

Dir.glob("lib/entities/*.rb").each do |file|
  require file
end

module NetGame
  include Network

  def data_accpt(message)
    @ships[message[0]] = Ship.new($ship.image, $ship.cMap, $ship.weapon)
    ship = @ships[message[0]]
    ship.x, ship.y, ship.team = message[2..-1]
  end

  def data_state(message)
    if message[0] == FIRE
      message[1..-1].each do |id|
        add_fire(find_object(id))
      end
    end
  end

  def data_addu(message)
    message.each do |s|
      object = find_object(s[:id])
      if object.nil? && s[:id] < 10
        @ships[s[:id]] = Ship.new($ship.image, $ship.cMap, $ship.weapon)
        object = @ships[s[:id]]
      end
      s.each_key do |k|
        object.method("#{k}=").call(s[k])
      end
    end
  end

  def data_msg(message)
    string, name, former_name = message
    @ships.delete(@ships.select {|x| x.name == name}[0]) if string == PART
    msg = case string
          when DEAD
            "User #{name} has died."
          when ALIVE
            "User #{name} has come back to life."
          when PART
            "User #{name} has left."
          when JOIN
            "User #{name} joins us."
          when CHNG
            "User #{former_name} has changed his nickname to #{name}"
          else
            "#{string} : #{name}"
          end
    @console.put msg
    @chat.put msg
  end

  def data_err(message)
    case message[0]
    when PASSWD
      @console.put "Wrong RCON Password."
    when SHTDWN
      change_state(Error.new, "Server shutting down, disconnected.", Proc.new {|k,v| change_state(MainMenu.new)})
    when EXECF
      @console.put "Command found, but execution failed."
    when CMDNTFND
      @console.put "Command not found."
    else
      @console.put message[0]
    end
  end

  def data_dat(message)
    message.each do |msg|
      object = find_object(msg[:id])
      msg.each_key do |key|
        accessor = object.method(key)
        writer = object.method("#{key}=")
        writer.call(accessor.call - msg[key])
      end
      if object.is_a?(Ship) && (msg.has_key?(:x) || msg.has_key?(:y))
        object.calc_dir
      end
    end
  end

  def data_ping(message)
    $ship.pings << ((SDL.get_ticks - message[0]) / 2).to_f
    # Division by two for round trip?
  end

  def data_flag(message)
  end

  def data_score(message)
    @scoreboard.scores = message[0]
  end

  def find_object(id)
    if id < 10
      @ships[id]
    else
      $entities[id - 10]
    end
  end

  def data_col(message)
    object1 = find_object(message[0])
    object2 = find_object(message[1])
    object1.collision_with(object2)
    object2.collision_with(object1)
  end

  def receive_data(data)
    message = Marshal.load(data[0])

    prefix = message[0]
    msg = message[1..-1]

    consts =  Constants.constants
    consts.each do |const|
      if prefix == Constants.const_get(const)
        begin
          self.__send__("data_#{const.downcase}", msg)
        rescue => e
          puts "Could not find prefix: #{const} or method failed:"
          puts e, e.backtrace
        end
      end
    end
  end
end

class Game < Engine
  include NetGame
  include Constants

  def init_connection
    if !($hostname =~ /\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b/)
      $hostname = nil
      change_state(Error.new, "INVALID IP ADDRESS", Proc.new {|k,v| change_state(MainMenu.new)})
      return
    end

    $nickname = $config['user']['name'] if $nickname.nil?
    $port = 4321 if $port.nil?
    $rcon_password = " "

    begin
      BasicSocket.do_not_reverse_lookup = true
      $server = UDPSocket.new
      $server.connect($hostname, $port)
    rescue
      change_state(Error.new, "Could not connect to server: #{$hostname}", Proc.new {|k,v| change_state(MainMenu.new)})
      $hostname = nil
      return
    end

    csend($server, AUTH, $nickname)

    puts "Looking for init data..."
    res = select([$server], nil, nil, 2)

    begin
      if res
        data = Marshal.load($server.recvfrom_nonblock(512)[0])

        if data[0] == ACCPT
          return data[1..-1]
        else
          change_state(Error.new, "Server full.", Proc.new {|k,v| change_state(MainMenu.new)})
          $hostname = nil
        end
      end
    rescue
      change_state(Error.new, "Could not receive data from server: #{$hostname}", Proc.new {|k,v| change_state(MainMenu.new)})
      $hostname = nil
    end
  end

  def additional_init(map = nil)
    id, map, x, y, team, gametype = init_connection
    return if $hostname.nil?

    $weapons = YAML::load(File.open("data/weapons.yaml"))
    ships = YAML::load(File.open("data/ships.yaml"))

    @keys_down = []

    @interface = UI::Interface.new
    loadingBar = UI::ProgressBar.new($screen, 1, 100, $screen.w / 2, $screen.h / 2)
    @interface.add(loadingBar)

    $fires = Group.new
    $entities = Group.new
    @ships = Group.new

    @fireTimeout = 150 # Limit of time until any user can fire again...

    loadingBar.update(10)

    puts "Loading images"
    @shipImage, @shipMap = load_image("data/images/icon.bmp", true)

    loadingBar.update(15)

    puts "Loading map"
    begin
      $map = Map.new("maps/mp_#{map}/#{map}.yaml")
      $map.load_map
      $map.render
    rescue => e
      change_state(Error.new, "Could not load map: #{map}", Proc.new {|k,v| change_state(MainMenu.new)})
      return
    end

    $weapons.each_key do |weapon|
      image, cmap = load_image($weapons[weapon]["image"], true)
      $weapons[weapon]["limage"] = image
      $weapons[weapon]["cmap"] = cmap 
    end 

    loadingBar.update(50)

    puts "Loading Ship"
    $ship = Ship.new(@shipImage, @shipMap, $weapons[ships[0]["weapon"]]) # Get new Ship class
    $ship.id, $ship.x, $ship.y, $ship.team, $ship.name = id, x, y, team, ships[0]["name"]
    @ships[id] = $ship

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

    loadingBar.update(90)

    puts "Loading interface"
    console_font = load_font("data/fonts/VeraMono.ttf", 15)
    @console = Console.new($screen, console_font, console_font.height * 4) # Get new console (active = false by default)
    @chat = Chat.new($screen, console_font, console_font.height * 4, 0) # Get new console (active = false by default)
    @scoreboard = UI::Scoreboard.new($screen, console_font, gametype)
    @interface.add(@scoreboard)

    puts "Finished loading"
    loadingBar.update(100)
    @interface.remove(loadingBar)

    # Add timer for ping every half second.
    @ping_id = $timer.add(5000, Proc.new {}, Proc.new {csend($server, PING, SDL.get_ticks)}, true)
  end

  def think(elapsedtime)
    res = select([$server], nil, nil, 0)
    if res
      begin
        data = $server.recvfrom_nonblock(512)
      rescue
        change_state(Error.new, "Could not receive data from server.", Proc.new {|k,v| change_state(MainMenu.new)})
        return
      end
      receive_data(data)
    end

    $fires.move(elapsedtime)

    if $ship.state != :dead
      $camera.focus($ship)
      $ship.keypress(elapsedtime, @keys_down)
      #@ships.collide_with($ship)
    else
      $camera.unfocus
    end

    $camera.move(elapsedtime, @keys_down)
  end

  def render
    $camera.draw
    #$ship.collision_check
    $ship.draw
    @ships.each {|s| s.draw if s != $ship && !s.nil?}
    $entities.draw
    $fires.draw
    @console.draw
    @chat.draw
    @interface.draw

    $font.draw_blended_utf8($screen, "Health: #{$ship.health} Shield: #{$ship.shield} Ping: #{$ship.pings[-1]}", 0, $screen.h - $font.height, 255, 255, 255)		
    debug {$font.draw_blended_utf8($screen, "x: #{$ship.x.round}, y: #{$ship.y.round}", 0, $font.height, 255, 255, 255)} # Draw current ship position
  end

  def pause
  end

  def resume
    if $nickname != $config['user']['name']
      $nickname = $config['user']['name']
      csend($server, AUTH, $ship.id, $nickname)
    end
  end

  def key_down(key)
    @console.keypress?(key) if !@chat.active
    @chat.keypress?(key) if !@console.active

    if !@console.active && !@chat.active
      @keys_down << key.sym if !@keys_down.include?(key.sym)
      if key.sym == SDL::Key::P
        push_state(PauseMenu.new)
      elsif key.sym == SDL::Key::TAB && @scoreboard.hidden?
        csend($server, SCORE)
        @interface.show(@scoreboard)
      #elsif key.sym == $keys["Fire"] && $ship.fireTimer >= @fireTimeout && $ship.state == :alive
        #$ship.fireTimer = 0
        #@fireBar.fired
        #add_fire($ship)
        #fire = $fires[-1]
        #csend($server, DAT, FIRE, $ship.id, fire.x, fire.y, fire.angle, fire.id)
      end
    end
  end

  def key_up(key)
    @keys_down.delete(key.sym)
    if key.sym == SDL::Key::TAB
      @interface.hide(@scoreboard)
    end
  end

  def destroy
    csend($server, QUIT, $ship.id) if !$ship.nil?
    $server = $hostname = nil
    $timer.delete(@ping_id)
  end
end
