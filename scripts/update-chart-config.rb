#!/usr/bin/ruby

require 'trollop'
require 'yaml'
require 'tmpdir'

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

def updateValues (workdir, branch, project, tag)
  user = ENV['TRIGGER_USER'] || "update-chart-values.rb"
  git = Vcs.new(repo: $repoUrl, name: $repoName, workdir: workdir)
  #git.fetch
  git.reset_hard
  git.checkout('master')
  git.pull('master')
  git.checkout(branch)
  git.pull(branch)
  git.mergemaster
  #git.status

  chartConfig="#{workdir}/#{$repoName}/dgs/values.yaml"
  d = YAML::load_file(chartConfig)
  if d.dig(project, 'image')
    oldImg = d[project]['image']
    if oldImg !=  "#{project}:#{tag}"
      d[project]['image'] = "#{project}:#{tag}"
      File.open(chartConfig, 'w') { |f| YAML.dump(d, f) }

      git.addAndCommit(chartConfig, "chore(deploy) updated from [#{oldImg}] to [#{d[project]['image']}] by #{user}")
      git.push(branch)
    else
      Logger.err "not deployed, no change: #{oldImg} == #{project}:#{tag}"
    end

  else
    Logger.err "Yaml path '#{project}.image' not found"
  end

end

opts = Trollop::options do
  version "test 0.0.1 (c) 2017 Alex Knol, nearForm"
  banner <<-EOS
This script will update a values.yml for the DGS chart for you according to the paranmeters:

Usage:
       test [options] <filenames>+
where [options] are:
EOS

  opt :repo, "Git repository containing the helm chart",
        :type => String
  opt :workdir, "Working directory",
        :type => String
  opt :branch, "Environment branch",
        :type => String
  opt :project, "Project to be updated",
        :type => String
  opt :tag, "Image (including tag)",
        :type => String
end
Trollop::die :repo, "required" if !opts[:repo]
Trollop::die :branch, "required" if !opts[:branch]
Trollop::die :project, "required" if !opts[:project]
Trollop::die :tag, "required" if !opts[:tag]
workdir = Dir.tmpdir() if !opts[:workdir]

$repoUrl = opts[:repo]
$repoName = /\/([\w|-]+)\.git/.match($repoUrl)

Logger.log "projectname: #{reponame}"

Logger.log "using this working directory: #{workdir}"

Logger.log "updating branch [#{opts[:branch]}] for project [#{opts[:project]}] with tag [#{opts[:tag]}].\n"

updateValues(workdir, opts[:branch], opts[:project], opts[:tag])
