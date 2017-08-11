require 'sensu-plugin/check/cli'
require 'sensu-plugins-kubernetes/client.rb'

module Sensu
  module Plugins
    # Namespace for the Kubernetes sensu-plugin.
    module Kubernetes
      # Abstract base class for a Sensu check that also provides
      # Kubernetes client connection support.
      class CLI < Sensu::Plugin::Check::CLI
        include Sensu::Plugins::Kubernetes::Client

        option :api_server,
               description: 'URL to API server',
               short: '-s URL',
               long: '--api-server',
               default: ENV['KUBERNETES_MASTER']

        option :api_version,
               description: 'API version',
               short: '-v VERSION',
               long: '--api-version',
               default: 'v1'

        option :api_incluster,
               description: 'Use service account authentication',
               long: '--in-cluster',
               boolean: true,
               default: false

        option :api_ca_file,
               description: 'CA file to verify API server cert',
               long: '--ca-file CA-FILE',
               default: nil

        option :api_client_cert,
               description: 'Client cert to present',
               long: '--cert CERT-FILE',
               default: nil

        option :api_client_key,
               description: 'Client key for the client cert',
               long: '--key KEY-FILE',
               default: nil

        option :api_user,
               description: 'User with access to API',
               short: '-u USER',
               long: '--user',
               default: nil

        option :api_password,
               description: 'If user is passed, also pass a password',
               short: '-p PASSWORD',
               long: '--password',
               default: nil

        option :api_token,
               description: 'Bearer token for authorization',
               short: '-t TOKEN',
               long: '--token',
               default: nil

        option :api_token_file,
               description: 'File containing bearer token for authorization',
               long: '--token-file TOKEN-FILE',
               default: nil

        option :kube_config,
               description: 'Path to a kube config file',
               long: '--kube-config KUBECONFIG',
               default: nil

        attr_reader :client

        # Initializes the Sensu check by creating a Kubernetes client
        # from the given options and will report a critical error if
        # those arguments are incorrect.
        def initialize
          super()
          begin
            @client = kubeclient(
              server: config[:api_server],
              version: config[:api_version],
              incluster: config[:api_incluster],
              ca_file: config[:api_ca_file],
              client_cert_file: config[:api_client_cert],
              client_key_file: config[:api_client_key],
              username: config[:api_user],
              password: config[:api_password],
              token: config[:api_token],
              token_file: config[:api_token_file],
              kube_config: config[:kube_config]
            )
          rescue ArgumentError => e
            critical e.message
          end
        end
      end
    end
  end
end
