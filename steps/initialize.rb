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

    status, message = parse_dockerfile(project.name,
                                       project_settings,
                                       build,
                                       "workspace/#{project.name}/#{build}/Dockerfile",
                                       message)

    project.builds[build].steps['initialize'] = { 'status' => status, 'message' => message }
    project.builds[build].status = status if status == 'failed'
    Resque.redis.set(project.name, project.builds.to_json)
  end

  def self.parse_dockerfile(project, project_settings, build, path, message)
    stages = []
    dockerfile = File.readlines(path)
    dockerfile.each do |line|
      stages.append(line.downcase.split(' as ')[1].chomp) if line.downcase.start_with?('from ')
    end
    Resque.enqueue(Build, project, project_settings, build, stages)
    ['success', "#{message}<br/><br/>stages: #{stages.join(', ')}"]
  rescue StandardError => e
    ['failed', "#{message}<br/><br/>#{e.message}", []]
  end
end
