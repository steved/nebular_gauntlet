# Timer class to use with timed actions
#
# Author::    Steven Davidovitz (mailto:steviedizzle@gmail.com)
# Copyright:: Copyright (c) 2006, The Nebular Gauntlet DEV team
# License::   GPL
#

class Timer
  def initialize
    @interrupts = []
    @recurring = []
  end

  def run
    @interrupts.select {|k| k[:run] < SDL.get_ticks}.each do |interrupt|
      interrupt[:block].call
      if @recurring.include?(interrupt[:id])
        interrupt[:run] = SDL.get_ticks + interrupt[:length]
      else
        @interrupts.delete(interrupt)
      end
    end
  end

  # Add a timer interrupt
  # - _length_ Time until action is called. In milliseconds.
  # - _start_block_ Action to be called when added
  # - _end_block_ Action to be called after _length_ amount of time
  def add(length, start_block, end_block, recurring = false)
    start_block.call
    @interrupts << {:id => @interrupts.length, :length => length, :block => end_block, :run => SDL.get_ticks + length}
    @recurring << @interrupts[-1][:id] if recurring
    @interrupts.length - 1 # Return timer id
  end

  def delete(id)
    return if id.nil?
    @interrupts.delete_at(id)
    @recurring.delete(id)
  end
end
