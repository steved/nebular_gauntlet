# Extends console for user added commands
# There is no need to change anything else, just add a method here and it will be included
#
# Author::    Steven Davidovitz (mailto:steviedizzle@gmail.com)
# Copyright:: Copyright (c) 2006, The Nebular Gauntlet DEV team
# License::   GPL
#

module Commands
  include Constants

  # Outputs string to console
  # - _args_ String to output to console
  def echo(args)
    if args == "usage"
      put("echo [string]: Outputs string to console")
    elsif args.length > 0
      text = args.join(" ")
      put(text)
    end
  end

  # List commands
  # - _args_ If set, list_commands will only output commands that include args
  def list_commands(args = nil)
    if args == "usage"
      put("list_commands: Outputs possible commands to console")
    else
      commands = find_commands.sort
      put("Possible commands:")
      commands.each do |command|
        if !args.nil?
          if command.include?(args[0])
            put(command)
          end
        else
          put(command)
        end
      end
    end
  end

  # Sets alpha of console
  # - _args_ Alpha to set console to
  def setalpha(args)
    if args == "usage"
      put("setalpha [integer]: Sets the alpha of console to int")
    elsif args.length > 0
      if (0..255) === args[0].to_i
        @alpha = args[0].to_i
        put("Alpha set to #{@alpha}")
      else
        put("Alpha must be between 0 and 255")
      end
    end
  end

  # Sets console height from top of screen
  # - _args_ Integer to set height
  def setconsolesize(args)
    if args == "usage"
      put("setconsolesize [integer]: Sets the height of the console to int")
    elsif args.length > 0
      if args[0].to_i < @font.height * 2
        put("Console size must be above #{@font.height * 2}")
      elsif args[0].to_i > @screen.h
        put("Console must be less than #{@screen.h}")
      else
        @height = args[0].to_i
        @console_view = []
        room = ((@height - (@height % @font.height)) / @font.height) - 1
        (0..room).each do |i|
          text = @console_archive[-1 - i]
          @console_view << text if !text.nil?
        end
        @console_view.reverse!
        put("Console size set to #{@height}")
      end
    end
  end

  # Exits program
  def quit(args = nil)
    if args == "usage"
      put("quit: Exits Nebular Gauntlet")
    else
      exit
    end
  end

  def respawn(args = nil)
    return if args == "usage"
    if $ship.state == :dead
      csend($server, STATE, ALIVE) if $server
      $ship.reset_firetimer
      $camera.track($ship)
      $ship.state = :alive
      $ship.health = 100
    end
  end

  def suicide(args = nil)
    retun if args == "usage"
    if $ship.state == :alive
      csend($server, STATE, DEAD) if $server
      $ship.state = :dead
      $ship.health = 0
    end
  end

  def say(args)
    if args == "usage"
      put("say [string]: Chat with other users")
    elsif args.length > 0
      csend($server, MSG, args.join(" ").to_s) if $server
    end
  end

  def rcon(args)
    if args == "usage"
      put("rcon [command]: Send command to server")
    elsif args.length > 0
      csend($server, RCON, $rcon_password, *args) if $server
    end
  end

  def rcon_password(args)
    if args == "usage"
      put("rcon_password [string]: Set the password for the server rcon to string")
    elsif args.length > 0
      $rcon_password = args[0]
      put("rcon password set to #{$rcon_password}")
    else
      $rcon_password = " "
      put("rcon password cleared.")
    end
  end

  def clear(args = nil)
    if args == "usage"
      put("clear: Clears the console")
    else
      reset
    end
  end

  def help(args = nil)
    if args.nil? || args == "usage"
      put("help [command]: Shows the usage for the command")
    elsif args.length > 0
      self.__send__(@args[0], "usage")
    end
  end
end	
