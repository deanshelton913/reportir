# Reportir

Use Reportir to send your feature spec's screenshots to an s3 bucket as a functional static site. 

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'reportir'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install reportir

## Usage

```ruby
# spec_helper.rb
require 'reportir'
require 'rspec'

RSpec.configure do |config|
  # Include Reportir's methods in your tests
  config.include Reportir, type: :feature

  # Send auto-generated results to your configured s3 bucket
  config.after :each, type: :feature do
    upload_result_to_s3_as_static_site
  end
end
```

Take Screenshots using the helper method anywhere in your spec.
Screenshots will display in the order they were taken.
```ruby
# spec/features/my_feature_spec.rb
describe 'My Feature', :type => :feature do
  it 'does something' do
    ...
    s3_screenshot('whatever-bananas')  # 1-whatever-bananas.png
    ...
    s3_screenshot('whatever-apples')  # 2-whatever-apples.png
    ...
  end
end
```
Just ensure your ENV cars are configured, and run your spec like normal.
```bash
# ~/.bashrc
export ENV['AWS_DEFAULT_BUCKET']=<YOURBUCKETNAME> 
export ENV['AWS_ACCESS_KEY_ID']=<YOURACCESSKEYID> 
export ENV['AWS_SECRET_ACCESS_KEY']=<YOURSECRETACCESSKEY> 
export ENV['AWS_DEFAULT_REGION']=<YOURREGION> 

```
```bash
rspec spec/features
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/reportir. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

