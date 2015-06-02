# Rocket Pants! [![Build Status](https://secure.travis-ci.org/Sutto/rocket_pants.png?branch=master)](http://travis-ci.org/Sutto/rocket_pants)

**Please Note:** Work on RocketPants 2.0 is currently underway on the [2.0-rewrite](https://github.com/Sutto/rocket_pants/tree/2.0-rewrite) branch. Please check there before requesting features.

## Introduction

First thing's first, you're probably asking yourself - "Why the ridiculous name?". It's simple, really - RocketPants is memorable, and sounds completely bad ass. - everything a library needs.

At its core, RocketPants is a set of tools (built around existing toolsets such as ActionPack) to make it easier to build well-designed APIs in Ruby and more importantly, along side Rails. You can think of it like [Grape](https://github.com/intridea/grape), a fantastic library which RocketPants was originally inspired by but with deeper Rails and ActionPack integration.

## Key Features

Why use RocketPants over alternatives like Grape or normal Rails? The reasons we built it come down to a couple of simple things:

1. **[It's opinionated](#working-with-data)** (like Grape) - In this case, we dictate a certain JSON structure we've found nice to work with (after having worked with and investigated a large number of other apis), it makes it simple to add metadata along side requests and the like.
2. **[Simple and Often Automatic Response Metadata](#collections)** - RocketPants automatically takes care of sending metadata about paginated responses and arrays where possible. This means as a user, you only need to worry about writing `expose object_or_presenter` in your controller and RocketPants will do it's best to send as much information back to the user.
3. **[Extended Error Support](#registering--dealing-with-errors)** - RocketPants has a built in framework to manage errors it knows how to handle (in the forms of mapping exceptions to a well defined JSON structure) as well as tools to make it [simple to hook up to Airbrake](#tracking-errors-w-airbrake-honeybadger-or-bugsnag) and do things such as including an error identifier in the response.
4. **[It's built on ActionPack](#general-structure)** - One of the key differentiators to Grape is that RocketPants embraces ActionPack and uses the modular components included from Rails 3.0 onwards to provide things you're familiar with already such as filters. If you're using Strong Parameters (e.g. in Rails 4), we'll even give you support for that.
5. **[Semi-efficient Caching Support](#implementing-efficient-validation)** - Thanks to a combination of Rails middleware and collection vs. resource distinctions, RocketPants makes it relatively easy to implement "Efficient Validation" (See [here](#implementing-efficient-validation)). As a developer, this means you get even more benefits of http caching where possible, without the need to generate full requests when etags are present.
6. **[Simple tools to consume RocketPants apis](#example-client-code)** - RocketPants includes the `RocketPants::Client` class which builds upon [APISmith](https://github.com/Sutto/api_smith) to make it easier to build clients e.g. automatically converting paginated responses back.
7. **[Built-in Header Metadata Support](#header-metadata)** - APIs can easily expose `Link:` headers (it's even partly built-in for paginated data - see below), and request metadata (e.g. Object count, etc.) can easily be embedded in the headers of the response, making useful `HEAD` requests.
8. **[Out of the Box ActiveRecord mapping](#built-in-activerecord-errors)** - We'll automatically take care of mapping `ActiveRecord::RecordNotFound`, `ActiveRecord::RecordNotSaved` and `ActiveRecord::RecordInvalid` for you, even including validation messages where possible.
9. **[Support for active_model_serializers](https://github.com/rails-api/active_model_serializers)** - If you want to use ActiveModelSerializers, we'll take care of it. Even better, in your expose call, pass through `:serializer` as expected (or `:each_serializer`) and we'll automatically take care of invoking it for you.

## Examples

### A full example application

Learn better by reading code? There is also have an example app mixing models and api clients over at [Sutto/transperth-api](https://github.com/Sutto/transperth-api) that is built using RocketPants.

### Example Server Code

Say, for example, you have a basic Food model:

```ruby
class Food < ActiveRecord::Base
  include RocketPants::Cacheable
end
```

```ruby
class FoodsController < RocketPants::Base

  version 1

  # The list of foods is cached for 5 minutes, the food itself is cached
  # until it's modified (using Efficient Validation)
  caches :index, :show, :cache_for => 5.minutes

  def index
    expose Food.paginate(:page => params[:page])
  end

  def show
    expose Food.find(params[:id])
  end

end
```

And in the router we'd just use the normal REST-like routes in Rails:

```ruby
api :version => 1 do
  resources :foods, :only => [:index, :show]
end
```

And then, using this example, hitting `GET http://localhost:3000/1/foods` would result in:

```json
{
  "response": [{
    "id":    1,
    "name": "Delicious Food"
  }, {
    "id":   2,
    "name": "More Delicious Food"
  }],
  "count": 2,
  "pagination": {
    "previous": null,
    "next":     null,
    "current":  1,
    "per_page": 10,
    "count":    2,
    "pages":    1
  }
}
```

with the `Cache-Control` header set whilst hitting `GET http://localhost:3000/1/foods/1` would return:

```json
{
  "response": {
    "id":    1,
    "name": "Delicious Food"
  }
}
```

with the `Etag` header set.

#### JSONP

If you want to enable JSONP support, it's as simple as calling `jsonp` in your class method:

```ruby
class MyController < RocketPants::Base
  jsonp
end
```

By default this will use the `callback` parameter, e.g. `GET /1/my?callback=console.log`.
To change this parameter, specify the `parameter` option like so:

```ruby
class MyController < RocketPants::Base
  jsonp :parameter => :jsonp
end
```

Finally, to disable it in a subclass, simple call `jsonp` in the child and pass `:enable => false` as an option.

#### Header Metadata

When `RocketPants.header_metadata` or `config.rocket_pants.header_metadata` are set to true, RocketPants can automatically
expose metadata via `X-Api-` headers. Likewise, for paginated responses, if you implement `page_url(page_number)` in your controller
with header metadata enabled, RocketPants will automatically add HTTP Link Headers for the next, prev, first and last to your
response.

Likewise, you can manually add link headers using the `link(rel, href, attributes = {})` method like so:

```ruby
def index
  # Not an actual rel, just an example...
  link :profile, user_profile_path(current_user)
  expose current_user
end
```

For batch adding links, you can use the `links` method:

```ruby
def index
  # Probably not the best example...
  links :next => random_wallpaper_path, :prev => random_wallpaper_path
  expose Wallpaper.random
end
```

### Example Client Code

Using the example above, we could then use the following to write a client:

```ruby
class FoodsClient < RocketPants::Client

  version  1
  base_uri 'http://localhost:3000'

  class Food < APISmith::Smash
    property :id
    property :name
  end

  def foods
    get 'foods', :transformer => Food
  end

  def food(id)
    get "foods/#{id}", :transformer => Food
  end

end
```

## General Structure

RocketPants builds upon the mixin-based approach to ActionController-based rails applications that Rails 3 made possible. Instead of including everything like Rails does in `ActionController::Base`, RocketPants only includes the bare minimum to make apis. In the near future, it may be modified to work with `ActionController::Base` for the purposes of better compatibility with other gems.

Out of the box, we use the following ActionController components:

* `ActionController::HideActions` - Lets you hide methods from actions.
* `ActionController::UrlFor` - `url_for` helpers / tweaks by Rails to make integration with routes work better.
* `ActionController::Redirecting` - Allows you to use `redirect_to`.
* `ActionController::ConditionalGet` - Adds support for Rails caching controls, e.g. `fresh_when` and `expires_in`.
* `ActionController::RackDelegation` - Lets you reset the session and set the response body.
* `ActionController::RecordIdentifier` - Gives `dom_class` and `dom_id` methods, used for polymorphic routing.
* `ActionController::HttpAuthentication` Mixins - Gives Token, Digest and Basic authentication.
* `AbstractController::Callbacks` - Adds support for callbacks / filters.
* `ActionController::Rescue` - Lets you use `rescue_from`.

And added our own:

* `RocketPants::UrlFor` - Automatically includes the current version when generating URLs from the controller.
* `RocketPants::Respondable` - The core of RocketPants, the code that handles converting objects to the different container types.
* `RocketPants::Versioning` - Allows versioning requirements on the controller to ensure it is only callable with a specific api version.
* `RocketPants::Instrumentation` - Adds Instrumentation notifications making it easy to use and hook into with Rails.
* `RocketPants::Caching` - Implements time-based caching for index actions and etag-based efficient validation for singular resources.
* `RocketPants::ErrorHandling` - Short hand to create errors as well as simplifications to catch and render a standardised error representation.
* `RocketPants::Rescuable` - Allows you to hook in to rescuing exceptions and to make it easy to [post notifications to tools such as Airbrake](#tracking-errors-w-airbrake-honeybadger-or-bugsnag).
* `RocketPants::StrongParameters` - Adds support for strong parameters.

To use RocketPants, instead of inheriting from `ActionController::Base`, just inherit from `RocketPants::Base`.

Likewise, in Rails applications RocketPants also adds `RocketPants::CacheMiddleware` before the controller endpoints to implement ["Efficient Validation"](http://rtomayko.github.com/rack-cache/faq).

## Installing RocketPants

Installing RocketPants is a simple matter of adding:

    gem 'rocket_pants', '~> 1.0'

To your `Gemfile` and running `bundle install`. Next, instead of inheriting from `ActionController::Base`, simply inherit from `RocketPants::Base`. For example, if you're working with an API-only application, instead of having this at the top of `application_controller.rb`:

    class ApplicationController < ActionController::Base

you would do this:

    class ApplicationController < RocketPants::Base

Your other controllers would inherit from `ApplicationController` as usual. For example:

    class UsersController < ApplicationController

Otherwise, you can generate a new `api_controller.rb` base controller which inherits from `RocketPants::Base`, and place all your logic there. For example:

In `application_controller.rb`:

    class ApplicationController < ActionController::Base

In `api_controller.rb`:

```
class ApiController < RocketPants::Base

# logic goes here
```

In your other controllers, such as `users_controller.rb`:

    class UsersController < ApiController


## Configuration

Setting up RocketPants in your rails application is pretty simple and requires a minimal amount of effort. Inside your environment configuration, RocketPants offers the following options to control how it's configured (and their expanded alternatives):

- `config.rocket_pants.use_caching` - Defaulting to true for production environments and false elsewhere, defines whether RocketPants caching setup as described below is used.
- `config.rocket_pants.cache` - A `Moneta::Store` / Moneta adapter instance (depending on the version of Moneta in use)used as the RocketPants cache, defaulting to a memory-based. Change for proper caching. (See [here](https://github.com/minad/moneta) for more information on Moneta.)
- `config.rocket_pants.header_metadata` - Defaults to false, if true enables header metadata in the application.
- `config.rocket_pants.pass_through_errors` - Defaults true in development and test, false otherwise. If true, will pass through errors up the stack otherwise will swallow them and return a system error via JSON for any unhandled exceptions.

## Version Controllers / Routes

The current preferred way of dealing with version APIs in RocketPants is to do it using routes in the form of `/:version/:endpoint` - e.g. `GET /1/users/324`. RocketPants has support in the router and controller level for enforcing and controlling this. In the controller, it's a matter of specifying the required API versions:

```ruby
class UsersController < RocketPants::Base
  version 1 # A single version
  # or...
  version 2..3 # 2-3 support this controller
end
```

And in the case of multiple versions, I strongly encourage namespaces the controllers inside modules. If the version param (as specified) by the URL does not match, then the specified controller will return an `:invalid_version` error as shown below.

Next, in your `config/routes.rb` file, you can also declare versions using the following syntax and it will automatically set up the routes for you:

```ruby
api :version => 1 do
  get 'x', :to => 'test#item'
end
```

Which will route `GET /1/x` to `TestController#item`.

Likewise, you can specify a route for multiple versions by:

```ruby
api :versions => 1..3 do
  get 'x', :to => 'test#item'
end
```

### How do I layout file system versions versions?

Using users an an example, for a namespaced / modularised version controller the file system location would be
`app/controllers/api/v1/users_controller.rb` - Rails uses it's own inflection to look for `Api::V1::UsersController` in that file.
In here, you'd write your control roughly like:

```ruby
class Api::V1::UsersController < RocketPants::Base
  version 1

  def index
    expose User.all # Not what we'd actually do, of course.
  end

end
```

Note that I'd personally also introduce `Api::V1::BaseController`, and inherit from that - that way any shared logic (e.g. authentication) can be put in there.

Finally, in the routes - the easiest way would be in the api declaration:

```ruby
api versions: 1, module: "api/v1" do
  resources :users, only: [:index]
end
```

Which will set up `/1/users` to hit the index action of `Api::V1::UsersController` - the `module` parameter comes from the rails built in routing configuration: http://api.rubyonrails.org/classes/ActionDispatch/Routing/Mapper/Scoping.html#method-i-scope

## Working with data

When using RocketPants, you write your controllers the same as how you would with normal ActionController, the only thing that changes is how you handle data. `head` and `redirect_to` still work exactly the same as in Rails, but instead of using `respond_with` and `render` you instead use RocketPant's `exposes` methods (and it's kind). Namely:

- `expose` / `exposes` - The core of all type conversion, will check the type of data and automatically convert it to the correct type (for either a singular, collection or paginated resource).
- `paginated` - Render an object as a paginated collection of data.
- `collection` - Renders a collection of objects - e.g. an array of users.
- `resource` - Renders a single object.

Along side the above that wrap data, it also provides:

- `responds` - Renders JSON, normalizing the object first (unwrapped).
- `render_json` - Renders an object as JSON.

### Singular Resources

Singular resources will be converted to JSON via `serializable_hash`, passing through any objects
and then wrapped in an object as the `response` key:

```json
{
  "response": {
    "your": "serialized-object"
  }
}
```

### Collections

Similar to singular resources, but also include extra data about the count of items.

```json
{
  "response": [{
    "name": "object-one"
  }, {
    "name": "object-two"
  }],
  "count": 2
}
```

### Paginated Collections

The final type, similar to collection objects but it includes details about the paginated data:

```json
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
    "count":    23,
    "pages":    5
  }
}
```

## Registering / Dealing with Errors

One of the built in features of RocketPants is the ability to handle rescuing / controlling exceptions and more importantly to handle mapping exceptions to names, messages and error codes.

This comes in useful when you wish to automatically convert exceptions such as `ActiveRecord::RecordNotFound` (Note: This case is handled already) to a structured bit of data in the response. Namely, it makes it trivial to generate objects that follow the JSON structure of:

```json
{
  "error":             "standard_error_name",
  "error_description": "A translated error message describing what happened."
}
```

It also adds a facilities to make it easy to add extra information to the response.

RocketPants will also attempt to convert all errors in the controller, defaulting to `"system"` as the exception name and message as the error description. We also provide a registry to allow throwing exception from their symbolic name like so:

```ruby
error! :not_found
```

In the controller.

Out of the box, the following exceptions come pre-registered and setup. For each of them, you can either use the error form (`error! :error_key`) or you can raise an instance of the exception class like normal.

Note that inside your application, you can also use `rake rocket_pants:errors` to view
a list of *all* registered errors, including custom ones.

<table>
  <tr>
    <th>Error Key</th>
    <th>Exception Class</th>
    <th>HTTP Status</th>
    <th>Description</th>
  </tr>
  <tr>
    <td><code>:throttled</code></td>
    <td><code>RocketPants::Throttled</code></td>
    <td><code>503 Unavailable</code></td>
    <td>The user has hit an api throttled error.</td>
  </tr>
  <tr>
    <td><code>:unauthenticated</code></td>
    <td><code>RocketPants::Unauthenticated</code></td>
    <td><code>401 Unauthorized</code></td>
    <td>The user doesn't have valid authentication details.</td>
  </tr>
  <tr>
    <td><code>:invalid_version</code></td>
    <td><code>RocketPants::Invalidversion</code></td>
    <td><code>404 Not Found</code></td>
    <td>An invalid API version was specified.</td>
  </tr>
  <tr>
    <td><code>:not_implemented</code></td>
    <td><code>RocketPants::NotImplemented</code></td>
    <td><code>503 Unavailable</code></td>
    <td>The specified endpoint is not yet implemented.</td>
  </tr>
  <tr>
    <td><code>:not_found</code></td>
    <td><code>RocketPants::NotFound</code></td>
    <td><code>404 Not Found</code></td>
    <td>The given resource could not be found.</td>
  </tr>
  <tr>
    <td><code>:invalid_resource</code>*</td>
    <td><code>RocketPants::InvalidResource</code>*</td>
    <td><code>422 Unprocessable Entity</code></td>
    <td>The given resource was invalid.</td>
  </tr>
  <tr>
    <td><code>:bad_request</code></td>
    <td><code>RocketPants::BadRequest</code></td>
    <td><code>400 Bad Request</code></td>
    <td>The given request was not as expected.</td>
  </tr>
  <tr>
    <td><code>:conflict</code></td>
    <td><code>RocketPants::Conflict</code></td>
    <td><code>409 Conflict</code></td>
    <td>The resource was a conflict with the existing version.</td>
  </tr>
  <tr>
    <td><code>:forbidden</code></td>
    <td><code>RocketPants::Forbidden</code></td>
    <td><code>403 Forbidden</code></td>
    <td>The requested action was forbidden.</td>
  </tr>
</table>

Note that error also excepts a Hash of contextual options, many which will be passed through to the Rails I18N subsystem. E.g:

```ruby
error! :throttled, :max_per_hour => 100
```

Will look up the translation `rocket_pants.errors.throttled` in your I18N files, and call them with `:max_per_hour` as an argument.

Finally, You can use this to also pass custom values to include in the response, e.g:

```ruby
error! :throttled, :metadata => {:code => 123}
```

Will return something similar to:

```json
{
  "error":             "throttled",
  "error_description": "The example error message goes here",
  "code":              123
}
```

\* Note that `:invalid_resource` (`RocketPants::InvalidResource`), although registered as a default RocketPants error, does not behave like other default registered errors. When using it, you **must** include an ActiveModel errors object, e.g.:

```ruby
error!(:invalid_resource, post.errors)
# or
render_error RocketPants::InvalidResource.new(post.errors)
```

If you don't do that, you may get an `ArgumentError`, because of the way Rocket Pants handles instantiation of a `RocketPants::InvalidResource`.

### Built in ActiveRecord Errors

Out of the box, Rocket Pants will automatically map the following to built in errors and rescue them
as appropriate.

- `ActiveRecord::RecordNotFound` into `RocketPants::NotFound`
- `ActiveRecord::RecordNotUnique` into `RocketPants::Conflict`
- `ActiveRecord::RecordNotSaved` into `RocketPants::InvalidResource (with no validation messages).`
- `ActiveRecord::RecordInvalid` into `RocketPants::InvalidResource (with messages in the "messages" key of the JSON).`

**Please Note:** The default RecordInvalid mapper can potentially leak information about your structure - If there is data
in the default error messages you don't wish to expose, we suggest implementing it on a per-action basis (using normal
rescues / `.save` instead of `.save!`) OR remapping the handler for `ActiveRecord::RecordInvalid`.

For Invalid Resource messages, the response looks roughly akin to:

```json
{
  "error": "invalid_resource",
  "error_description": "The current resource was deemed invalid.",
  "messages": {
    "name":        ["can't be blank"],
    "child_number":["can't be blank", "is not a number"],
    "latin_name":  ["is too short (minimum is 5 characters)", "is invalid"]
  }
}
```

### A Note on Mongoid

We currently don't support mongoid / other ORMs in RocketPants, but you can map errors directly like so:

```ruby
ApiController < RocketPants::Base
  map_error! Mongoid::Errors::Validations do |exception|
    RocketPants::InvalidResource.new exception.record.errors
  end
end
```

Thanks to @tiredenzo on #47 for this information. If you'd be interested in making
a `rocket_pants-mongoid` gem mapping more errors, please get in touch.

### Strong Parameters

One of the newer features of Rocket Pants, if you have the Strong Parameters plugin on Rails 3
or are using Rails 4, is that we'll automatically rescue strong parameters errors and render them
as `bad_request` API errors to the requesting users.

### Tracking errors w/ Airbrake, Honeybadger or Bugsnag

Since Rocket Pants automatically rescues server errors, you'll additionally need to configure tracking them if you want to be warned when they happen.

Rocket Pants comes with built in support for [Airbrake](https://airbrake.io/), [Honeybadger](https://www.honeybadger.io/) and [Bugsnag](https://bugsnag.com/). Depending on your prefered tracking solution, in your base controller add this:

```ruby
class ApplicationController < RocketPants::Base
  # Airbrake
  use_named_exception_notifier :airbrake
  # or Honeybadger
  use_named_exception_notifier :honeybadger
  # or Bugsnag
  use_named_exception_notifier :bugsnag
end
```

If you're using some other service, you can add a custom notifier:

```ruby
class ApplicationController < RocketPants::Base
  self.exception_notifier_callback = lambda do |controller, exception, request|
    # track errors
  end
end
```

## Implementing Efficient Validation

One of the core design principles built into RocketPants is simple support for "Efficient Validation" as described in the [Rack::Cache FAQ](http://rtomayko.github.com/rack-cache/faq) - Namely, it adds simple support for object-level caching using etags with fast verification thanks to the `RocketPants::CacheMiddleware` cache middleware.

To do this, it uses `RocketPants.cache`, by default any Moneta-based store, to keep a mapping of object -> current cache key. RocketPants will then generate the etag when caching is enabled in the controller for singular-responses, generating an etag that can be quickly validated.

For example, you'd add the following to your model:

```ruby
class User < ActiveRecord::Base
  include RocketPants::Cacheable
end
```

And then in your controller, you'd have something like:

```ruby
class UsersController < RocketPants::Base

  version 1

  # Time based, e.g. collections, will be cached for 5 minutes - whilst singular
  # items e.g. show will use etag-based caching:
  caches :show, :index, :cache_for => 5.minutes

  def index
    expose User.all
  end

  def show
    expose User.find(params[:id])
  end

end
```

When the user hits the index endpoint, it will generate an expiry-based caching header that caches the result for up to 5 minutes. When the user instead hits the show endpoint, it will generate a special etag that contains and object identifier portion and an object cache key. Inside `RocketPants.cache`, we store the mapping and then inside `RocketPants::CacheMiddleware`, we simply check if the given cache key matches the specified object identifier. If it does, we return a not modified response otherwise we pass it through to controller - giving the advantage of efficient caching without having to hit the full database on every request.

## Using with RSpec

When testing controllers written using RocketPants, your normal rails approach should work.
The only difference one needs to take into the account is the need to specify the `:version`
parameter on any http requests, e.g:

```ruby
# get
get :index, :version => 1

# post
post :index, :version => 1, :payload => { :foo => 'bar' ... }
```

Otherwise it will raise an exception.

To set the version to be used for all tests in a given set of specs you can use the `default_version` tag. It will set the version for all tests in that block and not require `:version` to be set individually:

```ruby
describe YourAwesomeController do
  default_version 1
end
```

RocketPants includes a set of helpers to make testing controllers built on `RocketPants::Base` simpler.

* `be_singular_resource` - Checks the response is a single resource - e.g. `response.should be_singular_resource`.
* `be_collection_resource` - Checks the response is collection of resources - e.g. `response.should be_collection_resource`.
* `be_paginated_resource` - Checks the response is paginated - e.g. `response.should be_paginated_resource`.
* `be_api_error(type = any)` - Checks it returned an error for the specified exception (or check the response is an error without any argument) - e.g. `response.should be_api_error RocketPants::NotFound`.
* `have_exposed(data, options = {})` - Given an object and conversion options, lets you check the output exposed the same object. e.g: `response.should have_exposed user`

Likewise, it adds the following helper methods:

- `parsed_body` - A parsed-JSON representation of the response.
- `decoded_body` - A `Hashie::Mash` of the response body.

To set up the integration, in your `spec/spec_helper.rb` add:

```ruby
config.include RocketPants::TestHelper,    :type => :controller
config.include RocketPants::RSpecMatchers, :type => :controller
```

Inside the `RSpec.configure do |config|` block.

## Contributors

- [Darcy Laycock](https://github.com/Sutto) - Main developer, current maintainer.
- [Steve Webb](https://github.com/swebb) - Helped with original work at [The Frontier Group](https://github.com/thefrontiergroup), inc. original design.
- [Fred Wu](https://github.com/fredwu) - README fixes, other contributions / fixes.
- [Levi Buzolic](https://github.com/levibuzolic) - README fixes.
- [Samuel Cochran](https://github.com/sj26) - Misc. work on RocketPants / tweaks.
- [tiredenzo](https://github.com/tiredenzo) - mongoid error information.
- [Fabio Napoleoni](https://github.com/fabn) - Version prefix support.
- [Justin Jones](https://github.com/nagash) - Bug fixes.
- [Eran Kampf](https://github.com/ekampf) - Support for `:bad_request` errors.
- [Matthew Nielsen](https://github.com/xunker) - README fixes.
- [Pavel Kotlyar](https://github.com/paxer) - Typo fixes.
- [John Rees](https://github.com/johnrees) - README fixes.
- [Keith Pitt](https://github.com/keithpitt) - Bug fixes.
- [Antoine Lagadec](https://github.com/oakho) - Bug fixes.
- [Moncef Belyamani](https://github.com/monfresh) - README clarification.
- [Jörg Schiller](https://github.com/joergschiller) - Strong Parameter support, `process` fixes.
- [Aron Hegyi](https://github.com/ahegyi) - Doc tweaks for `:invalid_resource`.
- [Manuel Meurer](https://github.com/manuelmeurer) for Doc tweaks.
- [Travis Pew](https://github.com/travisp) for initial RSpec v3 support.
- [Brandt Lareau](https://github.com/newdark) for RSpec v3 fixes.
- [David Pedersen](https://github.com/davidpdrsn) for Rails 4.2 fixes.
- [Damir Svrtan](https://github.com/DamirSvrtan) for Travis CI fixes.
- [Michael Chrisco](https://github.com/michaelachrisco) for spelling fixes.
- [Kevin Jalbert](https://github.com/kevinjalbert) for spelling fixes.
- [Damir Svrtan](https://github.com/DamirSvrtan) for support for bugsnag, docs and tests.

If you're not on this list and thing you should be, let @Sutto know.

## Contributing

We encourage all community contributions. Keeping this in mind, please follow these general guidelines when contributing:

* Fork the project
* Create a topic branch for what you’re working on (git checkout -b awesome_feature)
* Commit away, push that up (git push your\_remote awesome\_feature)
* Create a new GitHub Issue with the commit, asking for review. Alternatively, send a pull request with details of what you added.
* Once it’s accepted, if you want access to the core repository feel free to ask! Otherwise, you can continue to hack away in your own fork.

Other than that, our guidelines very closely match the GemCutter guidelines [here](https://github.com/rubygems/rubygems.org/wiki/Contribution-Guidelines).

(Thanks to [GemCutter](http://wiki.github.com/qrush/gemcutter/) for the contribution guide)

## License

RocketPants is released under the MIT License (see the [license file](https://github.com/Sutto/rocket_pants/blob/master/LICENSE)) and is copyright Filter Squad and Darcy Laycock, 2013.
