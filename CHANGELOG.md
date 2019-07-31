# Change Log
This project adheres to [Semantic Versioning](http://semver.org/).

This CHANGELOG follows the format listed [here ](https://github.com/sensu-plugins/community/blob/master/HOW_WE_CHANGELOG.md)

## [Unreleased]
### Breaking Changes
- Bump `sensu-plugin` dependency from `~> 2.7` to `~> 4.0` you can read the changelog entries for [4.0](https://github.com/sensu-plugins/sensu-plugin/blob/master/CHANGELOG.md#400---2018-02-17), [3.0](https://github.com/sensu-plugins/sensu-plugin/blob/master/CHANGELOG.md#300---2018-12-04), and [2.0](https://github.com/sensu-plugins/sensu-plugin/blob/master/CHANGELOG.md#v200---2017-03-29)

### Added
- Travis build automation to generate Sensu Asset tarballs that can be used n conjunction with Sensu provided ruby runtime assets and the Bonsai Asset Index
- Require latest sensu-plugin for [Sensu Go support](https://github.com/sensu-plugins/sensu-plugin#sensu-go-enablement)
 - 
## [4.0.0] - 2018-12-15
### Security
- updated rubocop dependency to `~> 0.51.0` per: https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-8418. (@majormoses)
- updated yard dependency to `~> 0.9.11` per: https://nvd.nist.gov/vuln/detail/CVE-2017-17042 (@majormoses)

### Breaking Changes
- drop suppport for ruby versions `< 2.3` as they are EOL (@majormoses)
- bumped dependency of sensu-plugin to 2.x you can read about it [here](https://github.com/sensu-plugins/sensu-plugin/blob/master/CHANGELOG.md#v145---2017-03-07) (@majormoses)

### Changed
- appeased the cops (@majormoses)

## [3.3.0] - 2018-11-26
### Changed
 - `check-kube-pods-running.rb`: Skip a POD which is in the not ready state for shorter time than the specified time. Otherwise, the check alerts if we get lots of new PODs which are spawned every second and get up or get terminated longer than a minute. (@sys-ops)

## [3.2.0] - 2018-11-21
### Changed
 - `check-kube-service-available.rb`: Skip a service if its selector is empty. Otherwise all PODs in the cluster are listed with client.get_pods() call (including those that we do not want to monitor) (@sys-ops)

## [3.1.1] - 2018-11-01
### Fixed
 - `check-kube-nodes-ready.rb`, `check-kube-pods-pending.rb`, `check-kube-pods-restarting.rb`, `check-kube-pods-running.rb`: fix exception when pod.spec.nodeName == nil (i.e. pod not assigned to a node) (@ttarczynski)

## [3.1.0] - 2018-10-29
### Added
 - `check-kube-nodes-ready.rb`, `check-kube-pods-pending.rb`, `check-kube-pods-restarting.rb`, `check-kube-pods-running.rb`: added options `--included-nodes` and `--excluded-nodes` which support a comma separated list so you can filter nodes (@ttarczynski)

### Fixed
- check-kube-pods-running.rb no longer throws an exception when there are no 3 conditions in the status information. Issue #39 (@AgarFu)

## [3.0.0] - 2017-09-12
### Breaking Change
 - check-kube-nodes-ready.rb no longer triggers an alert if an unschedulable node becomes NotReady (@tg90nor)

## [2.0.0] - 2017-08-28
### Added
 - Add option to explicitly include specific namespaces (@simulalex)

### Breaking Change
 - Drops support for Ruby-2.0, now requires Ruby >= 2.1.0 (@simulalex)

## [1.1.0] - 2017-08-11
### Added
- Ruby 2.4.1 testing (@thomasriley)
- Add option to use kubeconfig file for auth and TLS (@jaxxstorm)

## [1.0.0] - 2017-03-21
### Added
- Add `metrics-pods.rb` that will output the number of running pods per service (@mickfeech)
- Add `check-kube-pods-running` check (@nyxcharon)

### Changed
- Update `kubeclient` to 2.3.0 (@jackfengji)
- Split `check-kube-pods-pending` into two checks; the original still checks for
pending pods, the restart count portion has been split into it's own check, `check-kube-pods-restarting`. (@nyxcharon)

## [0.1.2] - 2016-08-07
### Fixed
- check-kube-service-available.rb: fixed error caused by misspelling of true boolean (@justinhammar)

### Changed
- check-kube-pods-pending.rb: Add namespace to output (@ajohnstone)
- check-kube-service-available.rb: Add namespace to output (@ajohnstone)
- pin `activesupport` to `< 5.0.0` to maintain compatability with Ruby < 2.2 (@eheydrick)

## [0.1.1] - 2016-05-17
### Fixed
- cli.rb: Fixed typo in critical call

## [0.1.0] - 2016-05-15
### Added
- Added flag to ignore namespaces in check-kube-pods-pending
- check-kube-service-available.rb: Will not mark a service as failed if any needed pod is running and ready
- check-kube-service-available.rb: Added options to allow of pod pending for given time to be counted as valid
- Factored all checks to share a common base class for connecting to Kubernetes
- Added flags to specify certificate authority and Kubernetes bearer token
- Added flags to specify client certificate/key and in-cluster support
- Support for Ruby 2.3

### Fixed
- check-kube-service-available.rb: Fixed scope issue in main block that would cause a nil error

### Changed
- Update to Rubocop 0.40 and cleanup
- Update to kubeclient 1.1.3

## 0.0.1 - 2016-03-03
### Added
- initial release

[Unreleased]: https://github.com/sensu-plugins/sensu-plugins-kubernetes/compare/4.0.0...HEAD
[4.0.0]: https://github.com/sensu-plugins/sensu-plugins-kubernetes/compare/3.3.0...4.0.0
[3.3.0]: https://github.com/sensu-plugins/sensu-plugins-kubernetes/compare/3.2.0...3.3.0
[3.2.0]: https://github.com/sensu-plugins/sensu-plugins-kubernetes/compare/3.1.1...3.2.0
[3.1.1]: https://github.com/sensu-plugins/sensu-plugins-kubernetes/compare/3.1.0...3.1.1
[3.1.0]: https://github.com/sensu-plugins/sensu-plugins-kubernetes/compare/3.0.1...3.1.0
[3.0.1]: https://github.com/sensu-plugins/sensu-plugins-kubernetes/compare/3.0.0...3.0.0.1
[3.0.0]: https://github.com/sensu-plugins/sensu-plugins-kubernetes/compare/2.0.0...3.0.0
[2.0.0]: https://github.com/sensu-plugins/sensu-plugins-kubernetes/compare/1.1.0...2.0.0
[1.1.0]: https://github.com/sensu-plugins/sensu-plugins-kubernetes/compare/1.0.0...1.1.0
[1.0.0]: https://github.com/sensu-plugins/sensu-plugins-kubernetes/compare/0.1.2...1.0.0
[0.1.2]: https://github.com/sensu-plugins/sensu-plugins-kubernetes/compare/0.1.1...0.1.2
[0.1.1]: https://github.com/sensu-plugins/sensu-plugins-kubernetes/compare/0.1.0...0.1.1
[0.1.0]: https://github.com/sensu-plugins/sensu-plugins-kubernetes/compare/0.0.1...0.1.0
