require 'open3'
require_relative 'compose'

class Docker
  def initialize(workspace)
    @workspace = workspace
  end

  def command(*args)
    stdin, stdout, stderr, waiter = Open3.popen3('docker', *args, chdir: @workspace)
    stdin.close
    while (output = stdout.gets)
      yield output
    end
    raise Error, stderr.read unless waiter.value.success?
  end

  def build(*args, &block)
    command('build', *args, &block)
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
