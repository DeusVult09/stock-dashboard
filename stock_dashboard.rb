require 'dotenv/load'
require 'sinatra'
require 'httparty'
require 'json'

set :public_folder, File.dirname(__FILE__) + '/public'

class AlphaAdvantClient
  BASE_URL = "https://alphavantage.co/query"
  TIME_MAP = { '1D' => 'TIME_SERIES_DAILY', '1M' => 'TIME_SERIES_DAILY', '1Y' => 'TIME_SERIES_WEEKLY'}

  def find_stock_data(input, timeframe)
    function = TIME_MAP[timeframe]
    return { "error" => "Invalid timeframe" } unless function 
    response = HTTParty.get(BASE_URL, query: { function: function, symbol: input.to_s.upcase.strip, apikey: ENV['ALPHAVANTAGE_KEY'] })
    return { "error" => "Network failure" } unless response.success?

    data = JSON.parse(response.body)
    msg = data["Error Message"] || data["Note"] || data["Information"]
    msg ? { "error" => msg } : data
  end
end

get '/' do
  send_file File.join(settings.public_folder, 'index.html')
end

get '/api/stock_data' do
  content_type :json
  ticker = params[:ticker]
  timeframe = params[:timeframe]
  client = AlphaAdvantClient.new
  result = client.find_stock_data(ticker, timeframe)
  result.to_json
end

