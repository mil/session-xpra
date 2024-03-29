#!/usr/bin/ruby
require 'commander/import'
require 'json'

program :name, 'session'
program :version, '1.0.0'
program :description, 'A CLI to using the xpra tool to save session names and manage'





#Uber simway to colorize outputin
class String
	def color(c)
		colors = { 
			:black   => 30, 
			:red     => 31, 
			:green   => 32, 
			:yellow  => 33, 
			:blue    => 34, 
			:magenta => 35, 
			:cyan    => 36, 
			:white   => 37 
		}
		return "\e[#{colors[c] || c}m#{self}\e[0m"
	end
end


puts "test"

$sessionsFile = "#{ENV['XDG_DATA_HOME']}/session-xpra/sessions"
$sessions = Hash.new

#Eventually to be read from a config file
range = {
	:min => 270,
	:max => 300
}

#Start a xpra session
command :start do |c|
	c.syntax = "session start [options]"
	c.description = "Starts an xpra session"

	#Required
	c.option '--run STRING',  String, "Specifies a co"
	c.description = "Starts an xpra session"

	#Required
	c.option '--run STRING',  String, "Specifies a commmand to start with the session"

	#Optional
	c.option '--name STRING', String, "Specifies the name of the session"

	c.action do |args, options|

		loadSessions

		#Get next highest display
		nextDisplay = range[:min]

		$sessions.each do |key, session|
			nextDisplay = [session["display"].to_i, nextDisplay].max
		end
		nextDisplay += 1

		#Set Defaults
		options.default :run=> 'return', :name => "session-#{nextDisplay}"
		puts "Trying to start xpra with #{options.run} under #{options.name}"

		#Error Checks
		[
			[ $sessions[options.name],      "Session name already exists"         ],
			[ (nextDisplay > range[:max]), "Display is out of range"             ],
			[ (options.run == 'return'),   "You must specify an initial command" ]
		].each do |condition, error|
			if (condition) then
				puts error 
				exit
			end
		end
	
		#Fire to xpra
		%x[xpra start :#{nextDisplay}]
		sleep 1
		%x[DISPLAY=:#{nextDisplay} #{options.run} & disown]

		$sessions[options.name] = {
			"display" => nextDisplay,
			"run"     => options.run
		}

		storeSessions
	end
end


#List sessions
command :list do |c|
	c.syntax = 'session list'
	c.description = 'Displays a list of the sessions currently managed'
	c.action do |args|
		loadSessions

		puts "Session Name\tCommand\t\tDisplay"
		$sessions.each do |name, info|
			puts "#{name.color(:green)}\t\t#{info['run'].color(:red)}\t\t#{info['display'].to_s.color(:blue)}"
		end

	end
end

command :attach do |c|
	c.syntax = 'session attach session-name'
	c.description = "Attach a session to the current display"
	c.option '--name STRING', String, "Specifies the name of the session"
	c.action do |args|
		loadSessions

		$sessions.each do |name,info|
		end


		storeSessions
	end



end

command :clear do |c|
	c.syntax      = 'session clear'
	c.description = "Clears all sessions"
	c.action do |args|
		loadSessions

		puts "Clearing all sessions"
		$sessions.each do |name, info|
			%[xpra stop :#{info['display']}]
		end
		%[killall xpra]

		$sessions = {}
		storeSessions

	end
end

#Function to write the list to the conf file
def storeSessions 
	sessionJson = JSON($sessions)
	File.open($sessionsFile, 'w') do |f|
		f.puts sessionJson
	end	
end

#Function to read the list from the conf file
def loadSessions 
	#Convert serialized JSON into sessionsS
	begin
		$sessions = JSON.parse(File.read($sessionsFile).to_s)
	rescue 
		puts "Unable to parse JSON"
	end
end

