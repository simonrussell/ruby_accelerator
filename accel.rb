require 'ruby_accelerator'

RubyAccelerator.execute([
  [:block_call, 10, :times, [
    [:call, Kernel, :puts, "blah!"]
  ]]
])
