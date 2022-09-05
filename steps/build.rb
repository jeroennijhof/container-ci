# frozen_string_literal: true

require_relative '../docker/docker'

class Build
  @queue = :build

  def self.perform(project, project_settings, build, dockerfile)
    project = Project.new(project, project_settings, Resque.redis.get(project))
    docker = Docker.new("workspace/#{project.name}/#{build}")
    message = ''

    project.builds[build].steps['build'] = { 'status' => 'running' }
    Resque.redis.set(project.name, project.builds.to_json)
    dockerfile['stages'].each do |stage|
      message += "<br/>Building stage: #{stage}<br/><br/>"
      docker.build('.', '--target', stage, '-t', "#{project.name}/#{stage}:latest") do |stdout|
        message += stdout
        project.builds[build].steps['build']['message'] = message
        Resque.redis.set(project.name, project.builds.to_json)
      end
    end
    dockerfile['stages'].shift
    project.builds[build].steps['build']['status'] = 'success'
    Resque.redis.set(project.name, project.builds.to_json)
    Resque.enqueue(Stage, project.name, project_settings, build, dockerfile)
  end
end
