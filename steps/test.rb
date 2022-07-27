# frozen_string_literal: true

require 'docker'

class Test
  @queue = :test

  def self.perform(project, project_settings, build, stages)
    project = Project.new(project, project_settings, Resque.redis.get(project))
    message = ''

    container = Docker::Container.create('Image' => "#{project.name}/test")
    container.tap(&:start).attach do |stream, chunk|
      message += "#{stream}: #{chunk}"
      project.builds[build].steps['test'] = { 'status' => 'running', 'message' => message }
      Resque.redis.set(project.name, project.builds.to_json)
    end
    status = 'success'
    status = 'failed' unless container.wait['StatusCode'].zero?
    container.remove

    project.builds[build].steps['test']['status'] = status
    project.builds[build].status = status
    Resque.redis.set(project.name, project.builds.to_json)
  end
end
