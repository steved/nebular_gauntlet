# Require all the game files
require 'lib/core'
require 'lib/mission'
require 'lib/network'
require 'lib/entity'

require 'lib/server/net'
require 'lib/server/rcon'
require 'lib/server/match'

Dir.glob("lib/entities/*.rb").each do |file|
  require file
end

class Server
  include NetServer

  def initialize(gametype, rcon_password, map)
    puts "Server started"
    $log.info("Server started.")

    $messages = []
    $users = []
    $entities = []
    $fires = []
    $rcon_password = rcon_password

    $weapons = YAML::load(File.open("data/weapons.yaml"))
    ships = YAML::load(File.open("data/ships.yaml"))
    $ship_weapon = $weapons[ships[0]["weapon"]]

    $weapons.each_key do |weapon|
      $weapons[weapon]["limage"] = load_image($weapons[weapon]["image"])    
    end

    if ["dm", "ctf", "tdm"].include?(gametype)
      $gametype = gametype
    else
      puts "Could not find gametype #{gametype}"
      exit
    end

    if ["tdm", "ctf"].include?(gametype)
      require 'lib/server/teams'
    end

    if File.exists?("maps/mp_#{map}/#{map}.yaml")
      puts "Starting map #{map}"
      $log.info("Starting map #{map}")
      $map = Map.new("maps/mp_#{map}/#{map}.yaml")
      $map.load_map
    else
      puts "Could not find map #{map}"
      exit
    end

    $ship_image = load_image("data/images/icon.bmp")
    # XXX One time loading of ship image. Will have to be changed later for teams, etc.

    loaded_images = {}
    $map.config["entities"].each_with_index do |entity, index|
      if entity.image != "nil" && !loaded_images.has_key?(entity.image)
        loaded_images[entity.image] = load_image(entity.image)
      end
      $entities << Object.const_get(entity.name).new(loaded_images[entity.image])
      $entities[-1].x, $entities[-1].y = entity.x, entity.y
      $entities[-1].id = index

      if !entity.extra.nil?
        entity.extra.each do |k,v|
          temp = $entities[-1].method("#{k}=")
          temp.call(v)
        end
      end
    end

    puts "Finished init, waiting for users..."
    $log.info("Finished init, waiting for users...")
  end 

  def think
    data = []
    old_length = $fires.length

    $users.each do |user|
      next if user.states.length == 0
      od = user.ship.dump
      user.states.each do |keys|
        user.ship.move(17, keys)
      end
      if $map.collide?(user.ship)
        user.ship.x = od[:x]
        user.ship.y = od[:y]
      end
      nd = user.ship.dump
      cd = {}
      nd.each_key do |key|
        next if key == :state
        if nd[key] != od[key]
          cd[key] = ((od[key] - nd[key]) * 10).to_i / 10.0
        end
      end
      cd[:id] = user.ship.id
      data << cd if cd.length > 1
      user.states.clear
    end

    $entities.each do |entity|
      od = entity.dump
      next if od.nil?
      entity.move(17)
      nd = entity.dump
      cd = {}
      nd.each_key do |key|
        next if key == :state
        if nd[key] != od[key]
          cd[key] = ((od[key] - nd[key]) * 10).to_i / 10.0
        end
      end
      cd[:id] = 10 + entity.id
      data << cd if cd.length > 1
    end

    collide($entities, $users.collect {|x| x.ship}, lambda {|o, j| broadcast(nil, COL, o.id + 10, j.id); o.collision_with(j); j.collision_with(o)})
    collide($entities, $entities, lambda {|o, j| broadcast(nil, COL, o.id + 10, j.id + 10); o.collision_with(j); j.collision_with(o)})

    if data.length > 0
      broadcast(nil, DAT, *data)
    end

    if $fires.length > old_length
      senddat = []
      $fires[-($fires.length - old_length)..-1].each do |fire|
        senddat << ($entities.include?(fire.ship) ? fire.ship.id + 10 : fire.ship.id)
      end
      broadcast(nil, STATE, FIRE, *senddat)
    end
  end

  def collide(group1, group2, block)
    group1.each do |o|
      next if o.state == :dead || o.state == :exploding
      group2.each do |j|
        next if o == j || j.state == :dead || j.state == :exploding
        if o.collide?(j)
          block.call(o, j)
        end
      end
    end
  end

  def shutdown
    broadcast(nil, ERR, SHTDWN)
    puts "Server shutting down."
    $log.info("Server shutting down.")
    $quit = true
    $users.each do |user|
      user.connection.close_connection_after_writing
    end
    EventMachine.add_periodic_timer(1) { wait_for_connections_and_stop }
  end

  def wait_for_connections_and_stop
    if $users.length <= 1
      EventMachine.stop
    else
      puts "Waiting for #{$users.length - 1} connections to finish."
    end
  end
end
