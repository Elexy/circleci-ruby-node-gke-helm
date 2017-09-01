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
  version "propagate 0.0.1 (c) 2017 Alex Knol, nearForm"
  banner <<-EOS
This script will propagate the image tags of <repo> from <chartpath>/values.yml from <source> branch to <target> branch:
Optionally provide Git user and email and Working directory.

Usage:
       propagate.rb [options] <filenames>+
where [options] are:
EOS

  opt :repo, "Git repository containing the helm chart",
        :type => String
  opt :chartpath, "Path inside the repo where the values.yaml file resides",
        :type => String
  opt :workdir, "Working directory",
        :type => String
  opt :source, "Origin branch",
        :type => String
  opt :target, "Target branch",
        :type => String
  opt :user, "Git user",
        :type => String
  opt :email, "Git email",
        :type => String

      end
Trollop::die :repo, "required" if !opts[:repo]
Trollop::die :chartpath, "required" if !opts[:chartpath]
Trollop::die :source, "required" if !opts[:source]
Trollop::die :target, "required" if !opts[:target]
workdir = Dir.tmpdir() if !opts[:workdir]

repoUrl = opts[:repo]
repoName = /\/([\w|-]+)\.git/.match(repoUrl)[1]
gitUser = opts[:user] || 'automated commit'
gitEmail = opts[:email] || 'email@email.com'

Logger.log "projectname: #{repoName}"

Logger.log "using this working directory: #{workdir}"

user = ENV['TRIGGER_USER'] || "update-chart-values.rb"
git = Vcs.new(repo: repoUrl, name: repoName, workdir: workdir)
git.config('user.name', gitUser)
git.config('user.email', gitEmail)
git.checkout(opts[:source])
git.pull(opts[:source])
# git.mergemaster

projects = ['backend','frontend','contentful_survey_editor']
images = {}
oldImages = {}

chartConfig="#{workdir}/#{repoName}/#{opts[:chartpath]}/values.yaml"
Logger.log("Getting image tags from branch: [#{opts[:source]}]")
d = YAML::load_file(chartConfig)

projects.each do |project|
  if d.dig(project, 'image')
    images[project] = d[project]['image']
  else
    Logger.err "Yaml path '#{project}.image' not found"
  end
end

git.branch(opts[:target]).checkout
git.branches.each do |branch|
  if /^remotes\/origin\/#{opts[:target]}$/.match(branch.to_s)
    puts branch.to_s
    git.pull(opts[:target])
  end
end

# puts images.inspect

# run the mergeMaster script in the repo we just cloned
mergeScript = "/scripts/merge_master.sh"
repoBase = "#{workdir}/#{repoName}"
pn = Pathname.new("#{repoBase}/#{mergeScript}")
puts pn
if pn.exist?
  Dir.chdir(repoBase) do
    OS.runCmd(pn.to_s)
  end
else
  Logger.log "Merge script not found at #{pn}"
  exit
end

Logger.log("Updating image tags in branch: [#{opts[:target]}]")

commitMsg = ''
changed = false
d = YAML::load_file(chartConfig)
projects.each do |project|
  oldImages[project] = d[project]['image']
  changed = true if images[project] != d[project]['image']
  if d.dig(project, 'image')
      d[project]['image'] = "#{images[project]}"
      commitMsg += "Updating #{project} from #{oldImages[project]} to #{images[project]}\n"
  else
    Logger.err "Yaml path '#{opts[:project]}.image' not found"
  end
end

File.open(chartConfig, 'w') { |f| YAML.dump(d, f) }

commitMsg += "by #{user}"
if changed
  git.addAndCommit(chartConfig, "#{commitMsg}")
else
  Logger.log "No real update:\n#{commitMsg}\n--> We will still push to make sure latest state is deployed."
end

git.push(opts[:target])
Logger.log "Push done, this is the end"
