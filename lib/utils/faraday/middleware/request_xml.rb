module TestChamber
  module Rest

    class RequestXml < Faraday::Middleware

      def initialize(app, options= {})
        super(app)
      end
      
      def call(request_env)
        request_env[:body] = request_env[:body].to_xml unless request_env[:body].nil?
        @app.call(request_env)
      end
    end

  end
end
