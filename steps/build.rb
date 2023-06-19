# frozen_string_literal: true

require_relative '../lib/docker/docker'

class Build
  @queue = :build

  def self.perform(settings, project_name, build, dockerfile)
    project = Project.new(project_name, settings['projects'][project_name], Resque.redis.get(project_name))
    docker = Docker.new(settings, "workspace/#{project.name}/#{build}")
    message = ''

    project.builds[build].steps['build'] = { 'status' => 'running' }
    Resque.redis.set(project.name, project.builds.to_json)
    dockerfile['stages'].each do |stage|
      message += "<br/>Building stage: #{stage}<br/><br/>"
      docker.build('.', '--target', stage, '--no-cache', '-t', "#{project.name}/#{stage}:latest") do |stdout|
        message += stdout
        project.builds[build].steps['build']['message'] = message
        Resque.redis.set(project.name, project.builds.to_json)
      end
    end
    dockerfile['stages'].shift
    project.builds[build].steps['build']['status'] = 'success'
    Resque.redis.set(project.name, project.builds.to_json)
    Resque.enqueue(Stage, settings, project.name, build, dockerfile)
  end
end
