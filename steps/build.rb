# frozen_string_literal: true

require 'docker'

class Build
  @queue = :build

  def self.perform(project, project_settings, build, stages)
    project = Project.new(project, project_settings, Resque.redis.get(project))
    message = ''

    stages.each do |stage|
      message += "<br/>building stage: #{stage}<br/><br/>"
      image = Docker::Image.build_from_dir('.', { target: stage }) do |v|
        if (log = JSON.parse(v)) && log.key?('stream')
          message += log['stream']
          project.builds[build].steps['build'] = { 'status' => 'running', 'message' => message }
          Resque.redis.set(project.name, project.builds.to_json)
        end
      end
      image.tag({ repo: "#{project.name}/#{stage}", tag: 'latest' })
      project.builds[build].steps['build']['status'] = 'success'
      Resque.redis.set(project.name, project.builds.to_json)
    end
    Resque.enqueue(Test, project.name, project_settings, build, stages)
  end
end
