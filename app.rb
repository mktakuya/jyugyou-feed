require 'sinatra/base'
require 'sinatra/contrib'
require "sinatra/reloader"
require 'slim'
require 'active_support/all'
require './classes'
require 'icalendar'
require 'sequel'

class Jyugyou < Sinatra::Base
  register Sinatra::Contrib

  configure :development do
    register Sinatra::Reloader
  end

  configure :production do
    set :server, :puma
  end

  before do
    connect_opt =  {"options"=>{"host"=>ENV['DB_HOST'], "user"=>ENV['DB_USER'], "password"=>ENV['DB_PASSWORD']}}
    @db = Sequel.postgres('jyugyou', connect_opt)
  end

  get '/' do
    @classes = CLASSES
    slim :index
  end

  get '/feeds' do
    if CLASSES.has_key? params[:class].downcase.to_sym
      conds = {
        class: CLASSES[params[:class].downcase.to_sym],
        date: Date.today.last_week.beginning_of_week..Date.today.next_week.end_of_week
      }
      calendar = Icalendar::Calendar.new
      calendar.append_custom_property("X-WR-CALNAME;VALUE=TEXT", "TNCT #{conds[:class]} 授業変更情報")
      calendar.timezone do |t|
        t.tzid = 'Asia/Tokyo'
        t.standard do |s|
          s.tzoffsetfrom = '+0900'
          s.tzoffsetto   = '+0900'
          s.tzname       = 'JST'
          s.dtstart      = '19700101T000000'
        end
      end

      @db[:jyugyous].where(conds).all.each do |col|
        calendar.event do |e|
          e.dtstart = Icalendar::Values::Date.new(col[:date])
          e.summary = "#{col[:period]} #{col[:content]}"
          e.description = "#{col[:class]} #{col[:date].to_s}(#{col[:period]}) #{col[:content]}"
        end
      end
      calendar.publish
      content_type 'text/calendar'
      calendar.to_ical
    else
      status 400
      '400 Bad Request'
    end
  end

   after do
     if @db
       @db.disconnect
     end
   end

  helpers do
    def page_title(title = nil)
      base_title = 'TNCT授業変更情報 iCalendarフィード'
      @title = title if title
      @title ? "#{@title} - #{base_title}" : base_title
    end
  end

  run! if app_file == $0
end
