# -*- coding: utf-8 -*-
#
# Copyright 2013 whiteleaf. All rights reserved.
#

require "open3"

#
# 雑多なお助けメソッド群
#
# MacOSX 関連は確認してないので動作するか不明
#
module Helper
  def self.os_windows?
    @@os_is_windows ||= RUBY_PLATFORM =~ /mswin(?!ce)|mingw|cygwin|bccwin/i
  end

  def self.os_mac?
    @@os_is_mac ||= RUBY_PLATFORM =~ /darwin/
  end

  def self.determine_os
    case
    when os_windows?
      :windows
    when os_mac?
      :mac
    else
      :other
    end
  end

  def self.confirm(message)
    confirm_msg = "#{message} (y/n)?: "
    STDOUT.print confirm_msg   # Logger でロギングされないように直接標準出力に表示
    while input = $stdin.gets
      case input[0].downcase
      when "y"
        return true
      when "n"
        return false
      else
        STDOUT.print confirm_msg
      end
    end
  end

  def self.open_browser_linux(address, error_message)
    %w(xdg-open firefox w3m).each do |browser|
      system(%!#{browser} "#{address}"!)
      return if $?.exitstatus != 127
    end
    error error_message
  end

  def self.open_directory(path, confirm_message = nil)
    if confirm_message
      return unless confirm(confirm_message)
    end
    case determine_os
    when :windows
      `explorer "file:///#{path.encode(Encoding::Windows_31J)}"`
    when :mac
      `open "#{path}"`
    else
      open_browser_linux(path, "フォルダが開けませんでした")
    end
  end

  def self.open_browser(url)
    case determine_os
    when :windows
      escaped_url = url.gsub("%", "%^").gsub("&", "^&")
      # MEMO: start の引数を "" で囲むと動かない
      `start #{escaped_url}`
    when :mac
      `open "#{url}"`
    else
      open_browser_linux(url, "ブラウザが見つかりませんでした")
    end
  end

  def self.print_horizontal_rule
    puts "―" * 35
  end

  def self.replace_filename_special_chars(str)
    str.tr("/:*?\"<>|.", "／：＊？”〈〉｜．").gsub("\\", "￥")
  end

  #
  # 外部コマンド実行中の待機ループの処理を書けるクラス
  #
  # response = Helper::AsyncCommand.exec("処理に時間がかかる外部コマンド") do
  #   print "*"
  # end
  # if response[2].success?
  #   puts "成功しました"
  # end
  #
  class AsyncCommand
    def self.exec(command, sleep_time = 0.5, &block)
      async_command = new(command)
      while async_command.running?
        block.call
        sleep(sleep_time)
      end
      async_command.response
    end

    def initialize(command)
      @command_response = nil
      @command_running = true
      Thread.new do
        @command_response = Open3.capture3(command)
        @command_running = false
      end
    end

    def running?
      @command_running
    end

    def response
      @command_response
    end
  end
end
