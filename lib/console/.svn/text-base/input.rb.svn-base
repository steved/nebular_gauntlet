# Module to parse key and mod to take into account special keys and
# extend Ruby/SDL's key parsing
#
# Author::    Steven Davidovitz (mailto:steviedizzle@gmail.com)
# Copyright:: Copyright (c) 2006, The Nebular Gauntlet DEV team
# License::   GPL
#


module Input

  # Parses key and mod and calls insert
  # - _sym_ Key that is pressed
  # - _mod_ Mod key if pressed
  def display_key(sym, mod)
    if mod == SDL::Key::MOD_NONE || mod == 4096
      unless sym >= 300 && sym <= 310 || sym == 271 || sym == 9 || sym == 319
        if SDL::Key.get_key_name(sym).length <= 1
          insert(SDL::Key.get_key_name(sym))
        end
      end
    elsif mod == (SDL::Key::MOD_LSHIFT || SDL::Key::MOD_RSHIFT) || mod == (4097 || 4098)
      case sym
      when 96
        insert("~")
      when 49
        insert("!")
      when 50
        insert("@")
      when 51
        insert("#")
      when 52
        insert("$")
      when 53
        insert("%")
      when 54
        insert("^")
      when 55
        insert("&")
      when 56
        insert("*")
      when 57
        insert("(")
      when 48
        insert(")")
      when 45
        insert("_")
      when 61
        insert("+")
      when 91
        insert("{")
      when 92
        insert("|")
      when 93
        insert("}")
      when 59
        insert(":")
      when 39
        insert('"')
      when 44
        insert("<")
      when 46
        insert(">")
      when 47
        insert("?")
      else
        if SDL::Key.get_key_name(sym).length <= 1
          insert(SDL::Key.get_key_name(sym).capitalize)
        end
      end
    elsif mod == SDL::Key::MOD_CAPS || mod == 12288
      unless sym >= 300 && sym <= 310 || sym == 271 || sym == 9 || sym == 319
        if SDL::Key.get_key_name(sym).length <= 1
          insert(SDL::Key.get_key_name(sym).capitalize)
        end
      end
    end
  end	

  # Inserts str into buffer at cursorPos
  # - _str_ String to insert
  def insert(str)
    @buffer.insert(@cursor_pos, str)
    @cursor_pos += 1
  end
end
