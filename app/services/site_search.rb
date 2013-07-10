# # -*- coding: utf-8 -*-
require 'open-uri'
require 'ostruct'

# XPath selectors are efficient, CSS selectors are readable
module SiteSearch
  class Search
    attr_reader :error

    def initialize(query, options={})
      @query = query
      @base_search_url = "#{APP_CONFIG['site_search_query_url']}?oenc=UTF-8&"
      @options = { read_timeout: 10 }.merge(options)
      search
    end

    # Send a GET request to the Siteseeker server and create a Nokogiri doc from the returned HTML
    def search
      begin
        html = open("#{@base_search_url}#{@query}", read_timeout: @options[:read_timeout]).read
        document = Nokogiri::HTML(html, nil, "UTF-8")
        @results = clean_up(document).xpath("/html/body")
      rescue Exception => e
        Rails.logger.error "Siteseeker: #{e}"
        @error = e
        @results = Nokogiri::HTML("<error>#{e}</error>")
      end
    end

    def sorting
      @results.css('div.ess-sortlinks').xpath("a | span[@class='ess-current']").map do |sort_by|
        OpenStruct.new(
          text: sort_by.text.strip,
          query: URI::parse(sort_by.xpath("@href").text).query,
          current: sort_by.xpath("@href").empty?
        )
      end
    end

    def total
      @results.css('#essi-hitcount').text.to_i
    end

    def paging
      extract_links(@results.xpath("//*[@class='ess-respages']/*[@class='ess-page' or @class='ess-current']"))
    end

    def more_query
      URI::parse(@results.xpath("//*[@class='ess-respages']/*[@class='ess-next']/@href").text).query
    end

    def editors_choice
      @results.xpath("//*[@class='ess-bestbets']").map do |ec|
        OpenStruct.new(
          text: ec.xpath("dt/a").text,
          url: ec.xpath("dt/a/@href").text,
          summary: ec.xpath("dd").text
        )
      end
    end

    def suggestions
      extract_links(@results.xpath("//*[@class='ess-spelling']/ul/li/a"))
    end

    def entries
      @results.css("dl.ess-hits dt").map do |entry|
        Entry.new(entry)
      end
    end

    def category_groups
      @results.css("[id^=essi-bd-cg-]").map do |category_group|
        OpenStruct.new(
          title: category_group.css(".ess-cat-bd-heading").text.strip.gsub(/:$/, ""),
          categories: category_group.css(".ess-cat-bd-category").map { |entry| Category.new(entry) }
        )
      end
    end

  protected

    def extract_links(node_set)
      node_set.map do |entry|
        { query: URI::parse(entry.xpath("@href").text).query, text: entry.text }
      end
    end

    # Rewrite href's in each a element
    def rewrite_urls(node_set)
      node_set.map do |entry|
        entry.css("a").each do |a|
          a.set_attribute("href", "?#{URI::parse(a.xpath("@href").text).query}")
        end
        entry
      end
      node_set
    end

    # Depollute some Siteseeker crap
    def clean_up(doc)
      doc.css(".ess-separator").remove
      doc.css("@title").remove
      doc.css("@onclick").remove
      doc.css("@tabindex").remove
      doc.css(".ess-label-hits").remove
      doc.css(".ess-clear").remove
      doc
    end
  end

  class Entry
    def initialize(entry)
      @entry = entry
    end

    def number
      @entry.css('.ess-hitnum').text.to_i
    end

    def title
      @entry.css('a').first.text.strip
    end

    def summary
      @entry.xpath("following-sibling::*[1]/div[@class='ess-hit-extract']").text.strip
    end

    def url
      @entry.css("a").first['href']
    end

    def content_type
      @entry.css('.ess-dtypelabel').text.gsub(/[\[\]]/, "").strip
    end

    def date
      @entry.xpath("following-sibling::dd[2]").css('.ess-date').text.strip
    end

    def breadcrumbs
      @entry.xpath("following-sibling::dd[1]/div[@class='ess-special']/ul/li[a]").map do |item|
        OpenStruct.new(text: item.css("a").text.strip, url: item.css("a/@href").text)
      end
    end

    def category
      @entry.xpath("following-sibling::*[2]").css('.ess-category').text.strip
    end
  end

  class Category
    def initialize(category)
      @category = category
    end

    def title
      @category.css("a").text.strip
    end

    def query
      URI::parse(@category.css("a").first['href']).query.strip
    end

    def hits
      @category.css(".ess-num").text.strip
    end
  end
end

# results = SiteSearch::Search.new("semester")
# puts results.error.class
# puts results.sorting[1].text.class
# puts results.sorting[1].query.class
# puts results.sorting[1].current.class
# puts results.sorting.class
# puts results.total
# puts results.paging.class
# puts results.more_query.class
# puts results.editors_choice.class
# puts results.suggestions.class
# puts "=" * 72
# puts results.category_groups.class
# puts results.category_groups.first.class
# puts results.category_groups.first.title.class
# puts results.category_groups.first.categories.first.title.class
# puts results.category_groups.first.categories.first.query.class
# puts results.category_groups.first.categories.first.hits.class
# puts "=" * 72
# puts results.entries
# puts results.entries.first.title
# puts results.entries.first.summary.class
# puts results.entries.first.url.class
# puts results.entries.first.number.class
# puts results.entries.first.date.class
# puts results.entries.first.content_type.class
# puts results.entries.first.category.class
# puts results.entries.first.breadcrumb.class
# puts results.entries.first.breadcrumb.first.class
# puts results.entries.first.breadcrumb.first.text.class
# puts results.entries.first.breadcrumb.first.url.class
