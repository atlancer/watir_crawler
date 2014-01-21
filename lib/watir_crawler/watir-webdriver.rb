module Watir
  class Element
    def uri
      url = self.attribute_value(:src) || self.attribute_value(:href)
      URI.join(self.browser.url, url).to_s if url
    end
  end

  class Image
    def save_to_file filepath
      File.open(filepath, 'wb') do |f|
        f.write open(self.uri).read
      end

      filepath
    end
  end
end

