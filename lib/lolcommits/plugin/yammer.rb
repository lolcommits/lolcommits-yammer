# frozen_string_literal: true

require 'lolcommits/plugin/base'
require 'lolcommits/cli/launcher'
require 'webrick'
require 'rest-client'
require 'cgi'

module Lolcommits
  module Plugin
    class Yammer < Base

      MESSAGES_API_URL    = "https://www.yammer.com/api/v1/messages".freeze
      ACCESS_TOKEN_URL    = 'https://www.yammer.com/oauth2/access_token.json'.freeze
      OAUTH_CLIENT_ID     = 'abbxXRgeSagk9GtiWW9rFw'.freeze
      OAUTH_CLIENT_SECRET = 'gHVw5Ekyy2mWOWsBzrZPs5EPnR6s04RibApcbuy10'.freeze
      OAUTH_REDIRECT_PORT = 5429
      OAUTH_REDIRECT_URL  = "http://localhost:#{OAUTH_REDIRECT_PORT}".freeze

      ##
      # Returns true if the plugin has been configured correctly.
      # The access_token must be set.
      #
      # @return [Boolean] true/false
      #
      def valid_configuration?
        !configuration[:access_token].nil?
      end

      ##
      # Prompts the user to configure the plugin.
      #
      # If the enabled option is set we attempt to fetch an Oauth token
      # via Yammers' Oauth 2 Server Side flow.
      #
      # https://developer.yammer.com/docs/oauth-2#server-side-flow
      #
      # @return [Hash] the configured plugin options
      #
      def configure_options!
        options = super
        if options[:enabled]
          oauth_access_token = fetch_access_token
          if oauth_access_token
            options.merge!(access_token: oauth_access_token)
          else
            puts "Aborting.. Plugin disabled since Yammer Oauth was denied"
            options[:enabled] = false
          end
        end
        options
      end

      ##
      # Post-capture hook, runs after lolcommits captures a snapshot.
      # Posts the lolcommit file to Yammer with a commit message
      # postfixed by a #lolcommits topic/hashtag.
      #
      # @return [Boolean] true/false indicating posting was successful
      #
      def run_capture_ready
        print "Posting to Yammer ... "
        response = RestClient.post(
          "https://www.yammer.com/api/v1/messages",
          { body: yammer_message, attachment1: File.new(runner.lolcommit_path) },
          { 'Authorization' => "Bearer #{configuration[:access_token]}" }
        )

        if response.code != 201
          debug response.body.inspect
          raise "Invalid response code (#{response.code})"
        end

        print "done!\n"
        true
      rescue StandardError => e
        print "failed :(\n"
        puts "Yammer error: #{e.message}"
        puts "Try a lolcommits capture with `--debug` and check for errors: `lolcommits -c --debug`"
        false
      end


      private

      def yammer_message
        "#{runner.message} #lolcommits"
      end

      def fetch_access_token
        puts "\nOpening this url to authorize lolcommits-yammer:"
        puts authorize_url
        open_url(authorize_url)
        puts "\nLaunching local webbrick server to complete the OAuth process ...\n"
        @oauth_code = nil
        begin
          trap('INT') { local_server.shutdown }
          trap('SIGTERM') { local_server.shutdown }
          local_server.mount_proc '/', server_callback
          local_server.start

          if @oauth_code
            debug "Requesting Yammer OAuth Token with code: #{@oauth_code}"
            oauth_response = RestClient.post(ACCESS_TOKEN_URL,
              {
                'client_id'     => OAUTH_CLIENT_ID,
                'client_secret' => OAUTH_CLIENT_SECRET,
                'code'          => @oauth_code
              }
            )

            if oauth_response.code.to_i == 200
              return JSON.parse(oauth_response.body)['access_token']['token']
            end
          end
          return nil
        rescue WEBrick::HTTPServerError
          raise "Do you have something running on port #{OAUTH_REDIRECT_PORT}? Please turn it off to complete the oauth process"
        end
      end

      def authorize_url
        "https://www.yammer.com/oauth2/authorize?client_id=#{OAUTH_CLIENT_ID}&response_type=code&redirect_uri=#{OAUTH_REDIRECT_URL}"
      end

      def open_url(url)
        Lolcommits::CLI::Launcher.open_url(url)
      end

      def local_server
        @local_server ||= WEBrick::HTTPServer.new(
          Port: OAUTH_REDIRECT_PORT,
          Logger: null_logger,
          AccessLog: null_logger
        )
      end

      def null_logger
        WEBrick::Log.new(nil, -1)
      end

      def oauth_response(heading)
        <<-RESPONSE
          <html>
            <head>
              <style>
              body {
                background-color: #36465D;
                text-align: center;
              }

              a { color: #529ecc; text-decoration: none; }
              a img { border: none; }

              img {
                width: 100px;
                margin-top: 100px;
              }

              div {
                margin: 20px auto;
                font: normal 16px "Helvetica Neue", "HelveticaNeue", Helvetica, Arial, sans-serif;
                padding: 20px 40px;
                background: #FEFEFE;
                width: 50%;
                border-radius: 10px;
                color: #757575;
              }

              h1 {
                font-size: 18px;
              }
              </style>
            </head>
            <body>
              <a href="https://lolcommits.github.io">
                <img src="https://lolcommits.github.io/assets/img/logo/lolcommits_logo_400px.png" alt="lolcommits" width="100px" />
              </a>
              <div>
                <h1>#{heading}</h1>
              </div>
            </body>
          </html>
        RESPONSE
      end

      def server_callback
        proc do |req, res|
          local_server.stop
          local_server.shutdown

          query = req.request_uri.query
          query = CGI.parse(req.request_uri.query) if query

          if query && !query['code'].empty?
            @oauth_code = query['code']
            res.body = oauth_response("Lolcommits Yammer Authorization Complete")
          else
            res.body = oauth_response("Lolcommits Authorization Cancelled")
          end
        end
      end
    end
  end
end
