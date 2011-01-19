# Module for Core methods that are needed by classes that aren't subclasses of Engine
#
# Author::    Steven Davidovitz (mailto:steviedizzle@gmail.com)
# Copyright:: Copyright (c) 2006, The Nebular Gauntlet DEV team
# License::   GPL
#

module Core
  # Loads selected image and returns display format for fast blitting and collision map if requested
  # - _image_ Filename of image
  # - _collisionMap_ If set to true, generate a collision map
  def load_image(image, collision_map = false, srccolorkey = [0, 0, 0])
    temp1 = SDL::Surface.load(image)
    temp1.set_color_key(SDL::SRCCOLORKEY | SDL::RLEACCEL, srccolorkey)
    if collision_map
      temp2 = temp1.display_format
      temp_map = temp1.make_collision_map
      return temp2, temp_map
    else
      temp1
    end
  end

  # Loads file according to file suffix
  # - _file_ Filename of sound
  def load_sound(file)
    begin
      suffix = file.split(".")[-1]
      if suffix == "wav"
        SDL::Mixer::Wave.load(file)
      else
        SDL::Mixer::Music.load(file)
      end
    rescue => e
      puts "Error loading sound file #{file}:"
      puts e
    end
  end

  # Plays a sound from the sounds array
  # - _name_ Name of sound
  # - _loops_ Number of loops to play
  def play_sound(name, loops = 0)
    return if !(SDL.inited_system(SDL::INIT_AUDIO) & SDL::INIT_AUDIO) || $config['user']['sound'] == "off"

    sound = @@sounds[name]

    begin
      if sound.class == SDL::Mixer::Wave
        SDL::Mixer.play_channel(-1, sound, loops)
      else
        SDL::Mixer.play_music(sound, loops)
      end
    rescue => e
      puts "Could not play sound."
      puts e
    end
  end

  # Loads font from filename
  # - _file_ Filname of font
  # - _size_ Size to load
  def load_font(file, size)
    begin
      SDL::TTF.open(file, size)
    rescue => e
      puts "Error loading font file #{filename}:"
      puts e
    end
  end

  # Load YAML-based configuration file
  # - _filename_ File from which to load
  def load_config(filename)
    begin
      $config = YAML::load(File.open(filename))

      $keys = {}
      $config['keys'].each do |name, value|
        $keys[name] = SDL::Key.const_get(value)
      end

      if $config['user']['sound'] != "off"
        SDL::Mixer.set_volume(-1, $config['user']['volume'])
      end
    rescue => e
      puts "Error loading config file #{filename}:"
      puts e
    end
  end

  # Loads YAML-based sounds file
  # - _filename_ File to load from
  def load_sounds(filename)
    begin
      @@sounds = YAML::load(File.open(filename))

      @@sounds.each do |name, value|
        @@sounds[name] = load_sound(@@sounds[name])
      end
    rescue => e
      puts "Error loading sound file #{filename}:"
      puts e
    end
  end

  # Dumps YAML config to file
  # -  _filename_ File to dump config to
  def save_config(filename, reload = true)
    File.open(filename, "w") {|f| YAML.dump($config, f)}
    load_config(filename) if reload
  end

  # Adds a fire entity to global array
  # - _entity_ Entity that the weapon belongs to
  def add_fire(entity)
    weapon = entity.weapon
    weapons = $weapons.select{|k, v| v == weapon}
    if RUBY_VERSION =~ /1.8/
      play_sound(weapons[0][0])
    else
      play_sound(weapons.keys[0])
    end
    scatter = 30
    (1..weapon["num"]).each do |i|
      scatter = rand(30) if weapon["scatter"] == "random"
      angle = entity.angle.send((i % 2 == 0 ? "+" : "-"), (scatter * (i / 2).to_i))
      $fires << Weapon.new(entity, weapon, $fires.length - 1, angle)
    end
    entity.reset_firetimer
  end

  # Get the next numbered filename. Used for savegames.
  # - _dir_ Directory to use
  # - _pattern_ Pattern to match
  # - _suffix_ Suffix to apply
  def next_file_name(dir, pattern, suffix)
    files = Dir.glob(dir)
    number = 0

    files.each do |f|
      tnumber = f.slice(/#{pattern}[0-9]+\.#{suffix}/).delete("#{pattern}.").to_i
      number = tnumber if tnumber > number
    end

    "#{pattern}#{number + 1}"
  end
end

