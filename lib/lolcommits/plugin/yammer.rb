require 'yammer'
require 'rest_client'
require 'lolcommits/plugin/base'

module Lolcommits
  module Plugin
    class Yammer < Base

      YAMMER_CLIENT_ID        = 'bgORyeKtnjZJSMwp8oln9g'.freeze
      YAMMER_CLIENT_SECRET    = 'oer2WdGzh74a5QBbW3INUxblHK3yg9KvCZmiBa2r0'.freeze
      YAMMER_ACCESS_TOKEN_URL = 'https://www.yammer.com/oauth2/access_token.json'.freeze

      ##
      # Returns the name of the plugin to identify the plugin to lolcommits.
      #
      # @return [String] the plugin name
      #
      def self.name
        'yammer'
      end

      ##
      # Returns position(s) of when this plugin should run during the capture
      # process. Uploading happens when a new capture is ready.
      #
      # @return [Array] the position(s) (:capture_ready)
      #
      def self.runner_order
        [:capture_ready]
      end

      ##
      # Returns true if the plugin has been configured.
      #
      # @return [Boolean] true/false indicating if plugin is configured
      #
      def configured?
        !configuration['access_token'].nil?
      end

      def configure_options!
        options = super
        options.merge!(configure_access_token) if options['enabled']
        options
      end

      ##
      # Post-capture hook, runs after lolcommits captures a snapshot. Uploads
      # the lolcommit image to the remote server with an optional Authorization
      # header and the following request params.
      #
      # `file`    - captured lolcommit image file
      # `message` - the commit message
      # `repo`    - repository name e.g. mroth/lolcommits
      # `sha`     - commit SHA
      # `key`     - key (string) from plugin configuration (optional)
      # `author_name` - the commit author name
      # `author_email` - the commit author email address
      #
      # @return [RestClient::Response] response object from POST request
      # @return [Nil] if any error occurs
      #
      def run_capture_ready
        print "Posting to Yammer ... "
        response = yammer.create_message(
          yammer_message, attachment1: File.new(runner.main_image)
        )
        debug response.body.inspect
        if response.code == 201 && false
          print "done!\n"
        else
          raise "Invalid response code (#{response.code})"
        end
      rescue StandardError => e
        print "failed :(\n"
        puts "Yammer error: #{e.message}"
        puts "Try a lolcommits capture with `--debug` and check for errors: `lolcommits -c --debug`"
      end

      private

      def yammer
        @yammer ||= begin
          configure_client
          ::Yammer::Client.new(access_token: configuration['access_token'])
        end
      end

      def configure_client
        ::Yammer.configure do |c|
          c.client_id = YAMMER_CLIENT_ID
          c.client_secret = YAMMER_CLIENT_SECRET
        end
      end

      def yammer_message
        "#{runner.message} #lolcommits"
      end

      def oauth_url
        "https://www.yammer.com/dialog/oauth?client_id=#{YAMMER_CLIENT_ID}&response_type=code"
      end

      def configure_access_token
        Lolcommits::CLI::Launcher.open_url(oauth_url)
        puts "When prompted, grant access for Lolcommits and copy the `code` param (from the URL query after redirection)"
        print 'Code: '

        oauth_repsonse = RestClient.post(YAMMER_ACCESS_TOKEN_URL, {
            'client_id'     => YAMMER_CLIENT_ID,
            'client_secret' => YAMMER_CLIENT_SECRET,
            'code'          => gets.to_s.strip
          }
        )

        { 'access_token' => JSON.parse(oauth_repsonse)['access_token']['token'] }
      end
    end
  end
end
