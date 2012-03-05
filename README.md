# Rocket Pants!

First thing's first, you're probably asking yourself - "Why the ridiculous name?". It's simple, really - Rocket Pants is memorable, and sounds completely bad ass. Everything a library needs.

At it's core, Rails is a set of tools (built around existing toolsets such as ActionPack) to make it easier to build well-designed API's in Ruby and, more importantly, along side Rails. You can think of it like [Grape](https://github.com/intridea/grape), a fantastic library which RocketPants was original inspired by but with deeper Rails and ActionPack integration.

## Key Features

Why use Rocket Pants over alternatives like Grape or normal Rails? The reasons we built it come down to a couple of
simple things:

1. **It's opinionated** (like Grape) - In this case, we dictate a certain JSON structure we've found nice to work with (after having worked with and investigated a large number of other apis), it makes it simple to add metadata along side requests and the like.
2. **Simple and Often Automatic Response Metadata** - Rocket Pants automatically takes care of sending metadata about paginated responses and arrays where possible. This means as a user, you only need to worry about writing `expose object\_or\_presenter` in your controller and Rocket Pants will do it's best to send as much information back to the user.
3. **Extended Error Support** - Rocket Pants has a build in framework to manage errors it knows how to handle (in the forms of mapping exceptions to a well defined JSON structure) as well as tools to make it simple to hook up to Airbrake and do things such as including an error identifier in the response.
4. **It's build on ActionPack** - One of the key differentiators to Graphe is that Rocket Pants embraces ActionPack and uses the modular components included from Rails 3.0 onwards to provide things you're familiar with already such as filters.
5. **Semi-efficient Caching Support** - Thanks to a combination of Rails middleware and collection vs. resource distinctions, Rocket Pants makes it relatively easy to implement "Efficient Validation" (See 'http://rtomayko.github.com/rack-cache/faq' [here](http://rtomayko.github.com/rack-cache/faq)). As a developer, this means you get even more benefits of http caching where possible, without the need to generate full requests when
etags are present.
6. **Simple Compact Response** - Want to have your index and search actions return a cut down version of the object whilst the show action returns the full thing? Rocket Pants makes it easy by defaulting to passing in a ` -compact` option when it calls `to_json`. 

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

## Working with data

TODO: explain how exposing data works.

## Registering / Dealing with Errors

TODO: Explain how to register and invoke errors.

## Implementing Efficient Validation

TODO: Describe how to implement efficient validation.

## An Example Controller / App

TODO: Link to the transperth client here.

## Using with Rspec

RocketPants includes a set of helpers to make testing controllers built on `RocketPants::Base` simpler. 

* `be_singular_resource` - 
* `be_collection_resource` - 
* `be_paginated_response` - 
* `be_api_error(type = any)` -
* `have_exposed(data)` - 

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