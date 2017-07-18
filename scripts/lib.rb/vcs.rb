require 'git'
require 'logger'
require_relative 'os'

class Vcs

  def initialize(repo: nil, name: nil, workdir: nil)
    @workdir = !workdir ? __dir__ : workdir
    if repo && !name
      Logger.err "VCS: wanted to clone repo without supplying a name"
      exit 1
    end
    if repo
      @repoDir = "#{@workdir}/#{name}"
      if File.directory?(@repoDir)
        @g = Git.open(@repoDir, :log => Logger.new(STDOUT))
        # Logger.log "instantiating git for #{@repoDir}"
      else
        @g = Git.clone(repo, name, { :path => @workdir, :log => Logger.new(STDOUT)})
        # Logger.log "Cloned #{repo} in #{@workdir}"
      end
    else
      @g = Git.open(@workdir, :log => Logger.new(STDOUT))
      # Logger.log "instantiating git for #{@workdir}"
    end
  end

  def config(key, value)
    @g.config(key, value)
  end

  def checkout(branch)
    @g.checkout(branch)
  end

  def pull(branch)
    r = @g.pull "origin", branch
    # Logger.log "git pull: #{r}"
  end

  def fetch()
    r = @g.fetch
    # Logger.log "git fetch: #{r}"
  end

  def reset()
    r = @g.reset
    # Logger.log "git reset: #{r}"
  end

  def reset_hard()
    r = @g.reset_hard
    # Logger.log "git reset_hard: #{r}"
  end

  def mergemaster
    oldDir = __dir__
    Dir.chdir @repoDir
    r = OS.runCmd "git merge -s recursive -X theirs master -q"
    # Logger.log "git merge: #{r}"
    Dir.chdir oldDir
  end

  def rebase(branch)
    oldDir = __dir__
    Dir.chdir @repoDir
    r = OS.runCmd "git rebase master"
    # Logger.log "git rebase: #{r}"
    Dir.chdir oldDir
  end

  def status
    r = OS.runCmd "git --work-tree=#{@repoDir} status"
    # Logger.log "git status: #{r}"
  end

  def reset
    r = @g.reset
    # Logger.log "git reset: #{r}"
  end

  def addAndCommit(path, msg)
    if(path)
      r =@g.add(path)
      # Logger.log "git add: #{r}"
    end
    msg = "automated commit by [#{ENV['USER']}]" if !msg
    r = @g.commit(msg)
    # Logger.log "git commit: #{r}"
  end

  def push(branch)
    r = @g.push "origin",branch
    # Logger.log "git push: #{r}"
  end

end
