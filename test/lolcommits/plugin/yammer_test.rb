require "json"
require "test_helper"
require 'webmock/minitest'

describe Lolcommits::Plugin::Yammer do
  include Lolcommits::TestHelpers::GitRepo
  include Lolcommits::TestHelpers::FakeIO

  describe "with a runner" do
    def runner
      # a simple lolcommits runner with an empty configuration Hash
      @runner ||= Lolcommits::Runner.new(
        main_image: Tempfile.new('main_image.jpg')
      )
    end

    def plugin
      @plugin ||= Lolcommits::Plugin::Yammer.new(runner: runner)
    end

    def valid_enabled_config
      {
        enabled: true,
        access_token: "oV4MuwnNKql3ebJMAYZRaD"
      }
    end

    describe "#enabled?" do
      it "is false by default" do
        plugin.enabled?.must_equal false
      end

      it "is true when configured" do
        plugin.configuration = valid_enabled_config
        plugin.enabled?.must_equal true
      end
    end

    describe "run_capture_ready" do
      before do
        plugin.configuration = valid_enabled_config
        commit_repo_with_message("first commit!")
      end

      after { teardown_repo }

      it "posts lolcommit image to Yammer with commit message" do
        in_repo do
          stub_request(:post, create_message_api_url).to_return(status: 201)
          output = fake_io_capture { plugin.run_capture_ready }

          output.must_equal "Posting to Yammer ... done!\n"
          assert_requested :post, create_message_api_url, times: 1, headers: {
            'Authorization' => 'Bearer oV4MuwnNKql3ebJMAYZRaD',
            'Content-Type'  => /multipart\/form-data/
          } do |req|
            req.body.must_match(/Content-Disposition: form-data;.+name="attachment1"; filename="main_image.jpg.+"/)
          end
        end
      end

      it "reports an error if posting to yammer fails" do
        in_repo do
          stub_request(:post, create_message_api_url).to_return(status: 503)
          output = fake_io_capture { plugin.run_capture_ready }

          output.split("\n").must_equal(
            [
              "Posting to Yammer ... failed :(",
              "Yammer error: 503 Service Unavailable",
              "Try a lolcommits capture with `--debug` and check for errors: `lolcommits -c --debug`"
            ]
          )
        end
      end
    end

    describe "configuration" do

      describe "#valid_configuration?" do
        it "returns false when not configured correctly" do
          plugin.valid_configuration?.must_equal false
        end

        it "returns true when configured" do
          plugin.configuration = valid_enabled_config
          plugin.valid_configuration?.must_equal true
        end
      end

      describe "configuring with Yammer Oauth" do
        before do
          # allow requests to localhost for this test
          WebMock.disable_net_connect!(allow_localhost: true)
        end

        after do
          WebMock.disable_net_connect!
        end

        it "aborts if Yammer Oauth is denied" do
          configured_plugin_options = {}
          fake_authorize_step

          output = fake_io_capture(inputs: %w(true)) do
            configured_plugin_options = plugin.configure_options!
          end

          output.split("\n").last.must_equal(
            "Aborting.. Plugin disabled since Yammer Oauth was denied"
          )

          configured_plugin_options.must_equal({ enabled: false })
        end

        it "configures successfully with a Yammer Oauth access token" do
          configured_plugin_options = {}
          yammer_oauth_token = "yam-oauth-token"
          yammer_oauth_code  = "yam-oauth-code"
          klass              = plugin.class

          stub_request(:post, klass::ACCESS_TOKEN_URL).with(
            body: {
              "client_id"     => klass::OAUTH_CLIENT_ID,
              "client_secret" => klass::OAUTH_CLIENT_SECRET,
              "code"          => [yammer_oauth_code]
            }
          ).to_return(
            status: 200,
            body: {
              "access_token" => {
                "token" => yammer_oauth_token
              }
            }.to_json
          )

          fake_authorize_step("?code=#{yammer_oauth_code}")

          fake_io_capture(inputs: %w(true)) do
            configured_plugin_options = plugin.configure_options!
          end

          configured_plugin_options.must_equal({
            enabled: true,
            access_token: "yam-oauth-token"
          })
        end
      end
    end
  end

  private

  def create_message_api_url
    plugin.class::MESSAGES_API_URL
  end

  # fake click for the authorize step in Yammer, by hitting local webrick server
  # loops repeating request until the server responds 200 OK
  def fake_authorize_step(redirect_params = nil)
    fork do
      res = nil
      while !res || res.code != "200"
        uri = URI("#{plugin.class::OAUTH_REDIRECT_URL}/#{redirect_params}")
        res = Net::HTTP.get_response(uri) rescue nil
        sleep 0.1
      end
    end
  end
end
