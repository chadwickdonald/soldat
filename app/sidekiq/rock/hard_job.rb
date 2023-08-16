class Rock::HardJob
  include Sidekiq::Job

  queue_as :default

  def perform(*args)
    puts "-----ROCK HARD!!!!!"
  end
end
