require 'dotenv/load'
require 'sinatra'
require 'httparty'
require 'json'

set :public_folder, File.dirname(__FILE__) + '/public'

class AlphaAdvantClient
  BASE_URL = "https://alphavantage.co/query"
  TIME_MAP = { '1D' => 'TIME_SERIES_DAILY', '1M' => 'TIME_SERIES_DAILY', '1Y' => 'TIME_SERIES_WEEKLY'}
    
  def find_stock_data(input, timeframe)
    query_params = { function: TIME_MAP[timeframe], symbol: input.to_s.upcase.strip, apikey: ENV['ALPHAVANTAGE_KEY'] }
    response = HTTParty.get(BASE_URL, query: query_params)
    response.success? ? response.parsed_response : { "error" => "Network failure" }
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

