#! /usr/bin/env ruby
#
#   check-kube-nodes-ready.rb
#
# DESCRIPTION:
# => Check if the Kubernetes nodes are in a ready to use state
#
# OUTPUT:
#   plain text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: kube-client
#
# USAGE:
# -s SERVER - The kubernates SERVER
# -v VERSION - The kubernates api VERSION. Defaults to v1
#
# LICENSE:
#   Kel Cecil <kelcecil@praisechaos.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/check/cli'
require 'json'
require 'kubeclient'
require 'net/https'

class AllNodesAreReady < Sensu::Plugin::Check::CLI
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
         description: 'May only need a bearer token for authorization',
         short: '-t TOKEN',
         long: '--token',
         default: nil

  option :api_ssl_verify_mode,
         description: 'SSL verify mode',
         short: '-svm MODE',
         long: '--ssl-verify-mode',
         default: 'none'

  def run
    cli = AllNodesAreReady.new
    api_server = cli.config[:api_server]
    api_version = cli.config[:api_version]
    api_user = cli.config[:api_user]
    api_password = cli.config[:api_password]
    api_token = cli.config[:api_token]
    api_ssl_verify_mode = cli.config[:api_ssl_verify_mode]

    ssl_verify_mode = nil
    case api_ssl_verify_mode
    when 'none'
      ssl_verify_mode = OpenSSL::SSL::VERIFY_NONE
    when 'peer'
      ssl_verify_mode = OpenSSL::SSL::VERIFY_PEER
    end

    ssl_options = {
      verify_ssl: ssl_verify_mode
    }

    auth_options = {}
    auth_options[:username] = api_user unless api_user.nil?
    auth_options[:password] = api_password unless api_password.nil?
    auth_options[:bearer_token] = api_token unless api_token.nil?

    begin
      client = Kubeclient::Client.new(api_server, api_version, ssl_options: ssl_options, auth_options: auth_options)
    rescue
      warning 'Unable to connect to Kubernetes API server'
    end

    failed_nodes = []
    client.get_nodes.each do |node|
      item = node.status.conditions.detect { |condition| condition.type == 'Ready' }
      if item.nil?
        warning "#{node.name} does not have a status"
      elsif item.status != 'True'
        failed_nodes << node.metadata.name
      end
    end

    if failed_nodes.empty?
      ok 'All nodes are reporting as ready'
    end
    critical "Nodes are not ready: #{failed_nodes.join(' ')}"
  end
end
