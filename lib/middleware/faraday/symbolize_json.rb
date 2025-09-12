# frozen_string_literal: true

require 'faraday'

module Middleware
  module Faraday
    class SymbolizeJson < ::Faraday::Middleware
      def on_complete(env)
        return unless env.response_headers['Content-Type'] =~ /application\/json/
        return if env[:body].blank?
        env.body = JSON.parse(env[:body], symbolize_names: true)
      end
    end
  end
end
