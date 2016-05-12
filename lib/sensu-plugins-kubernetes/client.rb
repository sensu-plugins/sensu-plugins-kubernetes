require 'kubeclient'
require 'uri'

module Sensu
  module Plugins
    module Kubernetes
      module Client
        INCLUSTER_CA_FILE =
          '/var/run/secrets/kubernetes.io/serviceaccount/ca.crt'.freeze

        INCLUSTER_TOKEN_FILE =
          '/var/run/secrets/kubernetes.io/serviceaccount/token'.freeze

        def kubeclient(options = {})
          raise(ArgumentError, 'options must be a hash') unless options.is_a?(Hash)

          api_server = options[:server]
          api_version = options[:version]

          ssl_options = {
            ca_file: options[:ca_file]
          }
          auth_options = {
            username: options[:username],
            password: options[:password],
            bearer_token: options[:token],
            bearer_token_file: options[:token_file]
          }

          if [:client_cert_file, :client_key_file].count { |k| options[k] } == 1
            raise ArgumentError, 'SSL requires both client cert and client key'
          end

          if options[:client_cert_file]
            begin
              ssl_options[:client_cert] = OpenSSL::X509::Certificate.new(File.read(options[:client_cert_file]))
            rescue => e
              raise e, "Unable to read client certificate: #{e}", e.backtrace
            end
          end

          if options[:client_key_file]
            begin
              ssl_options[:client_key] = OpenSSL::PKey::RSA.new(File.read(options[:client_key_file]))
            rescue => e
              raise e, "Unable to read client key: #{e}", e.backtrace
            end
          end

          if options[:incluster]
            # Provide in-cluster defaults, if not already specified
            # (following the kubernetes incluster config code, more or less)

            # api-server
            # TODO: use in-cluster DNS ??
            if api_server.nil?
              host = ENV['KUBERNETES_SERVICE_HOST']
              port = ENV['KUBERNETES_SERVICE_PORT']
              if host.nil? || port.nil?
                raise ArgumentError, 'unable to load in-cluster configuration,'\
                     ' KUBERNETES_SERVICE_HOST and KUBERNETES_SERVICE_PORT'\
                     ' must be defined'
              end
              api_server = URI::HTTPS.build(host: host, port: port, path: '/api')
            end

            # ca file, but only if it exists
            if ssl_options[:ca_file].nil? && File.exist?(INCLUSTER_CA_FILE)
              # Readability/permission issues should be left to kubeclient
              ssl_options[:ca_file] = INCLUSTER_CA_FILE
            end

            # token file
            if auth_options[:bearer_token_file].nil?
              auth_options[:bearer_token_file] = INCLUSTER_TOKEN_FILE
            end
          end

          ssl_options[:verify_ssl] = ssl_options[:ca_file] ? OpenSSL::SSL::VERIFY_PEER : OpenSSL::SSL::VERIFY_NONE

          begin
            # new only throws errors on bad arguments
            Kubeclient::Client.new(api_server, api_version,
                                   ssl_options: ssl_options,
                                   auth_options: auth_options)
          rescue URI::InvalidURIError => e
            # except for this one, which we'll re-wrap to make catching easier
            raise ArgumentError, "Invalid API server: #{e.message}", e.backtrace
          end
        end
      end
    end
  end
end
