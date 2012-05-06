# RocketPants Change Log

**Please Note**: This change log only covers v1.3 forwards - apologies for anything missing prior to that.

## Version 1.3

* Fixed a bug where any request with an etag would return `304 Not Modified` when the caching middleware was enabled.
* Support for header metadata - Simply set `RocketPants.header_metadata = true` or `config.rocket_pants.header_metadata = true`
  and rocket pants will mirror the response metadata to `X-Api-*` headers, e.g. `X-Api-Count: 2` for a collection response with
  two items. This makes it suitable for use in `HEAD` requests. Please note, the client doesn't currently support this.
* Support for automatically generating the `Link: ` header for paginated responses. Simply implement `page_url(page_number)` in your
  controller, returning nil when it's a valid page, and rocket pants will add the headers for you. Also, you can use the `link(rel, href, attributes = {})`
  and `links(ref => type)` to manually add header links.