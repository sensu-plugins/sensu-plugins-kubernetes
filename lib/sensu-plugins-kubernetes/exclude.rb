# frozen_string_literal: true

module Sensu
  module Plugins
    # Namespace for the Kubernetes sensu-plugin.
    module Kubernetes
      # A mixin module that provides filtering functions.
      module Exclude
        # Filters the list of pods or nodes based on include/exclude options.
        #
        # @option options [String] :exclude_nodes
        #   Exclude the specified nodes (comma separated list)
        #   Exclude wins when a node is in both include and exclude lists
        # @option options [String] :include-nodes
        #   Include the specified nodes (comma separated list), an
        #   empty list includes all nodes
        def node_included?(node_name)
          if config[:include_nodes].empty?
            true
          else
            config[:include_nodes].include?(node_name)
          end
        end

        def node_excluded?(node_name)
          config[:exclude_nodes].include?(node_name)
        end

        def should_exclude_node(node_name)
          if node_name.nil?
            false
          else
            node_excluded?(node_name) || !node_included?(node_name)
          end
        end
      end
    end
  end
end
