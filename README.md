# Lolcommits Yammer

[![Gem](https://img.shields.io/gem/v/lolcommits-yammer.svg?style=flat)](http://rubygems.org/gems/lolcommits-yammer)
[![Travis](https://travis-ci.org/lolcommits/lolcommits-yammer.svg?branch=master)](https://travis-ci.org/lolcommits/lolcommits-yammer)
[![Depfu](https://img.shields.io/depfu/lolcommits/lolcommits-yammer.svg?style=flat)](https://depfu.com/github/lolcommits/lolcommits-yammer)
[![Maintainability](https://api.codeclimate.com/v1/badges/dc8b0801920bffbecf9f/maintainability)](https://codeclimate.com/github/lolcommits/lolcommits-yammer/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/dc8b0801920bffbecf9f/test_coverage)](https://codeclimate.com/github/lolcommits/lolcommits-yammer/test_coverage)

[lolcommits](https://lolcommits.github.io/) takes a snapshot with your webcam
every time you git commit code, and archives a lolcat style image with it. Git
blame has never been so much fun!

This plugin automatically posts a new message to your Yammer account with the
captured lolcommit image, your commit message and a 'Lolcommits' topic tag.
Something like this:

![example
commit](https://github.com/lolcommits/lolcommits-yammer/raw/master/assets/images/example-commit.png)


## Requirements

* Ruby >= 2.0.0
* A webcam
* [ImageMagick](http://www.imagemagick.org)
* [ffmpeg](https://www.ffmpeg.org) (optional) for animated gif capturing
* A [Yammer](http://yammer.com) account

## Installation

After installing the lolcommits gem, install this plugin with:

    $ gem install lolcommits-yammer

Then configure to enable with:

    $ lolcommits --config -p yammer
    # set enabled to `true`
    # confirm access for this plugin at yammer.com (link opens automatically)

That's it! Your next lolcommit will be posted to Yammer. To disable uninstall
this gem or use:

    $ lolcommits --config -p yammer
    # and set enabled to `false`

To revoke plugin permissions at Yammer, visit 'Edit Settings' -> 'My
Applications' and select 'Revoke Access' for the 'Lolcommits Yammer' app.

## Development

Check out this repo and run `bin/setup`, this will install all dependencies and
generate docs. Use `bundle exec rake` to run all tests and generate a coverage
report.

You can also run `bin/console` for an interactive prompt, allowing you to
experiment with the gem code.

## Tests

MiniTest is used for testing. Run the test suite with:

    $ rake test

## Docs

Generate docs for this gem with:

    $ rake rdoc

## Troubles?

If you think something is broken or missing, please raise a new
[issue](https://github.com/lolcommits/lolcommits-yammer/issues). Take
a moment to check it hasn't been raised in the past (and possibly closed).

## Contributing

Bug [reports](https://github.com/lolcommits/lolcommits-yammer/issues) and [pull
requests](https://github.com/lolcommits/lolcommits-yammer/pulls) are welcome on
GitHub.

When submitting pull requests, remember to add tests covering any new behaviour,
and ensure all tests are passing on [Travis
CI](https://travis-ci.org/lolcommits/lolcommits-yammer). Read the
[contributing
guidelines](https://github.com/lolcommits/lolcommits-yammer/blob/master/CONTRIBUTING.md)
for more details.

This project is intended to be a safe, welcoming space for collaboration, and
contributors are expected to adhere to the [Contributor
Covenant](http://contributor-covenant.org) code of conduct. See
[here](https://github.com/lolcommits/lolcommits-yammer/blob/master/CODE_OF_CONDUCT.md)
for more details.

## License

The gem is available as open source under the terms of
[LGPL-3](https://opensource.org/licenses/LGPL-3.0).

## Links

* [Travis CI](https://travis-ci.org/lolcommits/lolcommits-yammer)
* [Code Climate](https://codeclimate.com/github/lolcommits/lolcommits-yammer)
* [Test Coverage](https://codeclimate.com/github/lolcommits/lolcommits-yammer/coverage)
* [RDoc](http://rdoc.info/projects/lolcommits/lolcommits-yammer)
* [Issues](http://github.com/lolcommits/lolcommits-yammer/issues)
* [Report a bug](http://github.com/lolcommits/lolcommits-yammer/issues/new)
* [Gem](http://rubygems.org/gems/lolcommits-yammer)
* [GitHub](https://github.com/lolcommits/lolcommits-yammer)
