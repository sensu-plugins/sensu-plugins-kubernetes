#! /usr/bin/env ruby
#
#   handler-kube-pod
#
# DESCRIPTION:
# => Deletes pods from the k8s cluster and sensu, intended to be used as a
#    keepalive handler.
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
# -j JSONCONFIG - The config file to us
#
# NOTES:
#
# LICENSE:
#   Justin McCarty <jmccarty3@gmail.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-handler'
require 'kubeclient'
require 'json'

class KubePod < Sensu::Handler
  option :json_config,
         description: 'Configuration name',
         short: '-j JSONCONFIG',
         long: '--json JSONCONFIG',
         default: 'k8s'

  def api_server
    get_setting('api_server') || ENV['KUBERNETES_MASTER']
  end

  def api_version
    get_setting('api_version') || 'v1'
  end

  def get_setting(name)
    settings[config[:json_config]][name]
  end

  def handle
    puts 'K8 handler'
    response = api_request(:DELETE, '/clients/' + @event['client']['name']).code
    deletion_status(response)
    begin
      client = Kubeclient::Client.new(api_server, api_version)
      client.delete_pod @event['client']['name']
    rescue KubeException => e
      puts "[Kube Pod] KubeException: #{e.message}"
    rescue StandardError => e
      puts "[Kube Pod] Unknown error #{e}"
    end
  end

  def deletion_status(code)
    case code
    when '202'
      puts "[Kube Pod] 202: Successfully deleted Sensu client: #{@event['client']['name']}"
    when '404'
      puts "[Kube Pod] 404: Unable to delete #{@event['client']['name']}, doesn't exist!"
    when '500'
      puts "[Kube Pod] 500: Miscellaneous error when deleting #{@event['client']['name']}"
    else
      puts "[Kube Pod] #{code}: Completely unsure of what happened!"
    end
  end
end
