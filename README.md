# BetterIpaddr

[![Gem Version](https://badge.fury.io/rb/better_ipaddr.svg)](https://rubygems.org/gems/better_ipaddr)
[![Build Status](https://travis-ci.org/bjmllr/better_ipaddr.svg)](https://travis-ci.org/bjmllr/better_ipaddr)

The `IPAddr` class that network engineers always wanted.

```ruby
require "better_ipaddr"
addr = IPAddr::V4[some_source] # shortcut for .new, because your test suite
                               #   contains a zillion IP addresses and you're
                               #   tired of typing Socket::AF_INET
addr.host?                     # is it a host address?
addr.network?                  # or a network address?
addr.cidr                      # what is the CIDR representation?
addr.grow(1)                   # what is the next larger enclosing network?
addr + 1                       # what address comes after this one?
addr.size                      # how many host addresses fit in this network?
addr.mask_addr                 # what's the netmask (as an integer)?
addr.prefix_length             # what's the prefix length (as an integer)?
addr == other_addr             # are these the same network?
addr.cover?(other_addr)        # does this network contain that one?
addr.overlap?(other_addr)      # do these networks share any hosts?
addr.each { ... }              # do something with each host in this network
addr.first                     # what's the network address?
addr.last                      # what's the broadcast address?
addr.wildcard                  # what's the wildcard mask for this network?
addr.summarize_with(other)     # can these networks be summarized?
```

Bonus: comes with an IP space finder.

```ruby
require "better_ipaddr/space"
space = BetterIpaddr::Space.new(some_array_of_ipaddrs,
                                space: IPAddr::V4["10.0.0.0/8"])

space.find_by_minimum_prefix_length(26) # => a subnet with at least 64 addresses
space.find_by_minimum_size(256)         # => a /24 or larger
space.gaps                              # => all your free subnets
```

Coming soon: MAC addresses and their various notations.

## Installation

Ruby 2.0 or later is required. There are no other dependencies.

Add this line to your application's Gemfile:

```ruby
gem 'better_ipaddr'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install better_ipaddr

## Usage

There are multiple ways to load this gem.

The quick and dirty way is to `require
"better_ipaddr/core_extension"`, which adds all the additional methods
directly to `IPAddr`. This is "monkey patching", so there may be
unintended consequences. If you use this approach in another library
or framework, be very clear about it with your users.

```ruby
require "better_ipaddr/core_extension"
addr = IPAddr["1.0.0.1"]
class_c = addr << 8 # => IPAddr::V4["1.0.0.0/24"]
IPAddr.new("1.0.0.0/24").summarize_with(IPAddr["1.0.1.0/24"]) # => IPAddr::V4["1.0.0.0/23"]
```

The recommended way is to `require "better_ipaddr"` and use
the `IPAddr` subclasses explicitly.

```ruby
require "better_ipaddr"
addr = IPAddr::V4["1.0.0.1"]
class_c = addr << 8 # => IPAddr::V4["1.0.0.0/24"]
```

Another way is to `require "better_ipaddr/methods"` and mix
`BetterIpaddr::InstanceMethods` into your own class which implements
the rest of the `IPAddr` API, or into individual `IPAddr` objects.

`BetterIpaddr::Space`, a collection class for dealing with sets of network addresses, is also available but not loaded by default.

```ruby
require "better_ipaddr/space"
space = BetterIpaddr::Space.new([IPAddr::V4["10.0.0.0/24"],
                                 IPAddr::V4["10.0.2.0/24"]])
space.gaps # => BetterIpaddr::Space.new([IPAddr::V4["10.0.1.0/24"]])
```

The available methods are described in the API docs.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bjmllr/better_ipaddr. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Copyright and License

Copyright (C) 2016 Ben Miller

The gem is available as free software under the terms of the [GNU General Public License, Version 3](http://www.gnu.org/licenses/gpl-3.0.html).
