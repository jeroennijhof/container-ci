# frozen_string_literal: true

require_relative 'build'

class Project
  attr_reader :name, :settings, :builds

  def initialize(name, settings, store)
    @name = name
    @settings = settings
    @builds = {}
    return if store.nil?

    JSON.parse(store).each do |build_number, build|
      @builds[build_number] = Build.new(build['timestamp'], build['status'], build['steps'])
    end
  end

  def last_build
    @builds[@builds.keys.reverse[0]] unless @builds.empty?
  end

  def delete_builds
    Resque.redis.set(@name, '{}')
    @builds = {}
  end
end
