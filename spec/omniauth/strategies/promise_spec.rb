require "spec_helper"

RSpec.describe OmniAuth::Promise do
  let(:auth_hash){ last_request.env['omniauth.auth'] }

  def app
    Rack::Builder.new do
      use OmniAuth::Test::PhonySession
      use OmniAuth::Builder do
        provider :promise, 'example.org'
      end
      run lambda { |env| [404, {"Content-Type" => "text/plain"}, [env.key?("omniauth.auth").to_s]] }
    end.to_app
  end

  def session
    last_request.env["rack.session"]
  end

  it "has a version number" do
    expect(OmniAuth::Promise::VERSION).not_to be nil
  end

  describe '#request_phase' do
    before do
      get '/auth/promise'
    end
    it 'should set nonce and redirect' do
      nonce = session['nonce']
      expect(session['nonce']).to be_present
      expect(last_response).to be_redirect
      expect(last_response.headers["Location"]).to eq("https://promiseauthentication.org/a/example.org?nonce=#{nonce}&redirect_uri=http://example.org/auth/promise/callback")
    end
  end

  describe "#callback_phase" do
    let(:promise_params) { CGI.parse(URI.parse(last_response.headers["Location"]).query) }
    let(:callback_path) { URI.parse(promise_params['redirect_uri'].first).path }
    let(:nonce) { promise_params["nonce"].first }
    let(:aud) { 'example.org' }
    let(:payload) do
      {
        jti: SecureRandom.uuid,
        sub: 'uid',
        aud: aud,
        iss: 'https://whatever.org',
        iat: Time.now.to_i,
        nonce: nonce
      }
    end

    let(:private_key) do
      ecdsa_key = OpenSSL::PKey::EC.new 'secp521r1'
      ecdsa_key.generate_key
      ecdsa_key
    end

    let(:public_key) do
      ecdsa_public = OpenSSL::PKey::EC.new private_key
      ecdsa_public.private_key = nil
      ecdsa_public
    end

    let(:id_token) do
      JSON::JWT.new(payload).sign(private_key, :ES512).to_s
    end

    before do
      stub_request(:get, "https://whatever.org/.well-known/jwks.json").
        to_return(:body => {keys: [public_key.to_jwk]}.to_json)
    end

    context 'when all is good' do
      before do
        get '/auth/promise'
        get callback_path, {:id_token => id_token}
      end

      it "should call once" do
        expect(auth_hash['uid']).to eq 'https://whatever.org|uid'
      end
    end

    describe 'caching of JWKS' do
      before do
        @instance = OmniAuth::Strategies::Promise.new 'hello'
        @url = "https://otherwhatever.org/.well-known/jwks.json"
        stub_request(:get, @url).
          to_return(
            :body => {keys: []}.to_json,
            headers: {
              etag: 'hello',
              cache_control: "public, must-revalidate, max-age=300"
            }
        )
        @instance.jwks(@url)
        @instance.jwks(@url)
        OmniAuth::Strategies::Promise.clear_cache!
        @instance.jwks(@url)
        @instance.jwks(@url)
      end
      it 'https once' do
        expect(WebMock).to have_requested(:get, @url).twice
      end
    end

    context 'when token is gibberish' do
      before do
        get '/auth/promise'
        get callback_path, {:id_token => 'hello'}
      end

      it "should have error" do
        expect(last_request.env["omniauth.error.type"]).to eq :invalid_token
      end
    end

    context 'when nonce is not matchin' do
      let(:nonce) { 'hello' }
      before do
        get '/auth/promise'
        get callback_path, {:id_token => id_token}
      end

      it "should have error" do
        expect(last_request.env["omniauth.error.type"]).to eq :nonce_not_matching
      end
    end

    context 'when aud is not matchin' do
      let(:aud) { 'hello' }
      before do
        get '/auth/promise'
        get callback_path, {:id_token => id_token}
      end

      it "should have error" do
        expect(last_request.env["omniauth.error.type"]).to eq :audience_not_matching
      end
    end

    context "when keys do not match" do
      before do
        get '/auth/promise'

        ecdsa_key = OpenSSL::PKey::EC.new 'secp521r1'
        ecdsa_key.generate_key
        id_token = JSON::JWT.new(payload).sign(ecdsa_key, :ES512).to_s

        get callback_path, {:id_token => id_token}
      end

      it "should call fail! with could_not_verify_token" do
        expect(last_request.env["omniauth.error"]).to be_kind_of(OmniAuth::Strategies::Promise::CouldNotVerifyTokenError)
        expect(last_request.env["omniauth.error.type"]).to eq :could_not_verify_token
      end
    end

    context "bad gateway (or any 5xx) for access_token" do
      before do
        stub_request(:get, "https://whatever.org/.well-known/jwks.json").
          to_raise(::Net::HTTPFatalError.new('502 "Bad Gateway"', nil))
        get '/auth/promise'
        get callback_path, {:id_token => id_token}
      end

      it "should call fail! with :service_unavailable" do
        expect(last_request.env["omniauth.error.type"]).to eq :service_unavailable
      end
    end

    context "SSL failure" do
      before do
        stub_request(:get, "https://whatever.org/.well-known/jwks.json").
          to_raise(::OpenSSL::SSL::SSLError.new)
        get '/auth/promise'
        get callback_path, {:id_token => id_token}
      end

      it "should call fail! with :service_unavailable" do
        expect(last_request.env["omniauth.error.type"]).to eq :service_unavailable
      end
    end
  end
end
