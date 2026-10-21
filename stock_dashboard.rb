
require 'sinatra'
require 'dotenv/load'

get "/api/stock_data" do
  api_key = ENV['ALPHAVANTAGE_KEY']

  
end