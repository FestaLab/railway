Sidekiq.configure_client do |config|
  config.redis = { url: ENV['AWS_REDIS_JOB_URL'], network_timeout: 5 }
end

Sidekiq.configure_server do |config|
  config.redis = { url: ENV['AWS_REDIS_JOB_URL'], network_timeout: 5 }
end
