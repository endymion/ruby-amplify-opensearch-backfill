module Loggable
  def logger(reset: false)
    if defined?(@logger) and !reset
      @logger
    else
      @logger = Logger.new($stdout)
      logger.formatter = proc { |severity, _time, _p, msg| "#{severity}: #{msg}\n" }
      logger.level = ENV['DEBUG'] ? Logger::DEBUG : Logger::INFO
      @logger
    end
  end
end
