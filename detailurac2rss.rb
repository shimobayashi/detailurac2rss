#!/usr/bin/env ruby

require 'rubygems'
require 'mechanize'
require 'rss/maker'

ROOT_URL = "http://moepic2.moe-ren.net/gazo/detailurac/"

# 返信がついてるスレを抽出する
agent = Mechanize.new
threads = []
['index', *(1..9).to_a].each {|p|
#(1..3).to_a.each {|p|
  url = "#{ROOT_URL}#{p}.htm"
  page = agent.get url
  page.search('table[summary="threads summary"]').each {|t|
    threads << t if t.search('table[summary="threads message"]').length > 0
  }
  break if threads.length >= 20
}
# RSSを吐く
rss = RSS::Maker.make('2.0') {|rss|
  rss.channel.title = 'detailurac2rss'
  rss.channel.description = 'Commented entries from detailurac'
  rss.channel.link = 'https://github.com/shimobayashi/detailurac2rss'

  threads.each {|t|
    # 画像検索のURLを取得する
    image_url = "#{ROOT_URL}#{t.at('table[summary="threads header"] a[target="new"]')[:href]}"
    page = agent.post 'http://www.ascii2d.net/imagesearch/search', {uri: image_url}
    link_url = page.uri.to_s

    # エントリを構築する
    thread_no = t.at('strong').inner_text
    thread_comments = t.search('font[color="#631992"]').map{|e| e.inner_text}.join('<br>')
    item = rss.items.new_item
    item.title = thread_no
    item.link = link_url
    item.guid.content = thread_no
    item.guid.isPermaLink = false
    item.description = %Q(<img src="#{image_url}" height="500"><br>#{thread_comments})
    item.date = Time.now
  }
}
puts rss
