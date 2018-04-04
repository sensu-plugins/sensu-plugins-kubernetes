#!/usr/bin/env ruby
# frozen_string_literal: false

#
# check-kube-pods-running_spec
#
# DESCRIPTION:
#   Tests for check-kube-pods-running.rb
#
# OUTPUT:
#
# PLATFORMS:
#
# DEPENDENCIES:
#
# USAGE:
#   bundle install
#   rake spec
#
require_relative './spec_helper.rb'
require_relative '../bin/check-kube-pods-running.rb'

describe AllPodsAreRunning do
  let(:check) do
    AllPodsAreRunning.new ['-s', 'https://kubernetes']
  end

  describe 'is the pod ready?' do
    it 'returns false if there is no type Ready' do
      pod = instance_double('pod')
      allow(pod).to receive_message_chain(:status, conditions: [])
      expect(check.ready?(pod)).to eq(false)
    end

    it 'returns false if there is type Ready but the status is not true' do
      pod = instance_double('pod')
      allow(pod).to receive_message_chain(:status, conditions: [instance_double('status_ready', type: 'Ready', status: 'False')])
      expect(check.ready?(pod)).to eq(false)
    end

    it 'returns true if there is type Ready and status is true' do
      pod = instance_double('pod')
      allow(pod).to receive_message_chain(:status, conditions: [instance_double('status_ready', type: 'Ready', status: 'True')])
      expect(check.ready?(pod)).to eq(true)
    end
  end
end
