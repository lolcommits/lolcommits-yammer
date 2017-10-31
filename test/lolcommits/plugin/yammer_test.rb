require "test_helper"
require 'webmock/minitest'

describe Lolcommits::Plugin::Yammer do

  include Lolcommits::TestHelpers::GitRepo
  include Lolcommits::TestHelpers::FakeIO

  def plugin_name
    "yammer"
  end

  it "should have a name" do
    ::Lolcommits::Plugin::Yammer.name.must_equal plugin_name
  end

  it "should run on capture ready" do
    ::Lolcommits::Plugin::Yammer.runner_order.must_equal [:capture_ready]
  end

  describe "with a runner" do
    def runner
      # a simple lolcommits runner with an empty configuration Hash
      @runner ||= Lolcommits::Runner.new(
        main_image: Tempfile.new('main_image.jpg'),
        config: OpenStruct.new(
          read_configuration: {},
          loldir: File.expand_path("#{__dir__}../../../images")
        )
      )
    end

    def plugin
      @plugin ||= Lolcommits::Plugin::Yammer.new(runner: runner)
    end

    def valid_enabled_config
      @config ||= OpenStruct.new(
        read_configuration: {
          "yammer" => {
            "enabled" => true,
            "endpoint" => "https://yammer.com/uplol",
            'optional_http_auth_username' => 'joe',
            'optional_http_auth_password' => '1234'
          }
        }
      )
    end

    describe "initalizing" do
      it "assigns runner and all plugin options" do
        plugin.runner.must_equal runner
        plugin.options.must_equal %w(
          enabled
          endpoint
          optional_key
          optional_http_auth_username
          optional_http_auth_password
        )
      end
    end

    describe "#enabled?" do
      it "is false by default" do
        plugin.enabled?.must_equal false
      end

      it "is true when configured" do
        plugin.config = valid_enabled_config
        plugin.enabled?.must_equal true
      end
    end

    describe "run_capture_ready" do
      before { commit_repo_with_message("first commit!") }
      after { teardown_repo }

      it "syncs lolcommits" do
        in_repo do
          plugin.config = valid_enabled_config

          stub_request(:post, "https://yammer.com/uplol").to_return(status: 200)

          plugin.run_capture_ready

          assert_requested :post, "https://yammer.com/uplol", times: 1,
            headers: {'Content-Type' => /multipart\/form-data/ } do |req|
            req.body.must_match(/Content-Disposition: form-data;.+name="file"; filename="main_image.jpg.+"/)
            req.body.must_match 'name="repo"'
            req.body.must_match 'name="author_name"'
            req.body.must_match 'name="author_email"'
            req.body.must_match 'name="sha"'
            req.body.must_match 'name="key"'
            req.body.must_match "plugin-test-repo"
            req.body.must_match "first commit!"
          end
        end
      end
    end

    describe "configuration" do
      it "returns false when not configured" do
        plugin.configured?.must_equal false
      end

      it "returns true when configured" do
        plugin.config = valid_enabled_config
        plugin.configured?.must_equal true
      end

      it "allows plugin options to be configured" do
        # enabled, endpoint, key, user, password
        inputs = %w(
          true
          https://my-server.com/uplol
          key-123
          joe
          1337pass
        )
        configured_plugin_options = {}

        fake_io_capture(inputs: inputs) do
          configured_plugin_options = plugin.configure_options!
        end

        configured_plugin_options.must_equal({
          "enabled" => true,
          "endpoint" => "https://my-server.com/uplol",
          "optional_key" => "key-123",
          "optional_http_auth_username" => "joe",
          "optional_http_auth_password" => "1337pass"
        })
      end

      describe "#valid_configuration?" do
        it "returns false for an invalid configuration" do
          plugin.config = OpenStruct.new(read_configuration: {
            "lolsrv" => { "endpoint" => "gibberish" }
          })
          plugin.valid_configuration?.must_equal false
        end

        it "returns true with a valid configuration" do
          plugin.config = valid_enabled_config
          plugin.valid_configuration?.must_equal true
        end
      end
    end
  end
end
