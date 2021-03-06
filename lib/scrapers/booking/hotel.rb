module Scrapers
  module Booking
    class Hotel
      private
      attr_reader :url, :browser

      public

      def initialize(url:)
        @url = url
      end

      def scrape
        init_capybara
        @browser = Capybara.current_session
        browser.visit(url)

        return build_hotel_attributes
      end

      private

      def build_hotel_attributes
        data     = extract_hotel_data
        raw_data = extract_raw_data
        hotel_id = raw_data.delete(:hotel_id)

        return {
          title:       data[:title],
          description: data[:description],
          provider_id: hotel_id,
          picture_url: data[:picture_url],
          raw_data:    raw_data
        }
      end

      def extract_hotel_data
        title_selector  = ".hp__hotel-name"
        title           = browser.find(title_selector).text.strip

        description_selector  = ".hp-description .hp_desc_main_content #summary p"
        description           = browser.all(description_selector).map(&:text).map(&:strip).join("\n").strip
        picture_url           = extract_picture_url

        {
          title:       title,
          description: description,
          picture_url: picture_url
        }
      end

      def extract_picture_url
        pictures_selector = ".bh-photo-grid .active-image"
        pictures_links    = browser.all(pictures_selector)

        if pictures_links.any?
          return pictures_links.first["href"]
        else
          pictures_selector = ".hp-gallery .slick-track img"
          pictures_images   = browser.all(pictures_selector)

          return pictures_images.first["src"]
        end
      end

      def extract_raw_data
        basic_raw_data  = {}
        hotel_id        = nil
        hotel_id_regexp = /b_hotel_id:\s'(?<hotel_id>\d+)'/

        scripts = browser.all("head script", visible: false)

        scripts.each do |script|
          raw_script = script["innerHTML"]

          if basic_raw_data.empty? && raw_script.include?("priceRange")
            basic_raw_data = JSON.parse(raw_script.gsub("\n", ""))
          elsif hotel_id.nil? && raw_script =~ hotel_id_regexp
            hotel_id = raw_script.match(hotel_id_regexp)[:hotel_id].to_i
          end
        end

        return basic_raw_data.merge(hotel_id: hotel_id)
      end

      def init_capybara
        require 'capybara/poltergeist'
        Capybara.register_driver :poltergeist do |app|
          Capybara::Poltergeist::Driver.new(app, phantomjs: Phantomjs.path, js_errors: false)
        end

        Capybara.default_driver = :poltergeist
      end
    end
  end
end
