# Rocket Pants!

First thing's first, you're probably asking yourself - "Why the ridiculous name?". It's simple, really - Rocket Pants is memorable, and sounds completely bad ass. Everything a library needs.

At it's core, Rails is a set of tools (built around existing toolsets such as ActionPack) to make it easier to build well-designed API's in Ruby and, more importantly, along side Rails. You can think of it like [Grape](https://github.com/intridea/grape), a fantastic library which RocketPants was original inspired by but with deeper Rails and ActionPack integration.

## Key Features

Why use Rocket Pants over alternatives like Grape or normal Rails? The reasons we built it come down to a couple of
simple things:

1. **It's opinionated** (like Grape) - In this case, we dictate a certain JSON structure we've found nice to work with (after having worked with and investigated a large number of other apis), it makes it simple to add metadata along side requests and the like.
2. **Simple and Often Automatic Response Metadata** - Rocket Pants automatically takes care of sending metadata about paginated responses and arrays where possible. This means as a user, you only need to worry about writing `expose object_or_presenter` in your controller and Rocket Pants will do it's best to send as much information back to the user.
3. **Extended Error Support** - Rocket Pants has a build in framework to manage errors it knows how to handle (in the forms of mapping exceptions to a well defined JSON structure) as well as tools to make it simple to hook up to Airbrake and do things such as including an error identifier in the response.
4. **It's build on ActionPack** - One of the key differentiators to Graphe is that Rocket Pants embraces ActionPack and uses the modular components included from Rails 3.0 onwards to provide things you're familiar with already such as filters.
5. **Semi-efficient Caching Support** - Thanks to a combination of Rails middleware and collection vs. resource distinctions, Rocket Pants makes it relatively easy to implement "Efficient Validation" (See 'http://rtomayko.github.com/rack-cache/faq' [here](http://rtomayko.github.com/rack-cache/faq)). As a developer, this means you get even more benefits of http caching where possible, without the need to generate full requests when
etags are present.

## General Structure

RocketPants builds upon the mixin-based approach to ActionController-based rails applications that Rails 3 made possible. Instead of including everything like Rails does in `ActionController::Base`, RocketPants only includes the bare minimum to make apis. In the near future, it may be modified to work with `ActionController::Base` for the purposes of better compatibility with other gems.

Out of the box, we use the following ActionController components:

* `ActionController::HideActions` - Lets you hide methods from actions.
* `ActionController::UrlFor` - `url_for` helpers / tweaks by Rails to make integration with routes work better.
* `ActionController::Redirecting` - Allows you to use `redirect_to`.
* `ActionController::ConditionalGet` - Adds support for Rails caching controls, e.g. `fresh_when` and `expires_in`.
* `ActionController::RackDelegation` - Lets you reset the session and set the response body.
* `ActionController::RecordIdentifier` - Gives `dom_class` and `dom_id` methods, used for polymorphic routing.
* `ActionController::MimeResponds` - Gives `respond_to` with mime type controls.
* `AbstractController::Callbacks` - Adds support for callbacks / filters.
* `ActionController::Rescue` - Lets you use `rescue_from`.

And add our own:

* `RocketPants::UrlFor` - Automatically includes the current version when generating URLs from the controller.
* `RocketPants::Respondable` - The core of RocketPants, the code that handles converting objects to the different container types.
* `RocketPants::Versioning` - Allows versioning requirements on the controller to ensure it is only callable with a specific api version.
* `RocketPants::Instrumentation` - Adds Instrumentation notifications making it easy to use and hook into with Rails.
* `RocketPants::Caching` - Implements time-based caching for index actions and etag-based efficient validation for singular resources.
* `RocketPants::ErrorHandling` - Short hand to create errors as well as simplifications to catch and render a standardised error representation.
* `RocketPants::Rescuable` - Allows you to hook in to rescuing exceptions and to make it easy to post notifications to tools such as AirBrake.

To use RocketPants, instead of inheriting from `ActionController::Base`, just inherit from `RocketPants::Base`.

Likewise, in Rails applications RocketPants also adds `RocketPants::CacheMiddleware` before the controller endpoints to implement
["Efficient Validation"](http://rtomayko.github.com/rack-cache/faq).

## Installing RocketPants

Installing RocketPants is a simple matter of adding:

    gem 'rocket_pants', '~> 1.0'

To your `Gemfile` and running `bundle install`. Next, instead of inherited from `ActionController::Base`, simply
inherit from `RocketPants::Base` instead. If you're working with an API-only application, I typically change this
in `ApplicationController` and inherit from `ApplicationController` as usual. Otherwise, I generate a new `ApiController`
base controller along side `ApplicationController` which instead inherits from `RocketPants::Base` and place all my logic
there.

## Configuration

Setting up RocketPants in your rails application is pretty simple and requires a minimal amount of effort. Inside your environment configuration, RocketPants offers the
following options to control how it's configured (and their expanded alternatives):

- `config.rocket_pants.use_caching` - Defaulting to true for production environments and false elsewhere, defines whether RocketPants caching setup as described below is used.
- `config.rocket_pants.cache` - A `Moneta::Store` instance used as the rocket pants cache, defaulting to a moneta memory instance. Change for proper caching. (See [here](https://github.com/wycats/moneta) for more information on Moneta.)

## Version Controllers / Routes

The current preferred way of dealing with version APIs in RocketPants is to do it using routes in the form of `/:version/:endpoint` - e.g. `GET /1/users/324`.
RocketPants has support in the router and controller level for enforcing and controlling this. In the controller, it's a matter of specifying the required API versions:

    class UsersController < RocketPants::Base
      version 1 # A single version
      # or...
      version 2..3 # 2-3 support this controller
    end

And in the case of multiple versions, I strongly encourage namespaces the controllers inside modules. If the version param (as specified) by the URL does not match, then the specified
controllre will return an `:invalid_version` error as shown below.

Next, in your `config/routes.rb` file, you can also declare versions using the following syntax and it will automatically set up the routes for you:

    api :version => 1 do
      get 'x', :to => 'test#item'
    end

Which will route `GET /1/x` to `TestController#item`.

Likewise, you can specify a route for multiple versions by:

    api :versions => 1..3 do
      get 'x', :to => 'test#item'
    end

## Working with data

When using RocketPants, you write your controllers the same as how you would with normal ActionController, the only thing that
changes is how yoy handle data. `head` and `redirect_to` still work exactly the same as in Rails, but instead of using `respond_with` and
`render` you instead use RocketPant's `exposes` methods (and it's kind). Namely:

- `expose` / `exposes` - The core of all type conversion, will check the type of data and automatically convert it to the correct time (for either a singular, collection or paginated resource).
- `paginated` - Render an object as a paginated collection of data.
- `collection` - Renders a collection of objects - e.g. an array of users.
- `resource` - Renders a single object.

Along side the above that wrap data, it also provides:

- `responds` - Renders JSON, normalizing the object first (unwrapped).
- `render_json` - Renders an object as JSON.

### Singular Resources

Singular resources will be converted to json via `serializable_hash`, passing through any objects
and then wrapped in an object as the `response` key:

    {
      "response": {
        "your": "serialized-object"
      }
    }

### Collections

Similar to singular resources, but also include extra data about the count of items.

    {
      "response": [{
        "name": "object-one"
      }, {
        "name": "object-two"
      }],
      "count": 2
    }

### Paginated Collections

The final type, similar to paginated objects but it includes details about the paginated data:

    {
      "response": [
        {"name": "object-one"},
        {"name": "object-two"},
        {"name": "object-three"},
        {"name": "object-four"},
        {"name": "object-five"}
      ],
      "count": 5,
      "pagination": {
        "previous": 1,
        "next":     3,
        "current":  2,
        "per_page": 5,
        "count":    23
        "pages":    5
      }
    }    

## Registering / Dealing with Errors

One of the built in features of rocketpants is the ability to handle rescuing / controlling exceptions and more importantly to handle mapping
exceptions to names, messages and error codes.

This comes in useful when you wish to automatically convert exceptions such as `ActiveRecord::RecordNotFound` to a structured bit of data in
the response. Namely, it makes it trivial to generate objects that follow the JSON structure of:

    {
      "error":             "standard_error_name",
      "error_description": "A translated error message describing what happened."
    }

It also adds a facilities to make it easy to add extra information to the response.

RocketPants will also attempt to convert all errors in the controller, defaulting to the `"system"` exception name and message as the error description. We also provide a registry to allow throwing exception from their symbolic name like so:

    error! :not_found

In the controller.

Out of the box, the following exceptions come pre-registered and setup:

- `:throttled` - The user has hit an api throttled error.
- `:unauthenticated` - The user doesn't have valid authentication details.
- `:invalid_version` - An invalid API version was specified.
- `:not_implemented` - The specified endpoint is not yet implemented.
- `:not_found` - The given resource could not be found.

## Implementing Efficient Validation

One of the core design principles built into RocketPants is simple support for "Efficient Validation" as described in the
[Rack::Cache FAQ](http://rtomayko.github.com/rack-cache/faq) - Namely, it adds simple support for object-level caching using
etags with fast verification thanks to the `RocketPants::CacheMiddleware` cache middleware.

To do this, it uses `RocketPants.cache`, by default any Moneta-based store, to keep a mapping of object -> current cache key.
Rocket Pants will then generate the etag when caching is enabled in the controller for singular-responses, generating an etag that can be quickly validated.

For example, you'd add the following to your model:

    class User < ActiveRecord::Base
      include RocketPants::Cacheable
    end

And then in your controller, you'd have something like:

    class UsersController < RocketPants::Base

      version 1

      # Time based, e.g. collections, will be cached for 5 minutes - whilst singular
      # items e.g. show will use etag-based caching:
      caches :show, :index, :caches_for => 5.minutes

      def index
        expose User.all
      end

      def show
        expose User.find(params[:id])
      end

    end

When the user hits the index endpoint, it will generate an expiry-based caching header that caches the result for up to 5 minutes.
When the user instead hits the show endpoint, it will generate a special etag that contains and object identifier portion and an
object cache key. Inside `RocketPants.cache`, we store the mapping and then inside `RocketPants::CacheMiddleware`, we simply check
if the given cache key matches the specified object identifier. If it does, we return a not modified response otherwise we pass
it through to controller - giving the advantage of efficent caching without having to hit the full database on every request.

## An Example Controller / App

TODO: Link to the transperth client here.

## Using with Rspec

RocketPants includes a set of helpers to make testing controllers built on `RocketPants::Base` simpler. 

* `be_singular_resource` - Checks the response is a single resource - e.g. `response.should be_siingular_resource`.
* `be_collection_resource` - Checks the response is collection of resources - e.g. `response.should be_collection_resource`.
* `be_paginated_response` - Checks the response is paginated - e.g. `response.should be_paginated_response`.
* `be_api_error(type = any)` - Checks it returned an error for the specified exception (or check the response is an error without any argument) - e.g. `response.should be_api_error RocketPants::NotFound`.
* `have_exposed(data, options = {})` - Given an object and conversion options, lets you check the output exposed the same object. e.g: `response.should have_exposed user`

Likewise, it adds the following helper methods:

- `parsed_body` - A parsed-JSON representation of the response.
- `decoded_body` - A `Hashie::Mash` of the response body.

To set up the integration, in your `spec/spec_helper.rb` add:

    config.include RocketPants::TestHelper,    :type => :controller
    cconfig.include RocketPants::RSpecMatchers, :type => :controller

Inside the `RSpec.configure do |config|` block.

## Contributing

We encourage all community contributions. Keeping this in mind, please follow these general guidelines when contributing:

* Fork the project
* Create a topic branch for what you’re working on (git checkout -b awesome_feature)
* Commit away, push that up (git push your\_remote awesome\_feature)
* Create a new GitHub Issue with the commit, asking for review. Alternatively, send a pull request with details of what you added.
* Once it’s accepted, if you want access to the core repository feel free to ask! Otherwise, you can continue to hack away in your own fork.

Other than that, our guidelines very closely match the GemCutter guidelines [here](http://wiki.github.com/qrush/gemcutter/contribution-guidelines).

(Thanks to [GemCutter](http://wiki.github.com/qrush/gemcutter/) for the contribution guide)

## License

API Smith is released under the MIT License (see the [license file](LICENSE)) and is
copyright Filter Squad, 2012.