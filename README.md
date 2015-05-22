[![Inline docs](http://inch-ci.org/github/paddor/sudoku.svg?branch=master)](http://inch-ci.org/github/paddor/sudoku)

Sudoku
======

My attempt to write a Sudoku solver.

Documentation
-------------

Ensure you have Yardoc installed and run `rake yard`. Open `doc/index.html` with a web browser.

Example
-------

```
$ ./sudoku.rb < examples/easy.txt
Board read:
_ 7 6 _ _ _ 1 _ _
_ _ 4 _ 3 9 _ _ _
_ 2 3 _ _ _ _ 8 _
8 _ _ 2 4 3 _ _ 6
6 3 _ _ 9 _ _ _ 2
4 _ _ 7 6 5 _ _ 1
_ 5 _ _ _ _ 2 6 _
_ _ _ 5 8 _ 3 _ _
_ _ 8 _ _ _ 5 9 _

Solving...
YAY! Solved in 957 steps.
Board with solution:
2 7 6 3 5 8 1 4 9
1 8 4 6 3 9 7 2 5
5 2 3 9 1 4 6 8 7
8 1 5 2 4 3 9 7 6
6 3 1 8 9 7 4 5 2
4 9 2 7 6 5 8 3 1
3 5 9 4 7 1 2 6 8
9 6 7 5 8 2 3 1 4
7 4 8 1 2 6 5 9 3

Solution is valid.
Solution is complete.
```
