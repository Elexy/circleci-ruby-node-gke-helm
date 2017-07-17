require 'mkmf'
require_relative 'logger'

class OS

  @existingCommands = {}

  def self.runCmd(cmd, exitIfFails=false, verbose=false)
  	Logger.log "RUN - #{cmd}"
    fileName = "outfile#{rand(10000)}"
    if self.cmdExists(cmd)
    	result = system("#{cmd} > /tmp/#{fileName}")
    	if exitIfFails && !result
    		puts ""
    		exit
    	end
    	begin
    		aFile = File.open("/tmp/#{fileName}", "r")
    		output = aFile.read
    		Logger.log(output) if verbose
        File.delete("/tmp/#{fileName}")
    	rescue SystemCallError
    		Logger.log("---")
    	end
    	return output
    else
      Logger.err("#{cmd} not found")
    end

  end

  def self.cmdExists(cmdString)
    cmd = cmdString.split(' ')[0]
    if @existingCommands[cmd]
      return true
    end
    check = find_executable(cmd)
    @existingCommands[cmd] = true
    return check
  end

  def self.scriptDir
    File.expand_path(File.dirname(__FILE__))
  end

end
