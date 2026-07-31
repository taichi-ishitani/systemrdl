[![Gem Version](https://badge.fury.io/rb/systemrdl.svg)](https://badge.fury.io/rb/systemrdl)
[![Regression](https://github.com/taichi-ishitani/systemrdl/actions/workflows/regression.yml/badge.svg?branch=master)](https://github.com/taichi-ishitani/systemrdl/actions/workflows/regression.yml)

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/A0A231E3I)

# SystemRDL

A SystemRDL 2.0 front-end for Ruby.
It parses SystemRDL source, elaborates the described register model, and exposes it as plain Ruby objects so that back-end tools can generate RTL, documentation, software headers, and so on.

SystemRDL is a register description language standardized by [Accellera](https://www.accellera.org/activities/working-groups/systemrdl).
This gem targets the [SystemRDL 2.0 specification](https://www.accellera.org/images/downloads/standards/systemrdl/SystemRDL_2.0_Jan2018.pdf).

## Installation

Install the gem and add it to the application's Gemfile by executing:

```bash
bundle add systemrdl
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install systemrdl
```

## Usage

### Compiling SystemRDL

Use the methods below to compile SystemRDL into an elaborated model.
Each method returns a list of the top-level address maps.

* Compile SystemRDL read from the given file path(s)
    * `SystemRDL.compile`
* Compile SystemRDL read from the given input stream(s)
    * `SystemRDL.compile_streams`
* Compile the given SystemRDL source string
    * `SystemRDL.compile_source`

`SystemRDL.compile` and `SystemRDL.compile_streams` accept multiple inputs.
The inputs are compiled in the given order and share their component definitions, so a component defined in an earlier input can be instantiated in a later one.
Note that this sharing is one-directional; an earlier input cannot refer to a component defined in a later one.

```ruby
require 'systemrdl'

# Compile files
address_maps = SystemRDL.compile('gpio.rdl', 'pwm.rdl')

# Compile a source string
address_maps = SystemRDL.compile_source(<<~'RDL')
  addrmap my_map {
    reg {
      field { sw = rw; hw = r; reset = 0x0; } value[32];
    } data;
  };
RDL
```

### Accessing the model

An elaborated model is a tree of address maps, registers, and fields.
Each element carries the properties assigned to it in the source.

```ruby
require 'systemrdl'

address_map = SystemRDL.compile_source(<<~'RDL').first
  addrmap gpio {
    name = "GPIO";
    desc = "Simple general purpose I/O controller";

    default sw = rw;
    default hw = r;

    reg {
      name = "Port Direction";
      field { desc = "0: input, 1: output"; reset = 0x0; } dir[32];
    } direction;

    reg {
      name = "Input Data";
      field { sw = r; hw = w; } value[32];
    } data_in;
  };
RDL

# GPIO: Simple general purpose I/O controller
puts "#{address_map.display_name}: #{address_map.desc}"

address_map.regs.each do |reg|
  # direction @ 0x0
  # data_in @ 0x4
  puts "#{reg.name} @ 0x#{reg.address.to_s(16)}"

  reg.fields.each do |field|
    # dir [31:0] sw=rw hw=r
    # value [31:0] sw=r hw=w
    puts "  #{field.name} [#{field.msb}:#{field.lsb}] sw=#{field.sw} hw=#{field.hw}"
  end
end
```

## Scope

This gem currently supports only the basic syntax needed to describe register maps that consist of address maps, registers, and fields.
More advanced constructs of the SystemRDL language are not supported yet.

## Design notes

The design decisions behind this implementation, along with their rationale, are documented under the [`notes`](notes) directory.
These notes focus on parts of the SystemRDL specification that are open to interpretation or left unspecified, and explain how this implementation resolves them.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/taichi-ishitani/systemrdl.

* [Issue Tracker](https://github.com/taichi-ishitani/systemrdl/issues)
* [Pull Request](https://github.com/taichi-ishitani/systemrdl/pulls)
* [Discussion](https://github.com/taichi-ishitani/systemrdl/discussions)

## Copyright & License

Copyright &copy; 2026 Taichi Ishitani.
SystemRDL is licensed under the terms of the [MIT License](https://opensource.org/licenses/MIT), see [LICENSE.txt](LICENSE.txt) for further details.
