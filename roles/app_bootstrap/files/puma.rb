workers ENV.fetch("PUMA_CONCURRENCY")
threads_count = ENV.fetch("RAILS_MAX_THREADS")
threads threads_count, threads_count

preload_app!

rackup DefaultRackup
port ENV.fetch("PORT") { 3000 }
rails_env = ENV.fetch("RAILS_ENV") { "production" }
environment rails_env

on_worker_boot do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end

wait_for_less_busy_worker
fork_worker
nakayoshi_fork
