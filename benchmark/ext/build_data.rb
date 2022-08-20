#!/usr/bin/env ruby

require 'bundler/setup'
require 'hamlit'
require 'benchmark/ips'
require_relative '../utils/benchmark_ips_extension'

h = { 'user' => { id: 1234, name: 'k0kubun' }, book_id: 5432 }

Benchmark.ips do |x|
  quote = "'"
  x.report("Hamlit.build_data") { Hamlit::AttributeBuilder.build_data(true, quote, h) }
  x.compare!
end
