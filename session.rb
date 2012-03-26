#!/usr/bin/ruby
require 'commander/import'

program :name, 'session'
program :version, '1.0.0'
program :description, 'A CLI to using the xpra tool to save session names and manage'

#Eventually to be read from a config file
range = "200-300"

sessions = Hash.new


#Start a xpra session
command :start do |c|
	c.syntax = "session start [options]"
	c.description = "Starts an xpra session"

	c.option '--run STRING',  String, "Specifies a command to start with the session"
	c.option '--name STRING', String, "Specifies the name of the session"

	c.action do |args, options|
		options.default :run=> 'return', :name => 'session-'
		puts "Starting xpra with #{options.run} under #{options.name}"

		#Create new session
		if sessions[options.name] then
			puts "session name already exists, please use a different name"
		else 
			sessions[options.name] = {
				:display => sessions.each[:display].max,
				:run => options.run
			}
		end


	end
end


#List sessions
command :list do |c|
	c.syntax = 'session list'
	c.description = 'Displays a list of the sessions currently managed'
	c.action do |args|
	end
end

#Function to write the list to the conf file
def writeList

end

#Function to read the list from the conf file
def readList

end
