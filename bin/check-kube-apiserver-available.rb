#! /usr/bin/env ruby
#
#   check-kube-apiserver-available.rb
#
# DESCRIPTION:
# => Check if the Kubernetes API server is up
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
require 'net/http'
require 'uri'

class ApiServerIsAvailable < Sensu::Plugin::Check::CLI
    option :api_server,
      description: 'URL to API server',
      short: '-s URL',
      long: '--api-server',
      default: ENV['KUBERNETES_MASTER']

    def run
      cli = ApiServerIsAvailable.new
      api_server = cli.config[:api_server]
      uri = URI.parse "#{api_server}/healthz"

      begin
        response = Net::HTTP.get_response(uri)
      rescue
        warning 'Host is unavailable'
      end

      if response.code.include? '200'
        ok 'Kubernetes API server is available'
      end
      critical 'Kubernetes API server is unavailable'
    end
end
