# -*- coding: utf-8 -*-
# Trend
# 現在のTwitterのトレンドでStreaming APIでOR検索！

require 'hpricot'

Module.new do

  plugin = Plugin::create(:trend_trac_streaming)
  main = Gtk::TimeLine.new()
  main.force_retrieve_in_reply_to = false
  queue_parse = SizedQueue.new(2)
  queue_event = TimeLimitedQueue.new(4, 1){ |messages| Delayer.new(Delayer::LAST){ main.add messages } }

  Delayer.new {
    service = Post.services.first
    Plugin.call(:mui_tab_regist, main, 'Trend')

    Thread.new{
      loop{
        sleep(3)
        notice 'filter stream: connect'
        begin
          buzzword = open('http://buzztter.com/ja/', 'r'){ |io|
            (Hpricot(io)/'div#buzzphrases'/'a').map{ |elm| elm.attributes['title'] }[0..7].join(',') }
          if !buzzword or buzzword.empty?
            sleep(60)
          else
            Plugin.call(:rewindstatus, "Buzzワード: #{buzzword}")
            puts "Buzzワード: #{buzzword}"
            timeout(60){
              service.streaming(:filter_stream, :track => buzzword){ |x| queue_parse.push x } } end
        rescue TimeoutError => e
        rescue => e
          warn e end
        notice 'filter stream: disconnected' } }

    Thread.new{
      loop{
        json = queue_parse.pop.strip
        case json
        when /^\{.*\}$/
          messages = service.__send__(:parse_json, json, :streaming_status) rescue nil
          if messages.is_a? Enumerable
            messages.each{ |message|
              queue_event.push message if message.is_a? Message
            }
          end
        end } } } end

