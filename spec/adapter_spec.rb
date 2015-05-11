require 'bundler/setup'
require 'webmock/rspec'
require 'sinatra/base'
require 'lionfish/adapter'
require 'byebug'

class FakeService < Sinatra::Base
  get '/users/:id' do
    params[:id]
  end
end

describe Faraday::Adapter::Lionfish do
  describe ".map" do
    it "pipelines HTTP requests in the block" do
      stub_request(:any, %r(http://example.com/.*)).to_rack(FakeService)

      connection = Faraday.new("http://example.com") do |f|
        f.adapter :lionfish
      end

      user_ids = [1, 2, 3]

      users = Lionfish.map(user_ids) do |user_id|
        response = connection.get("/users/#{user_id}")
        expect(response.status).to eq 200
        response.body
      end

      expect(users).to eq %w(1 2 3)
    end
  end
end
