# frozen_string_literal: true

##
# config.ru (run with rackup)
#

require './container_ci'
require 'resque'
require 'resque/server'

config = ContainerCi.settings
connection = { host: config.redis['host'], port: config.redis['port'] }
connection[:username] = config.redis['username'] if config.redis.key?('username')
connection[:password] = config.redis['password'] if config.redis.key?('password')
connection[:scheme] = config.redis['scheme']
connection[:ssl_params] = { verify_mode: OpenSSL::SSL::VERIFY_NONE }

Resque.redis = Redis.new(connection)
raise 'Redis namespace is required in the configuration' unless config.redis['namespace']

Resque.redis.namespace = config.redis['namespace']

# Silence Redis deprecation warnings for now because Resque has no fix yet
# https://github.com/redis/redis-rb/blob/master/CHANGELOG.md#460
Redis.silence_deprecations = true

run Rack::URLMap.new \
  '/' => ContainerCi,
  '/resque' => Resque::Server.new
