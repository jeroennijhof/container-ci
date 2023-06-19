# frozen_string_literal: true

require 'open3'
require_relative 'compose'

class Docker
  def initialize(settings, workspace)
    @settings = settings
    @workspace = workspace
  end

  def connection
    args = ['-H', @settings['docker']['uri']]
    if @settings['docker']['tls']
      args.append('--tls')
      args.append('--tlscacert')
      args.append(@settings['docker']['tlscacert'])
      args.append('--tlscert')
      args.append(@settings['docker']['tlscert'])
      args.append('--tlskey')
      args.append(@settings['docker']['tlskey'])
    end
    args
  end

  def command(*args)
    stdin, stdout, stderr, waiter = Open3.popen3('docker', *connection, *args, chdir: @workspace)
    stdin.close
    while (output = stdout.gets)
      yield output
    end
    raise Error, stderr.read unless waiter.value.success?
  end

  def command_err(*args)
    stdin, stdout, stderr, waiter = Open3.popen3('docker', *connection, *args, chdir: @workspace)
    stdin.close
    stdout.close
    while (output = stderr.gets)
      yield output
    end
    raise Error, stderr.read unless waiter.value.success?
  end

  def build(*args, &block)
    command_err('build', *args, &block)
  end

  def run(*args, &block)
    command('run', *args, &block)
  end

  def compose_up(containers, &block)
    Compose.create(@workspace, containers)
    command('compose', '-f', 'docker-compose.yml', 'up', '-d', &block)
  end

  def compose_down(&block)
    command('compose', '-f', 'docker-compose.yml', 'down', &block) if File.exist?("#{@workspace}/docker-compose.yml")
  end

  def compose_port(service, port, &block)
    command('compose', '-f', 'docker-compose.yml', 'port', service, port, &block)
  end

  class Error < StandardError; end
end
