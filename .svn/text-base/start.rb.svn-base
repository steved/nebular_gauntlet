Dir.chdir(File.expand_path(File.dirname(__FILE__)))

require 'lib/engine'
require 'lib/intro'
require 'lib/menus'

@engine = Engine.new # Base engine

@engine.set_title("Loading...")
@engine.init

@engine.change_state(Intro.new) # Push the intro state
@engine.set_title("Nebular Gauntlet") 
@engine.start

@engine.set_title("Quitting...")
