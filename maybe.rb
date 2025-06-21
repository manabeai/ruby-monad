require 'dry/monads'
require 'debug'
extend Dry::Monads[ :maybe]

r = Maybe(10).fmap { |x| x + 5 }.fmap { |y| y * 2 }