require 'faraday'

class Faraday::Adapter::Lionfish < Faraday::Adapter
  dependency 'lionfish'

  def call(env)
    response = ::Lionfish.request(env)
    save_response(env, response.status.to_i, response.body, response.headers)

    @app.call env
  end

  Faraday::Adapter.register_middleware lionfish: self
end
