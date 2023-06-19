# frozen_string_literal: true

require 'json'
require 'sinatra/base'
require 'sinatra/config_file'
require_relative 'helpers/project_helper'

class ContainerCi < Sinatra::Base
  register Sinatra::ConfigFile

  config_file 'config.yml'
  helpers ProjectHelper

  get '/?' do
    erb :root
  end

  get '/favicon.ico?' do
    nil
  end

  get '/projects?' do
    @projects = project_get
    @status = project_status_classes
    erb :projects
  end

  get '/:project/?' do
    @project = project_get_name(params[:project])
    erb :project
  end

  get '/:project/builds?' do
    @project = project_get_name(params[:project])
    @status = project_status_classes
    @status_buttons = project_status_buttons
    erb :builds
  end

  delete '/:project/builds?' do
    @project = project_get_name(params[:project])
    @project.delete_builds
    nil
  end

  get '/:project/:build/:step/message/?' do
    @project = project_get_name(params[:project])
    @project.builds[params[:build]].steps[params[:step]]['message']
  end

  put '/:project/:build/:step/status/?' do
    status 201
    @project = project_put_name(params)
  end

  post '/trigger/:trigger/?' do
    halt 500, 'something went wrong' unless project_trigger(params[:trigger], params)
  end
end
