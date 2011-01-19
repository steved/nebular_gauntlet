# Console that only shows chat
#
# Author::    Steven Davidovitz (mailto:steviedizzle@gmail.com)
# Copyright:: Copyright (c) 2006, The Nebular Gauntlet DEV team
# License::   GPL
#

require 'lib/console/console'

class Chat < Console

  # Initialize chat, default is inactive
  # - _screen_ Screen surface
  # - _font_ Font to use
  # - _height_ Height from top of window. A multiple of the font's height is recommended.
  # - _alpha_ Alpha (transparency) to set console to
  # - _activation_ Key which activates console
  # - _background_ Console background color
  # - _inputchar_ String to signify input line
  def initialize(screen, font, height, alpha = 255, activation = SDL::Key::T, background = [255, 255, 255], inputchar = "[>")
    super

    @y = 400
  end

  # Parses text and executes command if found
  # - _text_ Text to parse
  def execute_string(text)
    # Delete the last executed command so that only the result shows
    @console_view.delete_at(-1) 
    @console_archive.delete_at(-1)

    self.__send__("say", [text])

    # Reset buffer and cursorPos
    @buffer = "" 
    @cursor_pos = 0
  end

  # What to do on keypress
  # - _key_ Key which is pressed
  def keypress?(key)	
    if @active
      case key.sym	
      when SDL::Key::RETURN
        if @buffer != ""
          @command_archive << @buffer
          put(@buffer)
          execute_string(@buffer)
        end
        @active = false
      when SDL::Key::SPACE
        insert(" ")
      when SDL::Key::BACKSPACE
        @buffer.slice!(@cursor_pos - 1..@cursor_pos - 1) unless @cursor_pos == 0
        cursor_left
      when SDL::Key::DELETE
        @buffer.slice!(@cursor_pos..@cursor_pos)
      when SDL::Key::LEFT
        cursor_left
      when SDL::Key::RIGHT
        cursor_right
      when SDL::Key::ESCAPE
        @active = false
      else
        display_key(key.sym, key.mod)
      end
    else
      if key.sym == @activation
        @active = true
      end
    end
  end

  # Render chat
  def draw
    x = @font.text_size(@inputchar)[0] # Width of inputchar
    y = 0

    @screen.draw_rect(0, @y, @screen.w, @height, @background, true, @alpha)

    if @active
      @font.draw_blended_utf8(@screen, @inputchar, 0, @y + @height - @font.height, 255, 255, 255) # Draw input symbol 
      @font.draw_blended_utf8(@screen, @buffer, x, @y + @height - @font.height, 255, 255, 255) # Draw buffer
      @screen.draw_line(x + (@cursor_pos * @font.textSize("a")[0]), @y + @height - @font.height, x + (@cursor_pos * @font.textSize("a")[0]), @y + @height, [255, 255, 255])
    end

    @console_view.each do |message| # Draw each message that is in view
      @font.draw_blended_utf8(@screen, message[0], 0, @y + y, 255, 255, 255)
      y += @font.height
    end
  end
end


