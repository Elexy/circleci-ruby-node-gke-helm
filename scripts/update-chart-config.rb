#!/usr/bin/ruby

require 'trollop'
require 'yaml'
require 'tmpdir'
require 'pathname'

require_relative 'lib.rb/logger'
require_relative 'lib.rb/vcs'
require_relative 'lib.rb/os'

# add dig to the hash class
class Hash
  def dig(*path)
    path.inject(self) do |location, key|
      location.respond_to?(:keys) ? location[key] : nil
    end
  end
end

opts = Trollop::options do
  version "update-chart-config 0.0.1 (c) 2017 Alex Knol, nearForm"
  banner <<-EOS
This script will update a values.yml for a Helm chart according to the paranmeters:

Usage:
       update-chart-config.rb [options] <filenames>+
where [options] are:
EOS

  opt :repo, "Git repository containing the helm chart",
        :type => String
  opt :chartpath, "Path inside the repo where the values.yaml file resides",
        :type => String
  opt :workdir, "Working directory",
        :type => String
  opt :branch, "Environment branch",
        :type => String
  opt :project, "Project to be updated",
        :type => String
  opt :tag, "Image (including tag)",
        :type => String
  opt :user, "Git user",
        :type => String
  opt :email, "Git email",
        :type => String

      end
Trollop::die :repo, "required" if !opts[:repo]
Trollop::die :chartpath, "required" if !opts[:chartpath]
Trollop::die :branch, "required" if !opts[:branch]
Trollop::die :project, "required" if !opts[:project]
Trollop::die :tag, "required" if !opts[:tag]
workdir = Dir.tmpdir() if !opts[:workdir]

repoUrl = opts[:repo]
repoName = /\/([\w|-]+)\.git/.match(repoUrl)[1]
gitUser = opts[:user] || 'automated commit'
gitEmail = opts[:email] || 'email"email.com'

Logger.log "projectname: #{repoName}"

Logger.log "using this working directory: #{workdir}"

Logger.log "updating branch [#{opts[:branch]}] for project [#{opts[:project]}] with tag [#{opts[:tag]}].\n"

user = ENV['TRIGGER_USER'] || "update-chart-values.rb"
git = Vcs.new(repo: repoUrl, name: repoName, workdir: workdir)
#git.fetch
git.config('user.name', gitUser)
git.config('user.email', gitEmail)
git.reset_hard
git.checkout('master')
git.pull('master')
git.checkout(opts[:branch])
git.pull(opts[:branch])

# run the mergeMaster script in the repo we just cloned
mergeScript = "/scripts/merge_master.sh"
repoBase = "#{workdir}/#{repoName}"
pn = Pathname.new("#{repoBase}")
puts pn
if pn.exist?
  Dir.chdir(repoBase) do
    OS.runCmd(pn.to_s)
  end
else
  Logger.log "Merge script not found at #{pn}"
  exit
end

chartConfig="#{workdir}/#{repoName}/#{opts[:chartpath]}/values.yaml"
Logger.log("updating chart config at: [#{chartConfig}]")
d = YAML::load_file(chartConfig)
if d.dig(opts[:project], 'image')
  oldImg = d[opts[:project]]['image']
  if oldImg !=  "#{opts[:project]}:#{opts[:tag]}"
    d[opts[:project]]['image'] = "#{opts[:project]}:#{opts[:tag]}"
    File.open(chartConfig, 'w') { |f| YAML.dump(d, f) }

    git.addAndCommit(chartConfig, "updated from [#{oldImg}] to [#{d[opts[:project]]['image']}] by #{user}")
    git.push(opts[:branch])
  else
    Logger.err "not updated, no change: #{oldImg} == #{opts[:project]}:#{opts[:tag]}"
  end

else
  Logger.err "Yaml path '#{opts[:project]}.image' not found"
end
