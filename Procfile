web: bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq -C config/sidekiq.yml
release: bin/rails db:prepare && bin/rails db:secondary:prepare
