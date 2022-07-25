# frozen_string_literal: true

require 'docker'
require 'json'

class Docker
  @queue = :initialize

  def self.perform(project, project_settings, build)
    docker = Docker.new
    output = docker.run('busybox', ['/bin/sh', '-c', '/bin/ps'], tty: true)
    builds = JSON.parse(Resque.redis.get(project))
    builds[build]['steps']['initialize'] = output
    Resque.redis.set(project, builds.to_json)
  end
end
