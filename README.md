# fsecurekey2pass

fsecurekey2pass is a simple script to export [F-Secure KEY](https://www.f-secure.com/en/web/home_global/key) entries into Jason A. Donenfeld's [pass](https://www.passwordstore.org/).

This script aims to migrate any number of credentials from F-Secure's commercial software to the password manager. The intention was to keep it clean from any dependencies.



## Requirements

1. Ruby > 1.8 (currently tested with Ruby 2.4.1)
2. F-Secure KEY export file. (.FSK)

## Usage

```
$ git clone https://github.com/magandrez/fsecurekey2pass.git
$ cd fsecurekey2pass
$ ruby fsecurekey2pass.rb -f ExportedPasswords.fsk
```

## License

Licensed under [GPLv2+](https://www.gnu.org/licenses/gpl-2.0.html).

This software is provided "as is", feel free to open an issue if you deem it necessary.
