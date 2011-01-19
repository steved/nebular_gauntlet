# The UI module encompasses the Interface class and all it's elements
# to display different types of user interfaces on screen.
#
# Author::    Steven Davidovitz (mailto:steviedizzle@gmail.com)
# Copyright:: Copyright (c) 2006, The Nebular Gauntlet DEV team
# License::   GPL
#

module UI
  TEXT_SHADOW = 0
  TEXT_COLOR = [230, 0, 0]
  TEXT_SELECTED = [255, 255, 255]
  BORDER_COLOR = [120, 0, 0]
  HLINE_COLOR = [0, 0, 0]
  FADE_CONTROL = 1

  # Base class that controls all widgets
  class Interface
    def initialize
      @elements = []
      @modal = 0
    end

    def draw
      @elements.each do |element|
        element.draw if !element.hidden?
      end
    end

    def add(element)
      @elements << element
      @modal += 1 if element.modal
    end

    def remove(element)
      @modal -= 1 if element.modal && @modal > 0
      @elements.delete(element)
    end

    def hide(element)
      element.hidden = true
    end

    def show(element)
      element.hidden = nil
    end

    def keypress?(key)
      if @modal > 0
        @elements[-1].keypress?(key)
      else
        @elements.each do |element|
          element.keypress?(key)
        end
      end
    end
  end

  # Base class on which all widgets are based.
  class Element
    attr_reader :modal
    attr_accessor :hidden

    def initialize(screen)
      @screen = screen
      @modal = false
      @hidden = nil
    end

    def draw
    end

    def keypress?(key)
    end

    def hidden?
      !@hidden.nil?
    end
  end

  # 4-Sided Rectangle
  class Box < Element

    # - _bcol_ Background color
    # - _fcol_ Foreground color
    def initialize(screen, height = 200, width = 200, bcol = [230,0,0], fcol = [40,40,40])
      super(screen)
      @height, @width, @bcol, @fcol = height, width, bcol, fcol
      @x = @y = 0
    end

    def draw
      @screen.draw_rect(@x, @y, @width, @height, @bcol)	
    end
  end

  # Class to diplay scores
  class Scoreboard < Box
    def initialize(screen, font, gametype)
      super(screen)
      @gametype = gametype
      @width = screen.w * (2 / 3)
      @height = screen.h * (2 / 3)
      @x = screen.w - (screen.w * (4 / 5))
      @y = screen.h - (screen.h * (4 / 5))
      @hidden = true
      @bcol = [255, 255, 255]

      @score_text = []
      @header = []
      @font = font
      title = Text.new(@screen, @font, @x + 25, @y + 25, "Server Name", [255, 255, 255])
      score = Text.new(@screen, @font, @x + @width - 50, @y + 25, "Kills", [255, 255, 255])
      kills = Text.new(@screen, @font, @x + @width - 150, @y + 25, "Score", [255, 255, 255])
      @header << title << score << kills
      if ["ctf", "tdm"].include?(@gametype)
        red = Text.new(@screen, @font, @x + 25, @y + 50, "Red Team", [255, 255, 255])
        blue = Text.new(@screen, @font, @x + 25, @y + (@height / 2), "Blue Team", [255, 255, 255])
        @header << red << blue
      end
    end

    def draw
      super
      @header.each {|x| x.draw}
      @score_text.each {|x| x.draw}
    end

    def scores=(scores)
      @scores = scores
      @score_text = []
      if ["ctf", "tdm"].include?(@gametype)
        @scores.each do |teams|
          teams.each_with_index do |score, index|
            y = @y + (index + 3) * 25 + (150 * @scores.index(teams))
            name = Text.new(@screen, @font, @x + 25, y, score[0].to_s, [255, 255, 255])
            kills = Text.new(@screen, @font, @x + @width - 25, y, score[1].to_s, [255, 255, 255]) 
            score = Text.new(@screen, @font, @x + @width - 125, y, score[2].to_s, [255, 255, 255]) 
            @score_text << name << kills << score
          end
        end
      else
        @scores.each_with_index do |user, index|
          y = @y + (index + 2) * 25
          name = Text.new(@screen, @font, @x + 25, y, user[0].to_s, [255, 255, 255])
          kills = Text.new(@screen, @font, @x + @width - 25, y, user[1].to_s, [255, 255, 255]) 
          score = Text.new(@screen, @font, @x + @width - 125, y, user[2].to_s, [255, 255, 255]) 
          @score_text << name << kills << score
        end
      end
    end
  end

  # Draws text at specified position
  class Text < Element
    attr_accessor :color, :text
    def initialize(screen, font, x, y, text, color = TEXT_COLOR)
      super(screen)
      @font, @text, @color, @x, @y = font, text, color, x, y
    end

    def draw
      return if @text.empty?

      if TEXT_SHADOW == 1
        @font.draw_blended_utf8(@screen, @text, @x + 2, @y + 2, 0, 0, 0)
      end

      @font.draw_blended_utf8(@screen, @text, @x, @y, *@color)
    end
  end

  # Centered text according to box limits
  class CenteredText < Text
    attr_reader :text
    def initialize(screen, font, x, y, boxw, boxh, text, color = TEXT_COLOR)
      super(screen, font, x, y, text, color)
      @yo = y
      center_text(@x, boxw, boxh)
    end

    def center_text(x, boxw, boxh)
      # Set the x,y back to originals so as not to have a moving text effect
      text_width, text_height = @font.text_size(@text)
      @x = x + (boxw / 2) - (text_width / 2)
      @y = @yo + (boxh / 2) - (text_height / 2) + 1
    end
  end

  # A horizantal line
  class Hline < Element
    def initialize(screen, x, y, height = 4, width = 200, color = HLINE_COLOR)
      super(screen)
      @x, @y, @width, @height, @color = x, y, width, height, color
    end

    def draw
      (1..@height).each do |i|
        @screen.draw_line(@x, @y + i, @x + @width, @y + i, @color)
      end
    end
  end

  # Box with centered text
  class MessageBox < Element
    # - _messages_ Array of messages to display
    def initialize(screen, font, x, y, messages)
      super(screen)
      @x, @y, @messages, @font, @bcolor, @tcolor = x, y, messages, font, BORDER_COLOR, TEXT_COLOR

      calc_long
      add
    end

    # Calculates longest message according to text size
    def calc_long
      @width = 0

      @messages.each_index do |i|
        length = @font.textSize(@messages[i])[0] + 10
        @width = length if length > @width
      end

      @height = @messages.length * @font.height

      @text_y = @y - @height + (@font.height / 2)
      @text_x = @x - (@width / 2)
    end

    def add
      @text = []

      @messages.each do |message|
        @text << CenteredText.new(@screen, @font, @text_x, @text_y, @width, @height, message, @tcolor)
        @text_y += @font.height				
      end
    end

    def draw
      # The following is to re-center all the text (along with text.center_text)
      @messages = []

      @text.each do |text|
        @messages << text.text
      end

      calc_long

      @screen.draw_rect(@x - (@width / 2), @y - (@height / 2), @width, @height, [255, 255, 255], true, 200)
      @screen.draw_rect(@x - (@width / 2), @y - (@height / 2), @width, @height, @bcolor)

      @text.each do |text|
        text.center_text(@x - (@width / 2), @width, @height)
        text.draw
      end
    end
  end

  # MessageBox that responds to keypress
  class Prompt < MessageBox

    # - _action_ What to do on keypress
    # - _messages_ Messages to display
    def initialize(screen, font, x, y, action, messages)
      super(screen, font, x, y, messages)
      @action = action
      @modal = true
    end

    def keypress?(key)
      @action.call(key.sym, self)
    end
  end

  class InputBox < MessageBox
    require 'lib/console/input'
    require 'lib/console/keyboard'
    include Keyboard
    include Input

    # - _input_ Input character
    # - _action_ What to do on key Enter press
    def initialize(screen, font, x, y, input, action, escape)
      super(screen, font, x, y, [input, ""])
      @modal = true
      @action = action
      @escape = escape
      @buffer = @text[1].text
      @cursor_pos = 0
    end

    def keypress?(key)
      case key.sym
      when SDL::Key::SPACE
        insert(" ")
      when SDL::Key::BACKSPACE
        @buffer.slice!(@cursor_pos - 1..@cursor_pos - 1) unless @cursor_pos == 0
        cursor_left
      when SDL::Key::DELETE
        @buffer.slice!(@cursor_pos..@cursor_pos)
      when SDL::Key::RETURN
        @action.call(@buffer, self) if @buffer.length > 0
      when SDL::Key::LEFT
        cursor_left
      when SDL::Key::RIGHT
        cursor_right
      when SDL::Key::ESCAPE
        @escape.call(self)
      else
        display_key(key.sym, key.mod)
      end
    end
  end

  # A base menu class
  class Menu < MessageBox

    # - _messages_ Array of messages to display
    def initialize(screen, font, messages)
      @x, @y = screen.w / 2, screen.h / 2
      super(screen, font, @x, @y, messages.collect{|i| i[0]})

      @actions = messages.collect{|i| i[1]}

      @selected = 0
      select(@selected)
    end

    def select(text)
      if text >= 0 && text < @text.length
        @text[@selected].color = TEXT_COLOR
        @text[text].color = TEXT_SELECTED
        @selected = text
      end
    end

    def keypress?(key)
      case key.sym
      when SDL::Key::UP
        select(@selected - 1)
      when SDL::Key::DOWN
        select(@selected + 1)
      when SDL::Key::LEFT, SDL::Key::RIGHT, SDL::Key::RETURN
        @actions[@selected].call(@text[@selected], key.sym)
      end
    end
  end

  # An image that is part of the intro sequence
  class IntroImage < Element
    attr_reader :alpha

    # - _image_ Image for intro
    def initialize(screen, image)
      super(screen)
      @image = image
      @alpha = 0
      @fade = 0

      center_image
    end

    # Centers image in middle of screen
    def center_image
      @x = (@screen.w / 2) - (@image.w / 2)
      @y = (@screen.h / 2) - (@image.h / 2)
    end

    # Fades image in by controlling alpha
    def fade_in
      if @alpha + FADE_CONTROL <= 255
        @alpha += FADE_CONTROL
      else
        @fade = 1
      end
    end

    # Fades image out
    def fade_out
      @alpha -= FADE_CONTROL if @alpha >= 0
    end	

    def draw
      if @fade == 0
        fade_in
      elsif @fade == 1
        fade_out
      end
      @image.set_alpha(SDL::SRCALPHA || SDL::RLEACCEL, @alpha)
      @screen.put(@image, @x, @y)
    end
  end

  # Displays introduction video/images
  class Intro < Element

    # - _lambda_ What to do when intro ends
    # - _*images_ Images in sequence
    def initialize(screen, lambda, *images)
      super(screen)

      @images = images
      @image = []
      @selected = 0
      $box_width, $box_height = @screen.w, @screen.h
      @ending = lambda

      add()
    end

    def add
      @images.each do |image|
        @image << IntroImage.new(@screen, image)
      end
    end

    def draw
      @screen.fill_rect(0, 0, @screen.w, @screen.h, 0)
      if @image.length != 0
        @image[0].draw					
        if @image[@selected].alpha == 0 #&& @selected + 1 < @image.length
          @image.delete_at(@selected)
        end
      else
        @ending.call
      end
    end
  end

  # Draws progress bar according to orientation
  class ProgressBar < Element

    # - _orientation_ Horizantal or Vertical
    # - _max_ Maximum percent
    # - _x_ Start position: x 
    # - _y_ Start position: y
    # - _reset_ Whether or not to reset to 0 after max
    # - _speed_ Speed multiplier
    def initialize(screen, orientation, max, x, y, reset = 0, speed = 1)
      super(screen)

      @reset, @max, @progress, @orientation, @speed = reset, max, 0, orientation, speed

      case @orientation
      when 0 # Vertical
        @w = 25
        @h = max
        @x = x
        @y = y - (@h / 2)
      when 1 # Horizantal
        @h = 25
        @w = max
        @x = x - (@w / 2)
        @y = y
      end
    end

    def draw
      @screen.draw_rect(0, 0, @screen.w, @screen.h, 0, true)
      @screen.draw_rect(@x, @y, @w, @h, [255, 255, 255])

      if @orientation == 0
        @screen.draw_rect(@x, @y, @w, @progress, [255, 255, 255], true)
      else
        @screen.draw_rect(@x, @y, @progress, @h, [255, 255, 255], true)
      end

      @screen.flip
    end

    def update(percent)
      @progress = percent if percent < @max
      draw
    end
  end

  # Specialized Progress bar class that is cleared when a ship fires
  class FireBar < Element

    # - _firetimeout_ How long until ship can fire again
    def initialize(screen)
      super(screen)

      @fillrect = 0
    end

    def draw
      @fillrect = - (100 - ((($ship.fireTimer - Time.now) / $ship.weapon["reload"]) * 100)) if $ship.fireTimer - Time.now >= 0

      @screen.draw_rect(@screen.w - 25, @screen.h, 25, @fillrect, [255, 255, 255], true, 255)
    end
  end

  # Square radar for use with entities
  class Radar < Box
    def initialize(screen, size_modifier, *objects)
      @size = size_modifier
      height = $map.h / @size
      width = $map.w / @size
      super(screen, height, width)
      @objects = objects
    end

    def draw
      @screen.draw_rect(@x, @y, @width, @height, @bcol)
      @objects.each do |obj|
        @screen.draw_circle(0 + (obj.x / @size), 0 + (obj.y / @size), 2, [200, 200, 200], true) if obj.state == :alive
      end
    end
  end
end		
