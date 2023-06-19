# frozen_string_literal: true

require 'json'
require_relative '../steps/initialize'

module ProjectHelper
  def project_get
    projects = []
    settings.projects.each do |project, project_settings|
      projects.append(Project.new(project, project_settings, Resque.redis.get(project)))
    end
    projects
  end

  def project_get_name(name)
    settings.projects.each do |project, project_settings|
      return Project.new(project, project_settings, Resque.redis.get(project)) if project == name
    end
    raise "Project #{name} not found"
  end

  def project_put_name(params)
    raise 'Invalid status' unless %w[running pause success failed].include?(params[:status])

    project = project_get_name(params[:project])
    project.builds[params[:build]].steps[params[:step]]['status'] = params[:status]
    project.builds[params[:build]].status = params[:status]
    Resque.redis.set(project.name, project.builds.to_json)
  end

  def project_status_classes
    {
      'success' => 'bi-check2-circle text-success',
      'failed' => 'bi-exclamation-circle text-danger',
      'running' => 'spinner-border text-success',
      'pause' => 'bi-pause-circle text-warning'
    }
  end

  def project_status_buttons
    {
      'success' => 'btn-outline-success',
      'failed' => 'btn-outline-danger',
      'running' => 'btn-outline-secondary',
      'pause' => 'btn-outline-warning'
    }
  end

  def project_trigger(trigger, params)
    settings.projects.each do |project, project_settings|
      return project_initialize(project, project_settings, params) if project_settings['trigger'] == trigger
    end

    false
  end

  def project_initialize(project, project_settings, params)
    branch = 'main'
    branch = params['branch'] if params.key?('branch') && !params['branch'].empty?
    project = Project.new(project, project_settings, Resque.redis.get(project))
    build_index = project.builds.size + 1
    project.builds[build_index.to_s] = Build.new
    Resque.redis.set(project.name, project.builds.to_json)
    Resque.enqueue(Initialize, settings_to_hash, project.name, build_index.to_s, branch)
  end

  def settings_to_hash
    { docker: settings.docker,
      k8s: settings.k8s,
      environment: settings.environment,
      projects: settings.projects }
  end
end
