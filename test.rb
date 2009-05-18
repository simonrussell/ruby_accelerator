# Copyright (c) 2009 Simon Russell.  All rights reserved.

require "#{File.dirname(__FILE__)}/lib/ruby_accelerator"
require 'benchmark'

asm = [
  { 
    :a => 'blah', 
    :b => 'blob', 
    :MAX_LENGTH => 10
  },

  [:call_1, :Result, :a, :+, :b],
  [:call_0, :Length, :Result, :length],
  [:call_1, :Test, :Length, :>, :MAX_LENGTH],
  [:jump_true, :Test, :too_long],
  [:return, :Length],
:too_long,
  [:return, :void]
]

asm2 = [
  {
    :START_VALUE => 0,
    :INCREMENT => 1,
    :FINAL_VALUE => 10
  },
  
  [:move, :A, :START_VALUE],
:looper,
  [:call_1, :T, :A, :<, :FINAL_VALUE],
  [:jump_false, :T, :finish],
  #[:call_1, :void, :self, :puts, :A],
  [:call_1, :A, :A, :+, :INCREMENT],
  [:jump, :looper],
:finish,
  [:return, :A]
]

asm3 = [
  {
    :TIMES => 10,
    :VALUE => 1
  },

  [:block, :block],  
  [:call_0, :r0, :TIMES, :times],
  [:return, :r0],

:block,
  [:call_1, :void, :VALUE, :+, :VALUE],
  [:return, :void]
]

def ruby_asm2
  a = 0
  
  while a < 10
    a += 1
  end

  a
end

ops = RubyAccelerator::Assembler.assemble(asm3)

puts ops.inspect

if false
  Benchmark.bmbm do |b|
    b.report 'ruby' do
      10000.times { ruby_asm2 }
    end

    b.report 'accel' do
      10000.times { RubyAccelerator.execute_linear(ops) }
    end
  end
else
  puts RubyAccelerator.execute_linear(ops)
end
