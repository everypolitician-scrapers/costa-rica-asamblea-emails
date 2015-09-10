#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'colorize'
require 'pry'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def scrape_list(url)
  noko = noko_for(url)
  noko.css('table[summary="Diputadas y diputados"] a[href*="mailto:"]/@href').each do |email|
    tds = email.xpath('ancestor::tr[1]/td')

    source_url = tds[0].css('a/@href').text
    source = open(source_url) { |f| f.base_uri.to_s }
    
    data = { 
      id: source[/Cedula_Diputado=(\d+)/, 1],
      name: [1, 0].map { |i| tds[i].text.tidy }.join(" "),
      email: email.text.sub('mailto:',''),
    }
    ScraperWiki.save_sqlite([:id, :name, :email], data)
  end
end

scrape_list('http://www.asamblea.go.cr/Diputadas_Diputados/Lists/Diputados/Diputadas%20y%20Diputados.aspx')
