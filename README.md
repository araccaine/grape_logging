# grape_logging

This is a fork of [aserafin/grape_logging](https://github.com/aserafin/grape_logging) to fix some things not addressed upstream:

- Missing route_param parameters from grape
- Some documentation

## Installation

Add this line to your application's Gemfile:

    gem 'grape_logging', github: 'araccaine/grape_logging', tag: '1.8.4-1'

And then execute:

    $ bundle install

## Basic Usage

In your api file (somewhere on the top), insert grape logging middleware before grape error middleware. This is important due to the behaviour of `lib/grape/middleware/error.rb`, which manipulates the status of the response when there is an error. 

```ruby
require 'grape_logging'
logger.formatter = GrapeLogging::Formatters::Default.new
insert_before Grape::Middleware::Error, GrapeLogging::Middleware::RequestLogger, { logger: logger }
```

**ProTip:** If your logger doesn't support setting formatter you can remove this line - it's optional

## Features

### Log Format

There are formatters provided for you, or you can provide your own.

#### `GrapeLogging::Formatters::Default`

    [2015-04-16 12:52:12 +0200] INFO -- 200 -- total=2.06 db=0.36 -- PATCH /api/endpoint params={"some_param"=>{"value_1"=>"123", "value_2"=>"456"}}

#### `GrapeLogging::Formatters::Json`

```json
{
  "date": "2015-04-16 12:52:12+0200",
  "severity": "INFO",
  "data": {
    "status": 200,
    "time": {
      "total": 2.06,
      "db": 0.36,
      "view": 1.70
    },
    "method": "PATCH",
    "path": "/api/endpoint",
    "params": {
      "value_1": "123",
      "value_2": "456"
    },
    "host": "localhost"
  }
}
```

#### `GrapeLogging::Formatters::Lograge`

    severity="INFO", duration=2.06, db=0.36, view=1.70, datetime="2015-04-16 12:52:12+0200", status=200, method="PATCH", path="/api/endpoint", params={}, host="localhost"

#### `GrapeLogging::Formatters::Logstash`

```json
{
  "@timestamp": "2015-04-16 12:52:12+0200",
  "severity": "INFO",
  "status": 200,
  "time": {
    "total": 2.06,
    "db": 0.36,
    "view": 1.70
  },
  "method": "PATCH",
  "path": "/api/endpoint",
  "params": {
    "value_1": "123",
    "value_2": "456"
  },
  "host": "localhost"
}
```

#### `GrapeLogging::Formatters::Rails`

Rails will print the "Started..." line:

    Started GET "/api/endpoint" for ::1 at 2015-04-16 12:52:12 +0200
      User Load (0.7ms)  SELECT "users".* FROM "users" WHERE  "users"."id" = $1
      ...

The `Rails` formatter adds the last line of the request, like a standard Rails request:

    Completed 200 OK in 349ms (Views: 250.1ms | DB: 98.63ms)

#### Custom

You can provide your own class that implements the `call` method returning a `String`:

```ruby
def call(severity, datetime, _, data)
   ...
end
```

You can change the formatter like so
```ruby
class MyAPI < Grape::API
  use GrapeLogging::Middleware::RequestLogger, logger: logger, formatter: MyFormatter.new
end
```

If you prefer some other format I strongly encourage you to do pull request with new formatter class ;)

### Customising What Is Logged

You can include logging of other parts of the request / response cycle by including subclasses of `GrapeLogging::Loggers::Base`
```ruby
class MyAPI < Grape::API
  use GrapeLogging::Middleware::RequestLogger,
    logger: logger,
    include: [ GrapeLogging::Loggers::Response.new,
               GrapeLogging::Loggers::FilterParameters.new,
               GrapeLogging::Loggers::ClientEnv.new,
               GrapeLogging::Loggers::RequestHeaders.new ]
end
```

