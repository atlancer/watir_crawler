require 'nestegg'

module WatirCrawler
  class Error < StandardError
    include Nestegg::NestingException
  end

  class WebdriverError < Error; end
  class ServiceUnavailable < Error; end
  class SiteTooSlow < Error; end
  class SiteChanged < Error; end

  class UnknownError < Error; end
end
