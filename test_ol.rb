require 'lib/ruby_accelerator'
require 'benchmark'

MULTIPLE = 1_000_000


def linear_spec
  [
    0,                  # nop
    1, 10, 11, 1, 13,   # call target_index, method_name_index, argc, *args
    2, 10, 11, 13       # assign target_index, method_name, value
    
    
    # item 10:
    Target,
    :method_name,
    1
  ]
end

class MyClass

  def inline_add
    1 + 1
    1 + 1
    1 + 1

    1 + 1
    1 + 1
    1 + 1

    1 + 1
    1 + 1
    1 + 1
  end

end

RubyAccelerator.test_pass
RubyAccelerator.define_accelerator_method(MyClass, :my_method, [[:call, 1, :+, 1]] * 9)

x = MyClass.new

Benchmark.bmbm do |benchmark|
  
  benchmark.report 'inline' do
    MULTIPLE.times { x.inline_add }
  end

  benchmark.report 'accel' do
    MULTIPLE.times { x.my_method }
  end

end
