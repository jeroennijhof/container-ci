# frozen_string_literal: true

require 'git'
require 'json'
require_relative '../models/project'

class Initialize
  @queue = :initialize

  def self.perform(project, project_settings, build)
    project = Project.new(project, project_settings, Resque.redis.get(project))
    project.builds[build].steps['initialize'] = { 'status' => 'running', 'message' => '' }
    Resque.redis.set(project.name, project.builds.to_json)

    git = Git.clone(project_settings['git'], "workspace/#{project.name}/#{build}")
    message = "Git commit #{git.log.last.sha}:<br/>#{git.log.last.message}"

    project.builds[build].steps['initialize'] = { 'status' => 'success', 'message' => message }
    Resque.redis.set(project.name, project.builds.to_json)
  end

  def self.parse_dockerfile
  end
end
