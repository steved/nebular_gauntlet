module NetServer
  def spawn(ship) 
    red_team = $users.select {|x| next if x.ship == nil; x.ship.team == :red}
    blue_team = $users.select {|x| next if x.ship == nil; x.ship.team == :blue}

    if red_team.length > blue_team.length
      ship.team = :blue
    elsif red_team.length == blue_team.length
      tnum = rand(2)
      ship.team = tnum == 0 ? :red : :blue
    else
      ship.team = :red
    end

    spawn_area = $map.config["spawns"].select {|x| x.team == ship.team}[0]
    width, height = rand(spawn_area.width), rand(spawn_area.height)
    spawn_x = spawn_area.x + spawn_area.width - width
    spawn_y = spawn_area.y + spawn_area.height - height
    ship.x, ship.y = spawn_x, spawn_y
  end
end
