#!/usr/bin/ruby

require 'mkmf'

extension_name = 'ruby_accelerator'

dir_config(extension_name)
#have_library('stdc++')

create_makefile(extension_name)
