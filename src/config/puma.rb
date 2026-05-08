max_threads = Integer(ENV.fetch('RAILS_MAX_THREADS', 5))
threads max_threads, max_threads

bind        "tcp://0.0.0.0:#{ENV.fetch('PORT', 8080)}"
environment ENV.fetch('RAILS_ENV', 'development')
