# OmniAuth Promise

This gem provides a way for application to integrate with [Promise](https://promiseauthentication.org).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'omniauth-promise'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install omniauth-promise

## Usage

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :promise, 'example.com'
end
```

Where `example.com` is your `client_id` with Promise.

### With Rails

In `config/initializers/devise.rb` add

```ruby
&hellip;
config.omniauth :github, 'example.com'
&hellip;
```

Where `example.com` is your `client_id` with Promise.

### How to pick a `client_id`?

A `client_id` is what Promise uses to control generation of identities. Each user, will get a unique random identity per `client_id`.

So, you should make the `client_id` the shortest possible domain you control. Eg. if you have site on `www.example.com`, you probably should choose `example.com` to be your `client_id`.

If you host your application on a provider, where you only control a subdomain, you should use that. Eg. `blm.herokuapp.com`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/promise-authentication/omniauth-promise. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/promise-authentication/omniauth-promise/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Omniauth::Promise project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/promise-authentication/omniauth-promise/blob/master/CODE_OF_CONDUCT.md).
