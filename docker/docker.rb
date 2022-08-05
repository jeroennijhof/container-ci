require 'open3'
require_relative 'compose'

class Docker
  def self.command(*args)
    stdin, stdout, stderr, waiter = Open3.popen3('docker', *args)
    stdin.close
    while (output = stdout.gets)
      yield output
    end
    raise Error, stderr.read unless waiter.value.success?
  end

  def self.build(*args, &block)
    command('build', *args, &block)
  end

  def self.run(*args, &block)
    command('run', *args, &block)
  end

  def self.compose_up(containers, &block)
    Compose.create('docker-compose.yml', containers)
    command('compose', '-f', 'docker-compose.yml', 'up', &block)
  end

  def self.compose_down(&block)
    command('compose', '-f', 'docker-compose.yml', 'down', &block) if File.exist?('docker-compose.yml')
  end

  class Error < StandardError; end
end
