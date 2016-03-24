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
require 'time'

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

  option :pendingTime,
         description: 'Time (in seconds) a pod may be pending for and be valid',
         short: '-p SECONDS',
         long: '--pending',
         default: 0,
         proc: proc(&:to_i)

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
    cli = AllServicesUp.new
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
      pod_available = false
      pod.each do |p|
        case p.status.phase
        when 'Pending'
          next if p.status.startTime.nil?
          if (Time.now - Time.parse(p.status.startTime)).to_i < cli.config[:pendingTime]
            pod_available = True
            break
          end
        when 'Running'
          p.status.conditions.each do |c|
            next unless c.type == 'Ready'
            if c.status == 'True'
              pod_available = true
              break
            end
            break if pod_available
          end
        end
        failed_services << p.metadata.name if pod_available == false
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
