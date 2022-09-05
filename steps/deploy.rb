# frozen_string_literal: true

require_relative '../docker/docker'

class Deploy
  @queue = :deploy

  def self.perform(project, project_settings, build, dockerfile)
    project = Project.new(project, project_settings, Resque.redis.get(project))
    project_settings['deploy'].each do |env, env_settings|
      if env_settings['confirm'] == true
        message = 'Waiting for confirmation...<br/><br/>'
        project.builds[build].steps["deploy_#{env}"] = { 'status' => 'pause', 'message' => message }
        project.builds[build].status = 'pause'
        Resque.redis.set(project.name, project.builds.to_json)
      end

      while project.builds[build].steps["deploy_#{env}"]['status'] == 'pause'
        sleep 1
        project = Project.new(project.name, project_settings, Resque.redis.get(project.name))
      end

      break unless project.builds[build].steps["deploy_#{env}"]['status'] == 'running'

      docker = Docker.new("workspace/#{project.name}/#{build}")
      message = "Deploying stable image for #{env}<br/>"

      containers = [{ 'name' => project.name,
                      'image' => "#{project.name}/stable",
                      'ports' => dockerfile['ports'] }]
      project.builds[build].steps["deploy_#{env}"] = { 'status' => 'running', 'message' => message }
      Resque.redis.set(project.name, project.builds.to_json)

      docker.compose_down do |stdout|
        message += stdout
        project.builds[build].steps["deploy_#{env}"]['message'] = message
        Resque.redis.set(project.name, project.builds.to_json)
      end

      docker.compose_up(containers) do |stdout|
        message += stdout
        project.builds[build].steps["deploy_#{env}"]['message'] = message
        Resque.redis.set(project.name, project.builds.to_json)
      end
      message += 'Deploying done<br/><br/>'
      project.builds[build].steps["deploy_#{env}"]['message'] = message
      Resque.redis.set(project.name, project.builds.to_json)

      dockerfile['ports'].each do |port|
        docker.compose_port(project.name, port) do |stdout|
          message += link("http://localhost:#{stdout.split(':')[1]}")
          project.builds[build].steps["deploy_#{env}"]['message'] = message
          Resque.redis.set(project.name, project.builds.to_json)
        end
      end

      project.builds[build].steps["deploy_#{env}"]['status'] = 'success'
      Resque.redis.set(project.name, project.builds.to_json)
    end
    project.builds[build].status = 'success'
    Resque.redis.set(project.name, project.builds.to_json)
  end

  def self.link(url)
    "<a href=\"#{url}\" target=\"_blank\">#{url}</a><br/>"
  end
end
