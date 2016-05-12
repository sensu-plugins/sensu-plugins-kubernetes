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

require 'sensu-plugins-kubernetes/cli'

class ApiServerIsAvailable < Sensu::Plugins::Kubernetes::CLI
  @options = Sensu::Plugins::Kubernetes::CLI.options.reject { |k| k == :api_version }

  def run
    if healthy?
      ok 'Kubernetes API server is available'
    end
    critical 'Kubernetes API server is unavailable'
  end

  # TODO: replace this method when it's added to kubeclient
  def healthy?
    client.handle_exception do
      client.create_rest_client('/healthz').get(client.headers)
    end
    true
  rescue KubeException
    false
  end
end
