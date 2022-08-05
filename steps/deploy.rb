# frozen_string_literal: true

require_relative '../docker/docker'

class Deploy
  @queue = :deploy

  def self.perform(project, project_settings, build, stages)
    project = Project.new(project, project_settings, Resque.redis.get(project))
    message = ''

    containers = { 'name' => project.name, 'image' => "#{project.name}/test" }
    project.builds[build].steps['deploy'] = { 'status' => 'running' }
    Resque.redis.set(project.name, project.builds.to_json)
    Docker.compose_down do |stdout|
      message += stdout
      project.builds[build].steps['deploy']['message'] = message
      Resque.redis.set(project.name, project.builds.to_json)
    end

    Docker.compose_up(containers) do |stdout|
      message += stdout
      project.builds[build].steps['deploy']['message'] = message
      Resque.redis.set(project.name, project.builds.to_json)
    end
    project.builds[build].steps['deploy']['status'] = 'success'
    project.builds[build].status = 'success'
    Resque.redis.set(project.name, project.builds.to_json)
  end
end
