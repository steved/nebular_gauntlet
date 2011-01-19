require 'lib/network'

module NetServer
  include Network

  def data_auth(msg, user, address, port)
    if !user.nil?
      former_name = user.name
      user.name = check_nick(msg[1])
      broadcast(nil, MSG, CHNG, user.name, former_name) 
      puts "User #{former_name} changed to #{user.name}"
      $log.info("User #{former_name} changed to #{user.name}")
    else
      add_user(address, port, msg[0])
    end
  end

  def data_quit(msg, user, address, port)
    id = msg[0]
    disconnect_user(id)
  end

  def data_msg(msg, user, address, port)
    $messages << msg[0]
    broadcast(user, MSG, msg[0]) 
  end

  def data_state(msg, user, address, port)
    case msg[0]
    when DEAD
      puts "User #{user.name} has died."
      $log.info("User #{user.name} has died.")
      broadcast(nil, MSG, DEAD, user.name)
      user.ship.state = :dead
    when ALIVE
      puts "User #{user.name} has come back to life."
      $log.info("User #{user.name} has come back to life.")
      broadcast(nil, MSG, ALIVE, user.name)
      user.ship.state = :alive
    end
  end

  def data_ping(msg, user, address, port)
    send(address, port, PING, msg[0])
  end

  def data_dat(msg, user, address, port)
    user.states << msg[1..-1]
  end

  def add_user(address, port, name)
    nuser = User.new(address, port, check_nick(name), Ship.new($ship_image, nil, $ship_weapon), 0, 0, [], self)
    if $users.length <= MAXUSERS
      $users << nuser
      spawn(nuser.ship)
      nuser.ship.id = $users.length - 1

      broadcast(nil, ACCPT, nuser.ship.id, $map.name, nuser.ship.x, nuser.ship.y, nuser.ship.team, $gametype)

      dat = []
      $users[0..-2].each do |user|
        dat << user.ship.dump
      end
      $entities.each do |entity|
        dat << entity.dump if !entity.dump.nil?
      end
      send(address, port, ADDU, *dat)

      puts "User #{name} joins us."
      $log.info("User #{name} joins us.")
      broadcast(nil, MSG, JOIN, name)
    else
      send(address, port, ERR, FULL)
    end
  end

  def disconnect_user(id)
    user = $users[id]
    broadcast(nil, MSG, PART, user.name) if !user.nil?
    $users.delete_at(id)
  end

  def spawn(ship)
    ship.x, ship.y = rand($map.width), rand($map.height)
    while $map.collide?(ship)
      ship.x, ship.y = rand($map.width), rand($map.height)
    end
  end

  def check_nick(nick)
    $users.collect {|x| x.name}.include?(nick) ? nick + "_1" : nick
  end

  def unbind
    $users.delete_if {|x| x.connection == self}
  end
end
