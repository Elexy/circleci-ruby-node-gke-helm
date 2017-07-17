
def colorize(text, color_code)
  "#{color_code}#{text}\e[0m"
end

def red(text); colorize(text, "\e[31m"); end
def green(text); colorize(text, "\e[32m"); end
#  + green('DONE') +

class Logger

  def self.err (msg)
  	puts "---> [" + red('ERROR')+ "] #{msg}"
  end

  def self.log(msg, level="info")
  	if msg.length
      puts "-> #{msg}"
  	end
  end
  def self.heading(msg, level="info")
    if msg.length
      puts "-> " + green(msg)
    end
  end

end
