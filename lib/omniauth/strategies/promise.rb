require 'json/jwt'
require 'faraday-http-cache'
require 'multi_json'
require 'omniauth'

module OmniAuth
  module Strategies
    class Promise
      class CouldNotVerifyTokenError < StandardError ; end
      class NonceNotMatchingError < StandardError ; end
      class AudienceNotMatching < StandardError ; end

      include OmniAuth::Strategy

      args [:client_id]
      option :client_id, nil

      attr_reader :verified_id_token

      def request_phase
        session["nonce"] = nonce = SecureRandom.uuid

        redirect_uri = callback_url

        redirect "https://promiseauthentication.org/a/#{options.client_id}?nonce=#{nonce}&redirect_uri=#{callback_url}"
      end

      def id_token
        request.params["id_token"]
      end

      def payload
        payload = JSON::JWT.decode(id_token , :skip_verification)
      end

      def self.client
        @client ||= Faraday.new do |builder|
          builder.use :http_cache, serializer: Marshal
          builder.adapter Faraday.default_adapter
        end
      end

      def self.clear_cache!
        @client = nil
      end

      def jwks(url = "#{payload['iss']}/.well-known/jwks.json")
        response = self.class.client.get(url)
        jwks = MultiJson.load(response.body)
      end

      def callback_phase
        fail(OmniAuth::NoSessionError, "Session Expired") if session["nonce"].nil?

        fail NonceNotMatchingError if payload['nonce'] != session['nonce']
        session['nonce'] = nil
        fail AudienceNotMatching if payload['aud'] != options.client_id

        @verified_id_token = nil
        jwks["keys"].each do |jwk|
          break if @verified_id_token
          begin
            key = JSON::JWK.new(jwk).to_key
            @verified_id_token = JSON::JWT.decode id_token, key
          rescue JSON::JWS::VerificationFailed
          end
        end

        raise CouldNotVerifyTokenError unless @verified_id_token

        super
      rescue ::Timeout::Error => e
        fail!(:timeout, e)
      rescue Faraday::ConnectionFailed, Faraday::SSLError => e
        fail!(:service_unavailable, e)
      rescue OmniAuth::NoSessionError => e
        fail!(:possible_replay_attack, e)
      rescue CouldNotVerifyTokenError => e
        fail!(:could_not_verify_token, e)
      rescue NonceNotMatchingError => e
        fail!(:nonce_not_matching, e)
      rescue AudienceNotMatching => e
        fail!(:audience_not_matching, e)
      rescue JSON::JWT::InvalidFormat => e
        fail!(:invalid_token, e)
      end

      uid do
        @verified_id_token['iss'] + '|' + @verified_id_token['sub']
      end
    end
  end
end
