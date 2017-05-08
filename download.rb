# coding: utf-8

require 'fileutils'
require 'logger'
require 'net/http'
require 'openssl'
require 'open-uri'
require 'pp'
require 'rexml/document'
require 'rexml/parsers/ultralightparser'
require 'ruby-progressbar'
require 'uri'

## REST クライアント、たぶんこっちのほうが簡潔に記載可能
## https://github.com/rest-client/rest-client

class DownloadItem
  attr_accessor :filename, :downloadurl
end

class Downloader

  API_ENDPOINT_GET_BY_USER = 'https://www.slideshare.net/api/2/get_slideshows_by_user'
  attr_reader :successlogger, :stdout, :warnlogger

  def initialize(outputdir=nil, stdout=nil, successlogger=nil, warnlogger=nil, interval=nil)
    @outputdir = outputdir || Dir.pwd
    @stdout = stdout || Logger.new(STDOUT)
    @successlogger = successlogger || Logger.new("downloadlist.log")
    @warnlogger = warnlogger || Logger.new("warninglist.log")
    @sleep = interval || 0.1

    FileUtils.mkdir_p(@outputdir.to_s)
  end

  def download_slides_by_user(user)

    unless ENV.has_key?("API_KEY") || ENV.has_key?("SHARED_SECRET")
      usage
      exit(1)
    end

    doc = REXML::Document.new (get_xml_contents(user))

    items = []
    doc.elements.each('//Slideshow') do |e|
      i = DownloadItem.new
      i.filename =  e.elements['Title'].text + "." + e.elements['Format'].text
      i.downloadurl = e.elements['DownloadUrl'].text
      items << i
    end

    size = items.size
    @progress = ProgressBar.create( :format         => "%a %E %b\u{15E7}%i %P%% %t %c/%C",
                                    :total          => size,
                                    :progress_mark  => ' ',
                                    :remainder_mark => "\u{FF65}",
                                  )
    batch_download(items)
  end

  private
  def get_xml_contents(user)
    @stdout.info("Starting api request...")
    params = Hash.new
    params["api_key"] = ENV["API_KEY"]
    params["sharedsecret"] = ENV["SHARED_SECRET"]
    params["ts"] = Time.now.to_i.to_s
    params["hash"] = Digest::SHA1.hexdigest(params["sharedsecret"]+params["ts"])
    params['username_for'] = user

    uri = URI.parse(API_ENDPOINT_GET_BY_USER)
    uri.query = URI.encode_www_form(params)
    http = Net::HTTP.new(uri.host, uri.port)

    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    req = Net::HTTP::Get.new uri
    res = http.request(req)
    @stdout.debug("#{res.code}, #{res.msg}, #{res.body}")

    res.body
  end

  def usage
    @stdout.error("Please set following environment variables.")
    @stdout.error("SlideShare api key and shared secret.")
  end

  def batch_download(items)
    items.each do |item|
      begin
        download(item)
        sleep(@sleep)
      rescue => e
        @warnlogger.warn "#{e.message}: Skip following slide. title: #{item.filename} url: #{item.downloadurl}"
      end
      @progress.increment
    end
  end

  def download(item)
    open(item.downloadurl) do |file|
      open(File.join(@outputdir, item.filename), "wb") do |out|
        out.write(file.read)
        @successlogger.info("Success: #{item.filename}")
      end
    end
  end
end

## specify slideshare user name at CLI
d = Downloader.new(ARGV[1])
d.download_slides_by_user(ARGV[0])
