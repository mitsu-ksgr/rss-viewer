#!/usr/bin/env ruby
#
# Simple RSS feed viewer.
#
require 'date'
require 'io/console'
require 'uri'
require 'rss'



#------------------------------------------------------------------------------
# Defines / Global vars
#------------------------------------------------------------------------------
class Param
  PRINT_ITEM_COUNT = 10
  TERM_LEN = 80
end

class Messenger
  @@list = []

  def self.push(msg)
    @@list.push(msg)
  end

  def self.has?
    return !@@list.empty?
  end

  def self.flush
    @@list = []
  end

  def self.messages
    return @@list
  end
end



#------------------------------------------------------------------------------
# System utils
#------------------------------------------------------------------------------
def err(msg)
  STDERR.puts "Error: #{msg}"
  exit(1)
end

class OS
  def self.open_uri(uri)
    case RUBY_PLATFORM
    when /linux/
      system("xdg-open #{uri}")
      return true

    when /darwin/
    when /mingw|mswin/
    else
      # TODO: print
      Messenger.notify("Error: Unsupported os: #{RUBY_PLATFORM}")
    end

    return false
  end

  class Console
    def self.clear
      case RUBY_PLATFORM
      when /linux|darwin/
        system("clear")
      when /mingw|mswin/
        system("cls")
      end
    end
  end
end



#------------------------------------------------------------------------------
# Print Helpers
#------------------------------------------------------------------------------
def fmtdt(datetime)
  datetime.nil? ? " "*16 : datetime.strftime("%FT%R")
end

def text_width(str)
  str.each_char.sum { |c| c.bytesize == 1 ? 1 : 2 }
end

def trim_text(str, n, tail = ".", tailn = 3)
  w = text_width(str)
  return str if w <= n

  ret = []
  cnt = 0
  limit = n - tailn
  str.each_char do |c|
    size = (c.bytesize == 1 ? 1 : 2)
    if cnt <= limit - size
      ret.push(c)
      cnt += size
    end
  end

  # padding
  (n-cnt).times do
    ret.push(tail)
  end

  ret.join("")
end



#------------------------------------------------------------------------------
# RSS Helpers
#------------------------------------------------------------------------------
def is_valid_uri?(uri)
  return uri =~ /\A#{URI::regexp(['http', 'https'])}\z/
end

class RSSType
  RSS1 = :rss1
  RSS2 = :rss2
  Atom = :atom
  Unkown = :unkown
end

class RSSFeedItem
  attr_reader :title, :desc, :published_at, :link

  def initialize(title: "", desc: "", published_at: nil, link: "")
    @title = title
    @desc = desc.strip
    @published_at = published_at
    @link = link
  end
end

class RSSFeed
  attr_reader :uri, :title, :siteurl, :items, :fetched_at

  def initialize(uri)
    @uri = uri
    @title = ""
    @siteurl = ""

    @type = RSSType::Unkown
    @feed = nil
    @items = []
    @fetched_at = nil
  end

  def fetch
    URI.open(uri) do |resp|
      rss = nil
      begin
        rss = RSS::Parser.parse(resp)
      rescue RSS::InvalidRSSError
        Messenger.push("Warn: RSS::InvalidRSSError: #$!")

        rss = RSS::Parser.parse(resp, false)
      end
      @feed = rss
    end
    @fetched_at = DateTime.now
    return self if @feed.nil?

    case @feed
    when RSS::RDF # RSS 1.0
      @type = RSSType::RSS1
    when RSS::Rss # RSS 0.9x / 2.0
      @type = RSSType::RSS2
    when RSS::Atom::Feed  # Atom
      @type = RSSType::Atom
    else
      @type = RSSType::Unkown
    end

    self.load_rawfeed
    return self
  end

  private

  def load_rawfeed
    return false if @feed.nil?

    # Base info
    case @type
    when RSSType::RSS1 # TODO
      @title = @feed.channel.title
      @siteurl = @feed.channel.link
    when RSSType::RSS2
      @title = @feed.channel.title
      @siteurl = @feed.channel.link
    when RSSType::Atom
      @title = @feed.title.content
      @siteurl = @feed.link
    end

    # Items
    @items = @feed.items.map do |item|
      params = {}

      case @type
      when RSSType::RSS1 # TODO
        params = {
          title: item.title,
          desc: item.description,
          published_at: item.date,
          link: item.link,
        }

      when RSSType::RSS2
        params = {
          title: item.title,
          desc: item.description,
          published_at: item.pubDate,
          link: item.link,
        }

      when RSSType::Atom
        params = {
          title: item.title.content,
          desc: item.content,
          published_at: item.published&.content || item.updated&.content,
          link: item.link.href,
        }
      end

      RSSFeedItem.new(**params)
    end

    return true
  end
