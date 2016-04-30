require 'sensu-plugins-kubernetes/version'

require 'sensu-plugin/check/cli'
require 'kubeclient'

module Sensu
    module Plugins
        module Kubernetes
            class CLI < Sensu::Plugin::Check::CLI

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

                def get_client(cli)
                    api_server = cli.config[:api_server]
                    api_version = cli.config[:api_version]

                    begin
                      Kubeclient::Client.new(api_server, api_version)
                    rescue
                      warning 'Unable to connect to Kubernetes API server'
                    end
                end
            end
        end
    end
end
