# RocketPants Change Log

**Please Note**: This change log only covers v1.3 forwards - apologies for anything missing prior to that.

## Version 1.13.0

* Support for Bugsnag and documentation tweaks around notifications.

## Version 1.12.1

* Fix for scopes and nested serialization working correctly (change Array check to `#to_ary`, as we should).

## Version 1.12.0

* RSpec 3.0 Differ fixes, Thanks to [newdark](https://github.com/newdark).
* Fix deprecation warning for `path_parameters` in 4.2, Thanks to [davidpdrsn](https://github.com/davidpdrsn).
* Travis CI fixes, Thanks to [DamirSvrtan](https://github.com/DamirSvrtan).
* Support for `:each_serializer`.

## Version 1.11.0

* Support for RSpec >= 3.0

## Version 1.10.0

* Remove .rvmrc because is deprecated in favor of .ruby-version and .ruby-gemset
* 'expose' method now validates invalid single objects
* `next` on kaminari with an empty result set should return the correct value.

## Version 1.9.2

* Support for Rails 4.1.0's changed Record Identifier class.

## Version 1.9.1

* `encode_to_json` hook for internal refactoring.

## Version 1.9.0

* Bump hashie version to support 1.0 and 2.0 versions. Note I've bumped to 1.9.0 to avoid
  accidentally breaking anyone who requires 1.0 and doesn't specify it directly (dudes...)

## Version 1.8.2

* Remove test deprecation notice on Rails 4.

## Version 1.8.1

* Fix the test helper on Rails 3.0.
* Get travis working again.

## Version 1.8.0

* Strong Parameter and test tweaks, thanks to [joergschiller](https://github.com/joergschiller).
* Better explanation for error handling, thanks to [ahegyi](https://github.com/ahegyi).
* Change the order of Instrumentation in RocketPants so it correct logs the error results.

## Version 1.7.0

* Make RocketPants work with Rails 4.0.0.beta1, Test against Ruby 2.0.0.

Note: This is a rather large change to the dependencies, hence the minor version bump.

## Version 1.6.0, 1.6.1

* ActiveModel Serializer Support
* Fix to avoid exposing exception messages in production.

## Version 1.5.4

* Add in `RocketPants::Forbidden` at the request of @dangalipo.

## Version 1.5.3

* Add in support for messages on `RocketPants::InvalidResource` to `RocketPants::Client`, thanks to @fredwu

## Version 1.5.2

* Map `ActiveRecord::RecordNotUnique` to `RocketPants::Conflict`.

## Version 1.5.1

* Merge in a fix from [nagash](https://github.com/nagash) that prevents reusing decoded / parsed responses in the test helper.

## Version 1.5

* Add in a built in `:invalid_resource` error, with support for passing through error messages.
* Support for ActiveRecord exceptions out of the box (See the README).
* Don't hide errors by default in `development` and `test`, respect `config.rocket_pants.pass_through_errors` and `RocketPants.pass_through_errors`.
* Allow specifying `:metadata` in context on errors / expose and add it directly to the response.
* Allow specifying `:metadata` in expose on objects.
* `RocketPants::Base.map_error!` now accepts lambdas as the target value / convertor.

## Version 1.4

* Add in a built in `:bad_request` error.
* Provide `:base` on `RocketPants::Errors.register!` will set the base class.
* Fixed integration with `will_paginate` and expanded our integration specs to be better.

## Version 1.3

* Fixed a bug where any request with an etag would return `304 Not Modified` when the caching middleware was enabled.
* Support for header metadata - Simply set `RocketPants.header_metadata = true` or `config.rocket_pants.header_metadata = true`
  and rocket pants will mirror the response metadata to `X-Api-*` headers, e.g. `X-Api-Count: 2` for a collection response with
  two items. This makes it suitable for use in `HEAD` requests. Please note, the client doesn't currently support this.
* Support for automatically generating the `Link: ` header for paginated responses. Simply implement `page_url(page_number)` in your
  controller, returning nil when it's a valid page, and rocket pants will add the headers for you. Also, you can use the `link(rel, href, attributes = {})`
  and `links(ref => type)` to manually add header links.