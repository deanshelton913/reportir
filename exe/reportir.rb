require 'reportir'
require 'thor'

require "thor"
 
class MyCLI < Thor
  desc "install", "add rspec configuration"
  def install
    puts "Hello install"
  end
end
 
MyCLI.start(ARGV)