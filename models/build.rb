# frozen_string_literal: true

require 'time'

class Build
  attr_reader :timestamp
  attr_accessor :status, :steps

  def initialize(timestamp = Time.now.utc, status = 'running', steps = {})
    @timestamp = timestamp
    @status = status
    @steps = steps
  end

  def to_json(*args)
    {
      'timestamp' => @timestamp,
      'status' => @status,
      'steps' => @steps
    }.to_json(*args)
  end
end
