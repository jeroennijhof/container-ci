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

  def project_status_classes
    {
      'success' => 'bi-check2-circle text-success',
      'failed' => 'bi-exclamation-circle text-danger',
      'running' => 'spinner-border text-success'
    }
  end

  def project_status_buttons
    {
      'success' => 'btn-outline-success',
      'failed' => 'btn-outline-danger',
      'running' => 'btn-outline-secondary'
    }
  end

  def project_trigger(trigger, _)
    settings.projects.each do |project, project_settings|
      return project_initialize(project, project_settings) if project_settings['trigger'] == trigger
    end

    false
  end

  def project_initialize(project, project_settings)
    project = Project.new(project, project_settings, Resque.redis.get(project))
    build_index = project.builds.size + 1
    project.builds[build_index.to_s] = Build.new
    Resque.redis.set(project.name, project.builds.to_json)
    Resque.enqueue(Initialize, project.name, project_settings, build_index.to_s)
  end
end
