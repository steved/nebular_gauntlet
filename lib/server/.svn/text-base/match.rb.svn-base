module NetServer
  def data_score(msg, user, address, port)
    scores = []
    if ["tdm", "ctf"].include?($gametype)
      red = []; blue = []
      $users.each do |x|
        eval("#{x.ship.team.to_s}") << [x.name, x.kills, x.score]
      end
      scores << red << blue
      send(user.address, user.port, SCORE, scores)
    else
      $users.each do |x|
        scores << [x.name, x.kills, x.score]
      end
      send(user.address, user.port, SCORE, scores)
    end
  end
end
