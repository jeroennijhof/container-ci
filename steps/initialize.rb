# frozen_string_literal: true

require 'git'
require 'json'
require_relative '../models/project'

class Initialize
  @queue = :initialize

  def self.perform(settings, project_name, build, branch)
    project = Project.new(project_name, settings['projects'][project_name], Resque.redis.get(project_name))
    project.builds[build].steps['initialize'] = { 'status' => 'running', 'message' => '' }
    Resque.redis.set(project.name, project.builds.to_json)

    git = Git.clone(project.settings['git'], "workspace/#{project.name}/#{build}")
    git.checkout(branch)
    message = "Branch: #{branch}<br/><br/>Git commit #{git.log.last.sha}:<br/>#{git.log.last.message}"

    status, message = parse_dockerfile(settings,
                                       project.name,
                                       build,
                                       "workspace/#{project.name}/#{build}/Dockerfile",
                                       message)

    project.builds[build].steps['initialize'] = { 'status' => status, 'message' => message }
    project.builds[build].status = status if status == 'failed'
    Resque.redis.set(project.name, project.builds.to_json)
  end

  def self.parse_dockerfile(settings, project_name, build, path, message)
    stages = []
    ports = []
    dockerfile = File.readlines(path)
    dockerfile.each do |line|
      stages.append(line.downcase.split(' as ')[1].chomp) if line.downcase.start_with?('from ')
      ports.append(line.downcase.split[1].chomp) if line.downcase.start_with?('expose ')
    end
    dockerfile = { 'stages' => stages, 'ports' => ports }
    Resque.enqueue(Build, settings, project_name, build, dockerfile)
    ['success', "#{message}<br/><br/>Stages: #{stages.join(', ')}"]
  rescue StandardError => e
    ['failed', "#{message}<br/><br/>#{e.message}", []]
  end
end
