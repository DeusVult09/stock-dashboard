
require 'dotenv/load'
require 'sinatra'
require 'httparty'
require 'json'
require 'date'

set :public_folder, File.dirname(__FILE__) + '/public'

class AlphaAdvantClient
  BASE_URL = "https://www.alphavantage.co/query"
  TIME_MAP = { '1D' => 'TIME_SERIES_DAILY', '1M' => 'TIME_SERIES_DAILY', '1Y' => 'TIME_SERIES_WEEKLY' }
  CACHE = {}
  TTL = 6 * 60 * 60 

  def find_stock_data(input, timeframe)
    function = TIME_MAP[timeframe]
    return { "error" => "Invalid timeframe" } unless function

    symbol = input.to_s.upcase.strip
    key = [function, symbol]

    hit = CACHE[key]
    return hit[:data] if hit && Time.now - hit[:at] < TTL

    response = HTTParty.get(BASE_URL, query: {
      function: function, symbol: symbol, apikey: ENV['ALPHAVANTAGE_KEY']
    })
    return { "error" => "Network failure" } unless response.success?

    data = JSON.parse(response.body)
    msg = data["Error Message"] || data["Note"] || data["Information"]

    if msg
      return sample_data(function, symbol) if msg.match?(/rate limit|requests per day|premium/i)
      return { "error" => msg }
    end

    CACHE[key] = { data: data, at: Time.now }
    data
  end

  private

  def sample_data(function, symbol)
    weekly = function == 'TIME_SERIES_WEEKLY'
    key = weekly ? 'Weekly Time Series' : 'Time Series (Daily)'
    price = 100.0 + symbol.sum % 200
    series = {}
    (weekly ? 60 : 100).times do |i|
      date = Date.today - i * (weekly ? 7 : 1)
      open = price
      close = (open * (1 + rand(-0.02..0.02))).round(2)
      series[date.to_s] = {
        "1. open"   => open.round(2).to_s,
        "2. high"   => ([open, close].max * 1.01).round(2).to_s,
        "3. low"    => ([open, close].min * 0.99).round(2).to_s,
        "4. close"  => close.to_s,
        "5. volume" => rand(1_000_000..5_000_000).to_s
      }
      price = close
    end
    { "Meta Data" => { "2. Symbol" => symbol }, key => series, "demo" => true }
  end
end

get '/' do
  send_file File.join(settings.public_folder, 'index.html')
end

get '/api/stock_data' do
  content_type :json
  client = AlphaAdvantClient.new
  client.find_stock_data(params[:ticker], params[:timeframe]).to_json
end
