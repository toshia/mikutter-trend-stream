# -*- coding: utf-8 -*-
# Trend
# 現在のTwitterのトレンドでStreaming APIでOR検索！

require 'hpricot'

Plugin.create :trend_stream do

  main = Gtk::TimeLine.new()
  main.force_retrieve_in_reply_to = false

  Delayer.new{ Plugin.call(:mui_tab_regist, main, 'Trend') }

  # ばずったーからバズワードを取得して配列で返す。
  # ==== Return
  # ばずったーから取得したキーワードの配列
  def rewind_buzzword
    open('http://buzztter.com/ja/', 'r'){ |io|
      @buzz = (Hpricot(io)/'div#buzzphrases'/'a').map{ |elm| elm.attributes['title'] }.sort.freeze } end

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
    result = messages.select{ |message|
      buzz.any?{ |b| message.to_s.include? b } }
    main.add result if not result.empty? end

end
