# frozen_string_literal: true

require_relative '../lib/docker/docker'

class Stage
  @queue = :stage

  def self.perform(settings, project_name, build, dockerfile)
    project = Project.new(project_name, settings['projects'][project_name], Resque.redis.get(project_name))
    docker = Docker.new(settings, "workspace/#{project.name}/#{build}")
    stage = dockerfile['stages'].shift
    message = ''

    project.builds[build].steps[stage] = { 'status' => 'running' }
    Resque.redis.set(project.name, project.builds.to_json)
    docker.run("#{project.name}/#{stage}") do |stdout|
      message += stdout
      project.builds[build].steps[stage]['message'] = message
      Resque.redis.set(project.name, project.builds.to_json)
    end
    project.builds[build].steps[stage]['status'] = 'success'
    Resque.redis.set(project.name, project.builds.to_json)
    if dockerfile['stages'].empty?
      Resque.enqueue(Deploy, settings, project.name, build, dockerfile)
    else
      Resque.enqueue(Stage, settings, project.name, build, dockerfile)
    end
  end
end
