# -*- coding: utf-8 -*-
# Trend
# 現在のTwitterのトレンドでStreaming APIでOR検索！

require 'hpricot'

Plugin.create :trend_stream do

  tab(:trend_stream, "Trend") do
    timeline :trend_stream
  end

  timeline_created = on_timeline_created do |tl|
    if tl.slug == :trend_stream
      Delayer.new{
        gtk_timeline = Plugin.filtering(:gui_get_gtk_widget, tl).first
        gtk_timeline.force_retrieve_in_reply_to = false
      }
      detach :timeline_created, timeline_created end end

  # ばずったーからバズワードを取得して配列で返す。
  # ==== Return
  # ばずったーから取得したキーワードの配列
  def rewind_buzzword
    open('http://buzztter.com/ja/', 'r'){ |io|
      @buzz = (Hpricot(io)/'div#buzzphrases'/'a').map{ |elm|
        elm.attributes['title']
      }.select{ |w|
        not(w =~ /[\*]/)
      }.sort.freeze } end

  def buzz
    @buzz ||= rewind_buzzword
  end

  filter_filter_stream_track do |word|
    if word.empty?
      [buzz[0, 8].join(',')]
    else
      [word + "," + buzz[0, 8].join(',')] end end

  on_period do
    before = buzz
    after = rewind_buzzword
    if before != after
      Plugin.call(:filter_stream_force_retry) end end

  on_appear do |messages|
    buzzword_top = buzz[0, 8]
    result = messages.select{ |message|
      buzzword_top.any?{ |b| message.to_s.include? b } }
    timeline(:trend_stream) << result if not result.empty? end

end
