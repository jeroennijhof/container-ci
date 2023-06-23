# frozen_string_literal: true

require_relative 'initialize'
require_relative 'build'
require_relative 'stage'
require_relative 'deploy'

module Step
  ##
  # Error class used by resque to set step in failed state when exception occur
  #
  class Error < Resque::Failure::Base
    def save
      project = Project.new(payload['args'][1], payload['args'][0]['projects'][payload['args'][1]], Resque.redis.get(payload['args'][1]))
      project.builds[payload['args'][2]].steps[payload['class'].downcase] =
        { 'status' => 'failed', 'message' => exception.to_s }
      project.builds[payload['args'][2]].status = 'failed'
      Resque.redis.set(project.name, project.builds.to_json)
    rescue StandardError => e
      puts "Error: #{e}"
      $stdout.flush
    end
  end
end
