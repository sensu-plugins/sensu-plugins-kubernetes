# Change Log
This project adheres to [Semantic Versioning](http://semver.org/).

This CHANGELOG follows the format listed at [Keep A Changelog](http://keepachangelog.com/)

## [Unreleased]
### Added
- Add `check-kube-service-endpoints.rb` check (@joemiller)

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

[Unreleased]: https://github.com/sensu-plugins/sensu-plugins-kubernetes/compare/1.1.0...HEAD
[1.1.0]: https://github.com/sensu-plugins/sensu-plugins-kubernetes/compare/1.0.0...1.1.0
[1.0.0]: https://github.com/sensu-plugins/sensu-plugins-kubernetes/compare/0.1.2...1.0.0
[0.1.2]: https://github.com/sensu-plugins/sensu-plugins-kubernetes/compare/0.1.1...0.1.2
[0.1.1]: https://github.com/sensu-plugins/sensu-plugins-kubernetes/compare/0.1.0...0.1.1
[0.1.0]: https://github.com/sensu-plugins/sensu-plugins-kubernetes/compare/0.0.1...0.1.0
