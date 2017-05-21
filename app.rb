require 'sinatra/base'
require 'sinatra/contrib'
require "sinatra/reloader"
require 'slim'

class Jyugyou < Sinatra::Base
  register Sinatra::Contrib

  configure :development do
    register Sinatra::Reloader
  end

  configure :production do
    set :server, :puma
  end

  get '/' do
    slim :index
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
