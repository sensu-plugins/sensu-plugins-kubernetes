require 'kubeclient'
require 'uri'

module Sensu
  module Plugins
    # Namespace for the Kubernetes sensu-plugin.
    module Kubernetes
      # A mixin module that provides Kubernetes client (kubeclient) support.
      module Client
        # The location of the service account provided CA.
        # (if the cluster is configured to provide it)
        INCLUSTER_CA_FILE =
          '/var/run/secrets/kubernetes.io/serviceaccount/ca.crt'.freeze

        # The location of the service account provided authentication token.
        INCLUSTER_TOKEN_FILE =
          '/var/run/secrets/kubernetes.io/serviceaccount/token'.freeze

        # Creates a new Kubeclient::Client instance using the given SSL
        # and authentication options (if any)
        #
        # @param [Hash] options The Kubernetes API connection details.
        # @option options [String] :server URL to API server
        # @option options [String] :version API version
        # @option options [Boolean] :incluster
        #   Use service account authentication if true
        # @option options [String] :ca_file
        #   CA file used to verify API server certificate
        # @option options [String] :client_cert_file
        #   Client certificate file to present
        # @option options [String] :client_key_file
        #   Client private key file for the client certificate
        # @option options [String] :username
        #   Username with access to API
        # @option options [String] :password
        #   If a username is passed, also pass a password
        # @option options [String] :token
        #   The bearer token for Kubernetes authorization
        # @option options [String] :token_file
        #   A file containing the bearer token for Kubernetes authorization
        # @option options [String] :kube_config
        #   A file containing kubeconfig yaml configuration
        #
        # @raise [ArgumentError] If an invalid option, or combination of options, is given.
        # @raise [Errono::*] If there is a problem reading the client certificate or private key file.
        # @raise [OpenSSL::X509::CertificateError] If there is a problem with the client certificate.
        # @raise [OpenSSL::PKey::RSAError] If there is a problem with the client private key.
        def kubeclient(options = {})
          raise(ArgumentError, 'options must be a hash') unless options.is_a?(Hash)

          if options[:kube_config]
            begin
              config = Kubeclient::Config.read(options[:kube_config])

              api_server = config.context.api_endpoint
              api_version = config.context.api_version

              ssl_options = config.context.ssl_options
              auth_options = config.context.auth_options
            rescue => e
              raise e, "Unable to read kubeconfig: #{e}", e.backtrace
            end
          else
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
          end

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
            raise ArgumentError, "Invalid API server: #{e}", e.backtrace
          end
        end
      end
    end
  end
end
