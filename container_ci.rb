# frozen_string_literal: true

require 'sinatra/base'
require 'sinatra/config_file'
require_relative 'helpers/project_helper'

class ContainerCi < Sinatra::Base
  register Sinatra::ConfigFile

  config_file 'config.yml'
  helpers ProjectHelper

  get '/?' do
    @projects = project_get
    @status = project_status_classes
    erb :projects
  end

  get '/:project/?' do
    @project = project_get_name(params[:project])
    @status = project_status_buttons
    erb :project
  end

  post '/trigger/:trigger/?' do
    halt 500, 'something went wrong' unless project_trigger(params[:trigger], body)
  end
end
