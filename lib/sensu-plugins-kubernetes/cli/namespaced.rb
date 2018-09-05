module Sensu
  module Plugins
    # Namespace for the Kubernetes sensu-plugin.
    module Kubernetes
      # Allows checks to easily retrieve a kube-client compatible namespace
      # string, and provide flags allowing users to configure this operation.
      module NamespacedCLI
        # The location of the service account namespace file.
        INCLUSTER_NAMESPACE_FILE =
          '/var/run/secrets/kubernetes.io/serviceaccount/namespace'.freeze

        # On inclusion, add options to the including class. This is done because
        # the "option" method is a class method.
        def self.included(base)
          base.send(:option,
                    :in_namespace,
                    description: 'Operate in the namespace of the pod running the check (when running in-cluster)',
                    long: '--in-namespace',
                    boolean: true,
                    default: false)
        end

        # Smart getter for the namespace string queries should be using.
        def namespace
          @namespace ||= determine_namespace
        end

        private

        # If "--in-namespace" is specified, get our pod's namespace. Otherwise,
        # perform cluster-wide requests.
        def determine_namespace
          # By default, perform cluster-wide requests
          return '' unless config[:in_namespace]

          begin
            namespace = File.read(INCLUSTER_NAMESPACE_FILE).strip
            unless valid_namespace?(namespace)
              raise "invalid namespace '#{namespace}' found in #{INCLUSTER_NAMESPACE_FILE}"
            end
          rescue StandardError => e
            raise e, "Unable to determine namespace: #{e}", e.backtrace
          end

          namespace
        end

        # Test if a string (ns) is a valid Kubernetes namespace name. Per the
        # docs below, this means a string of 1-63 lower case alphanumeric
        # characters or hyphens, as long as the first character is not a hyphen:
        # https://github.com/kubernetes/community/blob/master/contributors/design-proposals/architecture/identifiers.md#definitions
        def valid_namespace?(ns)
          # rubocop:disable Style/DoubleNegation
          !!(/[a-z0-9][a-z0-9-]{,62}/ =~ ns)
          # rubocop:enable Style/DoubleNegation
        end
      end
    end
  end
end