#### FilterParameters
The `FilterParameters` logger will filter out sensitive parameters from your logs. If mounted inside rails, will use the `Rails.application.config.filter_parameters` by default. Otherwise, you must specify a list of keys to filter out.

#### ClientEnv
The `ClientEnv` logger will add `ip` and user agent `ua` in your log.

#### RequestHeaders
The `RequestHeaders` logger will add `request headers` in your log.

### Logging to file and STDOUT

You can log to file and STDOUT at the same time, you just need to assign new logger
```ruby
log_file = File.open('path/to/your/logfile.log', 'a')
log_file.sync = true
logger Logger.new GrapeLogging::MultiIO.new(STDOUT, log_file)
```

### Set the log level

You can control the level used to log. The default is `info`.

```ruby
class MyAPI < Grape::API
  use GrapeLogging::Middleware::RequestLogger,
    logger: logger,
    log_level: 'debug'
end
```

### Logging via Rails instrumentation

You can choose to not pass the logger to ```grape_logging``` but instead send logs to Rails instrumentation in order to let Rails and its configured Logger do the log job, for example.
First, config ```grape_logging```, like that:
```ruby
class MyAPI < Grape::API
  use GrapeLogging::Middleware::RequestLogger,
    instrumentation_key: 'grape_key',
    include: [ GrapeLogging::Loggers::Response.new,
               GrapeLogging::Loggers::FilterParameters.new ]
end
```

and then add an initializer in your Rails project:
```ruby
# config/initializers/instrumentation.rb

# Subscribe to grape request and log with Rails.logger
ActiveSupport::Notifications.subscribe('grape_key') do |name, starts, ends, notification_id, payload|
  Rails.logger.info payload
end
```

The idea come from here: https://gist.github.com/teamon/e8ae16ffb0cb447e5b49

### Logging via Rails instrumentation and Rails formatter

You may also use the Rails logger formatter with tagged logging on each line with this workaround:

```ruby
# config/initializers/instrumentation.rb
ActiveSupport::Notifications.subscribe('grape_key') do |_name, _starts, _ends, _notification_id, payload|
  # Remove all leading and trailing white space and split the message on each new line
  messages = GrapeLogging::Formatters::Rails.new.call('', _starts, nil, payload).strip.split(/\n/)
  
  # Add a single newline character at the last message for better log readability if needed 
  messages[-1] = messages[-1] + "\n"

  # Log each message line
  messages.each do |message|
    Rails.logger.tagged('API').info message
  end
end

# with this in your API class, e.g. app/api/api.rb
module Api
  class Api < Grape::API
    insert_before Grape::Middleware::Error, GrapeLogging::Middleware::RequestLogger,
                  instrumentation_key: 'grape_key',
                  include: [
                    GrapeLogging::Loggers::Response.new,
                    GrapeLogging::Loggers::FilterParameters.new
                  ]
  end
end
```

This results in a log like this (note line 3 and 4):

```
I, [2024-02-20T10:14:23] [<ip>] [<request-id>] Started GET "/123/list/abc?add_param=xyz" for <ip> at 2024-02-20 10:14:23
D, [2024-02-20T10:14:23] [<ip>] [<request-id>]   Do something...
I, [2024-02-20T10:14:24] [<ip>] [<request-id>] [API] Parameters: {"add_param"=>"xyz", "more_id"=>"abc", "id"=>123}
I, [2024-02-20T10:14:24] [<ip>] [<request-id>] [API] Completed 200 OK in 168.25ms (Views: 155.45ms | DB: 12.8ms)

I, [2024-02-20T10:15:00] [<ip>] [<request-id>] Started GET "/some-other-request" for <ip> at 2024-02-20 10:15:00
```

### Logging exceptions

If you want to log exceptions you can do it like this
```ruby
class MyAPI < Grape::API
  rescue_from :all do |e|
    MyAPI.logger.error e
    #do here whatever you originally planned to do :)
  end
end
```
## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
