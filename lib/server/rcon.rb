module RCONCommands
  #Test methods for score changing
  def score(args)
    $users[args[0].to_i].score = args[1].to_i  
  end
end

module NetServer
  include RCONCommands
  def data_rcon(msg, user, address, port)
    if msg[0] == $rcon_password
      command = msg[1]
      args = msg[2..-1]

      if RCONCommands.public_instance_methods.include?(command.to_sym)
        begin
          self.__send__(command, args)
        rescue
          send(user.address, user.port, ERR, EXECF)
        end
      else
        puts "Command not found: #{command}"
        $log.warn("Command not found: #{command}")
        send(user.address, user.port, ERR, CMDNTFND)
      end
    else
      send(user.address, user.port, ERR, PASSWD)
    end
  end
end
