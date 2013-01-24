# RocketPants Change Log

**Please Note**: This change log only covers v1.3 forwards - apologies for anything missing prior to that.

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