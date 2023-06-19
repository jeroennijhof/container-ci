# frozen_string_literal: true

require 'resque'
require 'resque/tasks'

namespace :resque do
  require './container_ci'
  require './steps/step'
  require 'resque/failure/multiple'
  require 'resque/failure/redis'

  config = ContainerCi.settings

  # Initialize Resque here so it can be used by Microservice and Resque::Server
  connection = { host: config.redis['host'], port: config.redis['port'] }
  connection[:username] = config.redis['username'] if config.redis.key?('username')
  connection[:password] = config.redis['password'] if config.redis.key?('password')
  connection[:ssl] = config.redis['ssl']
  connection[:ssl_params] = { verify_mode: OpenSSL::SSL::VERIFY_NONE }

  Resque.redis = Redis.new(connection)
  raise 'Redis namespace is required in the configuration' unless config.redis['namespace']

  Resque.redis.namespace = config.redis['namespace']

  Resque::Failure::Multiple.classes = [Resque::Failure::Redis, Step::Error]
  Resque::Failure.backend = Resque::Failure::Multiple

  # Silence Redis deprecation warnings for now because Resque has no fix yet
  # https://github.com/redis/redis-rb/blob/master/CHANGELOG.md#460
  Redis.silence_deprecations = true
end
