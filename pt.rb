require 'rubygems'
gem 'ParseTree'
require 'parse_tree'
require 'pp'

class MyClass
  def myfunc(x, y, *rest, &block)
    bb = defined?(x)
    z = 2
    self.blah = 4
    x.blob = 5
    Fixnum.blob = 6
    puts "asfsadf", 1, 1.0, :asdf, %q(asfasdf), /asfd/, z, x, y, &block

    puts :asdf => 12, :werwer => 14
  end

  def emptyfunc
  end

  def simplefunc(*args)
    XYZ.call(*args)
  end
end

pp ParseTree.translate(MyClass, :myfunc)
puts
pp ParseTree.translate(MyClass, :emptyfunc)
puts
pp ParseTree.translate(MyClass, :simplefunc)
puts
pp ParseTree.translate(String, :to_s)
