#!/usr/bin/ruby

require 'benchmark'
require "#{File.dirname(__FILE__)}/lib/ruby_accelerator"

MULTIPLE = 1_000_000

Benchmark.bmbm do |benchmark|

  benchmark.report 'inline op' do
    MULTIPLE.times { 1+1 }
  end

  benchmark.report 'inline op x 10' do
    (MULTIPLE / 10).times { 1+1; 1+1; 1+1; 1+1; 1+1; 1+1; 1+1; 1+1; 1+1; 1+1 }
  end

  benchmark.report 'inline op while loop' do
    x = 0
    while x < MULTIPLE
      1 + 1
      x += 1
    end
  end

  benchmark.report 'inline op for loop' do
    for i in 1..MULTIPLE
      1 + 1
    end
  end

  benchmark.report 'send' do
    MULTIPLE.times { 1.send(:+, 1) }
  end

  benchmark.report 'send x 10' do
    (MULTIPLE / 10).times { 1.send(:+, 1); 1.send(:+, 1); 1.send(:+, 1); 1.send(:+, 1); 1.send(:+, 1); 1.send(:+, 1); 1.send(:+, 1); 1.send(:+, 1); 1.send(:+, 1); 1.send(:+, 1); }
  end

  benchmark.report 'addtest1' do
    MULTIPLE.times { RubyAccelerator::addtest1 }
  end

  benchmark.report 'addtest1_loop' do
    RubyAccelerator::addtest1_loop(MULTIPLE)   # loop done inside function
  end

  benchmark.report 'addtest2' do
    MULTIPLE.times { RubyAccelerator::addtest2 }
  end

  benchmark.report 'addtest2 x 10' do
    (MULTIPLE / 10).times { RubyAccelerator::addtest2_loop(10) }
  end

  benchmark.report 'addtest2_loop' do
    RubyAccelerator::addtest2_loop(MULTIPLE)   # loop done inside function
  end

  benchmark.report 'addtest3' do
    RubyAccelerator::addtest3(MULTIPLE)
  end

  benchmark.report 'execute' do
    RubyAccelerator.execute([
      [:block_call, MULTIPLE, :times, [
        [:call, 1, :+, 1]
      ]]
    ])
  end

  linear = RubyAccelerator::Assembler.assemble(
    [
      {
        :TIMES => MULTIPLE,
        :VALUE => 1
      },

      [:block, :block],  
      [:call_0, :r0, :TIMES, :times],
      [:return, :r0],

    :block,
      [:call_1, :void, :VALUE, :+, :VALUE],
      [:return, :void]
    ]
  )

  benchmark.report 'execute_linear' do
    RubyAccelerator.execute_linear(linear)
  end

  linear10 = RubyAccelerator::Assembler.assemble(
    [
      {
        :TIMES => MULTIPLE / 10,
        :VALUE => 1
      },

      [:block, :block],  
      [:call_0, :r0, :TIMES, :times],
      [:return, :r0],

    :block,
      [:call_1, :void, :VALUE, :+, :VALUE],
      [:call_1, :void, :VALUE, :+, :VALUE],
      [:call_1, :void, :VALUE, :+, :VALUE],

      [:call_1, :void, :VALUE, :+, :VALUE],
      [:call_1, :void, :VALUE, :+, :VALUE],
      [:call_1, :void, :VALUE, :+, :VALUE],

      [:call_1, :void, :VALUE, :+, :VALUE],
      [:call_1, :void, :VALUE, :+, :VALUE],
      [:call_1, :void, :VALUE, :+, :VALUE],
      [:call_1, :void, :VALUE, :+, :VALUE],

      [:return, :void]
    ]
  )

  benchmark.report 'execute_linear x 10' do
    RubyAccelerator.execute_linear(linear10)
  end

end
