require 'logger'

module WatirCrawler
  module Loggable
    module Logger
      def logger
        @@logger ||= ::Logger.new(STDOUT) # Ruby's logger by default
      end

      def logger=(logger)
        @@logger = logger
      end

      def debug
        @@debug ||= false
      end

      def debug=(debug)
        @@debug = debug
      end
    end

    extend Logger

    module Log
      def log msg = nil
        if msg
          Loggable.logger.debug(msg) if Loggable.debug
        else
          Loggable.logger
        end
      end
    end

    # for extending of module
    def self.extended(base)
      base.extend Logger
      base.extend Log
    end

    # for including to class
    def self.included(base)
      base.extend Log
      base.send :include, Log
    end
  end

  extend Loggable
end
