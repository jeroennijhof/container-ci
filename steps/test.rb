# frozen_string_literal: true

require_relative '../docker/docker'

class Test
  @queue = :test

  def self.perform(project, project_settings, build, stages)
    project = Project.new(project, project_settings, Resque.redis.get(project))
    docker = Docker.new("workspace/#{project.name}/#{build}")
    message = ''

    project.builds[build].steps['test'] = { 'status' => 'running' }
    Resque.redis.set(project.name, project.builds.to_json)
    docker.run("#{project.name}/test") do |stdout|
      message += stdout
      project.builds[build].steps['test']['message'] = message
      Resque.redis.set(project.name, project.builds.to_json)
    end
    project.builds[build].steps['test']['status'] = 'success'
    Resque.redis.set(project.name, project.builds.to_json)
    Resque.enqueue(Deploy, project.name, project_settings, build, stages)
  end
end
