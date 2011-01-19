# This is a network API that simplifies
# sending and parsing
#
# Author::    Steven Davidovitz (mailto:steviedizzle@gmail.com)
# Copyright:: Copyright (c) 2006, The Nebular Gauntlet DEV team
# License::   GPL
#

begin
  require 'eventmachine'
rescue LoadError
  warn "For network support install eventmachine."
end
require 'socket'
require 'lib/engine'
require 'lib/constants'

module Network
  include Core
  include Constants

  # Sends user data, gzipped and marshalled
  # - _user_ User to send packet to
  # - _prefix_ Data prefix to use
  # - _*data_ Data to send
  def send(address, port, prefix, *data)
    dat = Marshal.dump(data.unshift(prefix))
    debug {puts "Sending out #{data}"; $log.debug("Sending out #{data}")}
    $server.send_datagram(dat, address, port)
  end

  def csend(socket, prefix, *data)
    debug {puts "Sending out #{data}"}
    data.unshift(prefix)
    dat = Marshal.dump(data)
    socket.send("#{dat}\n", 0)
  end

  # Broadcasts data to all clients
  # - _sender_ If there is a message sender
  # - _prefix_ Data prefix to use
  # - _*msg_ Data to send
  def broadcast(sender, prefix, *msg)
    if prefix == MSG && msg[0] == PART
      puts "User #{msg[1]} leaves us." 
      $log.info("User #{msg[1]} leaves us.")
    elsif prefix == MSG && !sender.nil?
      puts "#{sender.name}: #{msg}"
      $log.info("#{sender.name}: #{msg}")
    end

    $users.each do |user|
      if sender.nil?
        send(user.address, user.port, prefix, *msg)
      else
        send(user.address, user.port, prefix, sender.name, *msg)
      end
    end
  end

  # Un-gzips and Un-Marshals data.
  # - _data_ Data to parse
  def receive_data(data)
    message = Marshal.load(data)

    port, address = Socket.unpack_sockaddr_in(self.get_peername)
    prefix = message[0]
    user = $users.select {|x| x.address == address}[0]
    msg = message[1..-1]

    consts = Constants.constants
    consts.each do |const|
      const_prefix = Constants.const_get(const)
      if prefix == const_prefix
        self.__send__("data_#{const.downcase}", msg, user, address, port)
      end
    end
  end
end

