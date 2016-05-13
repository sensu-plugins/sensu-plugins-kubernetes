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

                option :ca_file,
                       description: 'CA file to use',
                       long: '--ca-file CA-FILE'

                option :bearer_token,
                       description: 'Kubernetes serviceaccount token',
                       long: '--bearer-token TOKEN'

                option :bearer_token_file,
                       description: 'Kubernetes serviceaccount token file',
                       long: '--bearer-token-file TOKEN-FILE'

                def get_client(cli)
                    api_server = cli.config[:api_server]
                    api_version = cli.config[:api_version]

                    ssl_options = {}
                    auth_options = {}

                    if cli.config.key?(:ca_file)
                        ssl_options[:ca_file] = cli.config[:ca_file]
                    end

                    if cli.config.key?(:bearer_token)
                        auth_options[:bearer_token] = cli.config[:bearer_token]
                    elsif cli.config.key?(:bearer_token_file)
                        auth_options[:bearer_token_file] =
                            cli.config[:bearer_token_file]
                    end

                    begin
                      Kubeclient::Client.new api_server, api_version,
                                             ssl_options: ssl_options,
                                             auth_options: auth_options
                    rescue
                      warning 'Unable to connect to Kubernetes API server'
                    end
                end
            end
        end
    end
end
