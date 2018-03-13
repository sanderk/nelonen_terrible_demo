# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).
Changelog based on guidelines from [Keep a CHANGELOG](http://keepachangelog.com/).

## 1.1.0 - 2018-02-16
### Added
- Site type basic. No uwsgi/php/proxy. Just locations.

## 1.0.2 - 2017-10-19
### Fixed
- Logrotate now correctly handles multiple sites, no longer resulting in only the last site having logrotate.

## 1.0.1 - 2017-04-21
### Fixed
- Missing /etc/nginx directories assumed to be present by openresty.
- Bug in conditionals in default config handling.
- Deprecation warnings by ansible 2.3.x.

## 1.0.0 - 2017-03-22
### Added
- Option to install openresty instead of default nginx
- Caches can be defined with cache dirs automatically created
- Listen directive in server can be specified as list
- Ability to disable /etc/nginx/conf.d/default.conf
### Fixed
- Fixed an issue where nginx was not being reloaded due to the fact that we were registering multiple tasks to the
  variable `site_config`. Which is allowed, but has a different behaviour. The vairable gets a `results` attribute
  containing a list of all tasks that are registered to it. Unfortunately we cannot loop over that list in our current
  setup, so we now have different register names for each task.
- Site config indenting
- Fixed root headers regression introduced in a847f4943aa

## 0.4.2 - 2017-01-10
### Fixed
- Fixed CORS headers regression introduced in a847f4943aa

## 0.4.0 - 2016-12-12
### Added
- Variable at HTTP level to defined logformats
- Flag to use RealIP, it will use X-Forwarded-For when request is coming for 10.0.0.0/8 (ELB, or internal)
- Server level: Specify urls to be ignored when logging access (typcally for ELB monitoring spam)
### Changed
- Flag to allow requests without origin header (when using CORS whitelisting)

## 0.3.9 - 2016-10-31
### Added
- You can now enable redirect to https for uwsgi sites.
- You can now add headers for the root location for uwsgi sites.
### Fixed
- Fix typo for defining aliases

## 0.3.8 - 2016-10-20
### Changed
- Expanded the nginx uwsgi config to be able to add any parameters to the extra location block, backward compatible.
### Added
- to the nginx uwsgi config: top level parameters for basic auth and configuring the listening interface
- to the nginx uwsgi config: the possiblity to use CORS (Whitelist style, not *) for the root location and others.

## 0.3.7 - 2016-09-26
### Changed
- Expanded the nginx proxy config, with backward compatibility in mind.

## 0.3.6 - 2016-07-29
### Changed
- Introduced some extra variables in nginx.conf for working with events, with the existing values as defaults.


## 0.3.5 - 2016-07-29
### Changed
- Introduced some variables in nginx.conf, with the existing values as defaults.

## 0.3.4 - 2016-07-27
### Fixed
- nginx service is now enabled

## 0.3.3 - 2016-07-12
### Changed
- Added condition for nginx_sites. Sometimes, all you want is install and configure a basic NGINX setup, and use a completely custom vhost config

## 0.3.2 - 2016-06-10
### Fixed
- typo fix in log format

## 0.3.1 - 2016-06-10
### Added
- client_max_body_size param for site
### Changed
- removed tag 0.3.0 due to not being in master

## 0.2.0 - 2016-05-11
### Added
- PHP site type
- Monitor
### Changed
- Increased server_names_hash_bucket_size to 128

## 0.1.0 - 2016-04-15
### Added
- Uwsgi site type
- Proxy site type
- Logrotate
