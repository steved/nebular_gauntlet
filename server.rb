Dir.chdir(File.expand_path(File.dirname(__FILE__)))

require 'getoptlong'
require 'eventmachine'
require 'logger'
require 'lib/server'
require 'lib/network'

$DEBUG = true
User = Struct.new(:address, :port, :name, :ship, :kills, :score, :states, :connection)
MAXUSERS = 10

port = 4321
rcon_password = "TEST" 
map = "planets"
logf = "server.log"
gametype = "dm"

opts = GetoptLong.new(
  [ "--port",	"-p", GetoptLong::REQUIRED_ARGUMENT],
  [ "--rcon_password", "-r", GetoptLong::REQUIRED_ARGUMENT],
  [ "--map", "-m", GetoptLong::REQUIRED_ARGUMENT],
  [ "--help", "-h", GetoptLong::NO_ARGUMENT],
  [ "--log", "-l", GetoptLong::REQUIRED_ARGUMENT],
  [ "--gametype", "-g", GetoptLong::REQUIRED_ARGUMENT]
)

opts.each do |opt, arg|
  case opt
  when "--gametype"
    gametype = arg
  when "--port"
    port = arg.to_i
  when "--rcon_password"
    rcon_password = arg
  when "--map"
    map = arg
  when "--log"
    logf = arg
  when "--help"
    print <<-EOL
Usage: ruby server.rb [options]

Options:
\t--port, -p		Sets port to specified integer (defaults to 4321)
\t--map, -m		Loads specified map on server start (defaults to planets)
\t--rcon_password, -r	Sets rcon password to specified string (defaults to TEST)
\t--log, -l             Sets the logfile location (defaults to server.log)
\t--gametype, -g        Sets the gametype (defaults to dm)

Nebular Gauntlet, Copyright 2008
EOL
    exit
  end
end

$quit = false

file = File.open(logf, File::WRONLY | File::APPEND | File::CREAT | File::TRUNC)
$log = Logger.new(file)
$log.level = $DEBUG ? Logger::DEBUG : Logger::INFO
$log.datetime_format = "%m-%d-%Y %I:%M:%S %p "

server = Server.new(gametype, rcon_password, map)

Signal.trap('INT') {server.shutdown if !$quit}

Thread.new do
  while !$quit
    server.think
  end
end

EventMachine.run {
  $server = EventMachine.open_datagram_socket("", port, NetServer)
}