end



#------------------------------------------------------------------------------
# Main
#------------------------------------------------------------------------------
def cui_loop(uri, feed)
  page = 0
  lines = Param::PRINT_ITEM_COUNT

  cursor = 0
  table_cursor = 0

  loop do
    OS::Console.clear

    #
    # Print header
    #
    puts <<~EOS

      RSS URI     : #{uri}
      Title       : #{feed.title}
      Total items : #{feed.items.length}

    EOS

    #
    # Print item table
    #
    puts "   |   Publish date   | Title "
    t_hr = "---+------------------+"
    puts t_hr + ("-" * (Param::TERM_LEN - t_hr.length))

    selected = nil
    feed.items.slice(table_cursor, lines).each_with_index do |item, idx|
      cur = ' '
      if cursor == idx
        cur = '>'
        selected = item
      end

      tr = " #{cur} | "
      tr += "#{fmtdt(item.published_at)} | "
      tr += "#{item.title}"
      puts trim_text(tr, Param::TERM_LEN)
    end

    puts t_hr + ("-" * (Param::TERM_LEN - t_hr.length))
    puts "   | [#{table_cursor} ~ #{table_cursor + lines} / #{feed.items.length}]"

    #
    # Print selected item
    #
    unless selected.nil?
      puts <<~EOS

        * Article
        Title        : #{selected.title}
        Publish date : #{selected.published_at}
        Link         : #{selected.link}

        #{selected.desc}
      EOS
    end

    #
    # Print messages
    #
    if Messenger.has?
      puts "\n" + ("~" * Param::TERM_LEN)
      puts <<~EOS

        * Notice
      EOS
      Messenger.messages.each do |msg|
        puts "- #{msg}"
      end
      Messenger.flush
    end

    #
    # Print footer
    #
    puts "\n" + ("=" * Param::TERM_LEN)
    puts <<~EOS

      * How to use
      Cursor Up / Down ....... k / j
      CUrsor Prev / Next ..... h / l
      Open article ........... SPACE
      Quit ................... q
    EOS
    #puts "DEBUG: Cursor=#{cursor}, TableCursor=#{table_cursor}"


    #
    # Get input.
    #
    key = STDIN.getch
    if key == "\e" && STDIN.getch == "["
      key = STDIN.getch
    end

    case key
    when 'Q', 'q', "\C-c"
      break
      puts ""

    when 'J', 'j' # to down
      if cursor < lines - 1
        cursor += 1
      elsif table_cursor + lines < feed.items.length
        table_cursor += 1
      end

    when 'K', 'k'
      if cursor > 0
        cursor -= 1
      elsif table_cursor > 0
        table_cursor -= 1
      end

    when 'L', 'l'
      table_cursor = [
        table_cursor + lines,
        feed.items.length - lines
      ].min

    when 'H', 'h'
      table_cursor = [
        table_cursor - lines,
        0
      ].max

    when ' ' # SPACE key
      Messenger.push("Opened: #{selected.link}")
      OS.open_uri(selected.link)

    end
  end
end



def main()
  #
  # Get rss feed uri
  #
  print("Enter the RSS URI> ")
  in_uri = gets.chomp
  err("nil") if in_uri.empty?
  err("invalid url") unless is_valid_uri?(in_uri)


  #
  # Get feed.
  #
  feed = nil
  fetch_thread = Thread.new do
    feed = RSSFeed.new(in_uri).fetch
  end

  print "fetching.."
  while fetch_thread.alive?
    print "."
    sleep(1)
  end
  fetch_thread.join
  puts "OK!"

  puts <<~EOS

    RSS URI    : #{in_uri}
    Feed Title : #{feed.title}

    Press enter key to continue...
  EOS
  gets

  cui_loop(in_uri, feed)
end



#------------------------------------------------------------------------------
# Entrypoint
#------------------------------------------------------------------------------
if __FILE__ == $0
  main
end

