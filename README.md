# ruby-opennetadmin

Small and simple Ruby lib for querying opennetadmin via dcm.php including a dcm.pl replacement

## Example

```
require 'ona'

ona = ONA.new('http://www.example.com/ona/dcm.php')
puts ona.query('get_module_list')
```

If authentication is required:
```
ona = ONA.new('http://www.example.com/ona/dcm.php','username','password')
```

ONA module options are passed via ruby hash:
```
oan.query('my_module', { :key1 => value1, :key2 => value2, ... }
```
