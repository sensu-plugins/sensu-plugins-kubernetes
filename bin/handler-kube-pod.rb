#! /usr/bin/env ruby
# frozen_string_literal: true

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
# -j JSONCONFIG - The settings section to use
#
# NOTES:
#
# LICENSE:
#   Justin McCarty <jmccarty3@gmail.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-handler'
require 'sensu-plugins-kubernetes/client'

class KubePod < Sensu::Handler
  include Sensu::Plugins::Kubernetes::Client

  option :json_config,
         description: 'Configuration section name',
         short: '-j JSONCONFIG',
         long: '--json JSONCONFIG',
         default: 'k8s'

  def client_config
    defaults = {
      server: ENV['KUBERNETES_MASTER'],
      version: 'v1'
    }
    h = settings[config[:json_config]]
    if h.is_a?(Hash)
      # Maintain backwards compatibility
      h[:server] ||= h[:api_server]
      h[:version] ||= h[:api_version]
      # And merge
      defaults.merge!(h)
    else
      defaults
    end
  end

  def handle
    puts 'K8 handler'
    response = api_request(:DELETE, '/clients/' + @event['client']['name']).code
    deletion_status(response)
    begin
      client = kubeclient(client_config)
      client.delete_pod @event['client']['name']
    rescue ArgumentError => e
      puts "[Kube Pod] Invalid settings: #{e.message}"
    rescue KubeException => e
      puts "[Kube Pod] KubeException: #{e.message}"
    rescue Exception => e # rubocop:disable Lint/RescueException
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
