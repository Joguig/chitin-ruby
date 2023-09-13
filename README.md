# Chitin (KY-tin): Process Exoskeleton - Ruby Edition

For details on what Chitin is and why you should use it, please [visit the main Chitin repo](https://git-aws.internal.justin.tv/common/chitin).

## Specifics of the Ruby API

Currently the ruby gem only supports emitting Trace events and injecting Trace headers.

## Configuration

Chitin supports specifying the service name and enabling/disabling individual features with `Chitin.configure`.

```
Chitin.configure do |config|
  config.service_name = "code.justin.tv/common/chitin-ruby/unknown"
  config.track_inbound_http = true
  config.track_outbound_http = true
  config.track_outbound_sql = false
end
```

## Dependencies

`sudo apt-get install bison flex`
