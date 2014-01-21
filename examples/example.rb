require 'bundler/setup'
require 'watir_crawler'

#WatirCrawler.logger.level = Logger::INFO
#WatirCrawler.debug = true

class CrawlerExample < WatirCrawler::Base
  def yandex_news
    browser_session do
      goto 'http://yandex.ru'

      news_list = "//ul[@class='b-news-list']"
      wait(news_list)

      pull(news_list) do
        titles = pull(:all, "./li").map{|li| li.text }
        links  = pull(:all, "./li/a").map{|a| a.uri }

        Hash[ titles.zip(links) ]
      end
    end
  end

  def google_news
    browser_session do
      goto 'http://news.google.com/'

      sections = "//div[@class='section-stream-content']//div[@class='section-list-content']/div"
      wait(sections)

      pull(:all, sections).reduce({}) do |result, section|
        pull(section.node_xpath) do
          section_name   = pull(".//span[@class='section-name']").text
          article_titles = pull(:all, ".//span[@class='titletext']").map{|element| element.text }

          result[section_name] = article_titles
        end

        result
      end
    end
  end

  def get_proxy(proxy_port = 3128)
    browser_session do
      goto 'http://hideme.ru/proxy-list/'

      checkbox = "//input[@id='c_all']"
      wait(checkbox).clear
      sleep 1

      wait("//select[@id='country']").select_value('JP')
      wait("//input[@id='t_h']").set # set http proxy
      wait("//input[@id='maxtime']").set 1400 # set proxy timeout
      wait("//input[@id='ports']").set proxy_port # set proxy port
      wait("//a[contains(@href,'search()')]").click # search !

      # get 1th proxy ip from the list
      proxy_list = "//table[@class='pl']"
      wait(proxy_list)

      proxy_ip = pull(proxy_list) { pull(".//tr[2]/td[1]") }
      raise 'No proxy found' unless proxy_ip

      [proxy_ip.text, proxy_port]
    end
  end

  def via_proxy proxy_ip, proxy_port
    browser_profile do |profile|
      profile['network.proxy.type'] = 1
      profile['network.proxy.http'] = proxy_ip
      profile['network.proxy.http_port'] = proxy_port.to_i
    end

    browser_session do
      goto 'http://www.whatsmyip.org/'
      wait("//span[@id='ip']").text
    end
  end

end

# ----------------------------------------------------------------------------------------------------------------------

timeouts = {
  :page_load => 150,
  :wait_timeout => 100 # wait for element on the page
}

begin
  crawler = CrawlerExample.new(timeouts)

  puts 'Last google news'
  p crawler.google_news

  puts 'Last yandex news'
  p crawler.yandex_news

  proxy = crawler.get_proxy
  puts "Found proxy: #{proxy.join(':')}"

  current_proxy = crawler.via_proxy(*proxy)
  puts "Current proxy: #{current_proxy}"
rescue WatirCrawler::SiteTooSlow
  puts
  puts 'ERROR: Site too slow'
end

