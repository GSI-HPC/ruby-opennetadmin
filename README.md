# ruby-opennetadmin

Small and simple Ruby lib for querying opennetadmin via dcm.php
including a dcm.pl replacement

## Example

```ruby
require 'ona'

ona = ONA.new('http://www.example.com/ona/dcm.php')
puts ona.query('get_module_list')
```

If authentication is required:
```ruby
ona = ONA.new('http://www.example.com/ona/dcm.php','username','password')
```

ONA module options are passed via ruby hash:
```ruby
oan.query('my_module', { :key1 => value1, :key2 => value2, ... }
```

## `ona.rb`

`ona.rb` is a basic drop-in replacement for `dcm.pl`

```ruby
ona.rb -l user -u http://www.example.com/ona/dcm.php -r my_module \
       key1=value2 key2=value2 ...
```
