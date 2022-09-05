# frozen_string_literal: true

require_relative '../docker/docker'

class Stage
  @queue = :stage

  def self.perform(project, project_settings, build, dockerfile)
    project = Project.new(project, project_settings, Resque.redis.get(project))
    docker = Docker.new("workspace/#{project.name}/#{build}")
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
      Resque.enqueue(Deploy, project.name, project_settings, build, dockerfile)
    else
      Resque.enqueue(Stage, project.name, project_settings, build, dockerfile)
    end
  end
end
