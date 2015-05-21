#!/usr/bin/env ruby
require 'profile'
require_relative 'sudoku'

Sudoku::Reader.new(<<BOARD).game.solver.solve
3 - - - 5 - - - 2
- - 8 - - - 7 - -
- 4 - - - 2 - 8 -
- - 9 5 - 6 - - -
2 - - - 9 - - - 8
- - - 7 - 4 1 - -
- 5 - 4 - - - 6 -
- - 7 - - - 2 - -
6 - - - 1 - - - 3
BOARD
