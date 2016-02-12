#! /usr/bin/env ruby
#
#   check-kube-pods-service-available
#
# DESCRIPTION:
# => Check if your kube services are up and ready
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
# -s SERVER - The kube server to use
# -l SERVICES - The comma delimited list of services to check
#
# NOTES:
#
# LICENSE:
#   Barry Martin <nyxcharon@gmail.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/check/cli'
require 'json'
require 'kubeclient'

class AllServicesUp < Sensu::Plugin::Check::CLI
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

  option :service_list,
         description: 'List of services to check',
         short: '-l SERVICES',
         long: '--list',
         required: true

  def run
    cli = AllServicesUp.new
    api_server = cli.config[:api_server]
    api_version = cli.config[:api_version]

    begin
      client = Kubeclient::Client.new(api_server, api_version)
    rescue
      warning 'Unable to connect to Kubernetes API server'
    end

    services = parse_list(cli.config[:service_list])
    failed_services = []
    s = client.get_services
    s.each do |a|
      next unless services.include?(a.metadata.name)
      # Build the selector key so we can fetch the corresponding pod
      selector_key = []
      services.delete(a.metadata.name)
      a.spec.selector.to_h.each do |k, v|
        selector_key << "#{k}=#{v}"
      end
      # Get the pod
      pod = nil
      begin
        pod = client.get_pods(label_selector: selector_key.join(',').to_s)
      rescue
        failed_services << a.metadata.name.to_s
      end
      # Make sure our pod is running
      next if pod.nil?
      pod.each do |p|
        unless p.status.phase.include?('Running')
          failed_services << p.metadata.name
        end
      end
    end

    if failed_services.empty? && services.empty?
      ok 'All services are reporting as up'
    end

    if !failed_services.empty?
      critical "All services are not ready: #{failed_services.join(' ')}"
    else
      critical "Some services could not be checked: #{services.join(' ')}"
    end
  end

  def parse_list(list)
    return list.split(',') if list && list.include?(',')
    return [list] if list
    ['']
  end
end
