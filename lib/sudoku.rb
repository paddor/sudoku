# My attempt to write a Sudoku solver with some heuristics.
#
# @author Patrik Wenger <paddor@gmail.com>
module Sudoku

  # A game consists of a board, a solver and a verifier. Board is supposed to
  # be set by the {Reader}. Solver and verifier
  # are created lazily and can be overridden using their setters.
  class Game
    # @return [Board] the board to solve
    attr_accessor :board
    attr_writer :solver, :verifier

    # @return [Solver] the solver used to solve this board, cached
    def solver
      @solver ||= BruteForceSolver.new(board)
    end

    # @return [Solver] the verifier used to verify this board, cached
    def verifier
      @verifier ||= Verifier.new(board)
    end
  end

  # A board consists of all the cells and a value range.
  class Board
    # @return [Range<Integer>] values from 1 up to size of this board
    attr_reader :value_range

    # Validates the size, initializes the cells, indexes the cell groups (to
    # quickly lookup a cell's row, column or box later) and sets the value
    # range according to size.
    #
    # @param size [Integer] size of the board
    def initialize(size = 9)
      @size = size
      check_size
      @cells = Array.new(size) { Array.new(size) { Cell.new(self) } }
      index_cell_groups
      @value_range = 1..size
    end

    # Sets a given (predefined) value on a cell.
    # @param row [Integer]
    # @param column [Integer]
    # @param value [Integer]
    def given(row, column, value)
      @cells[row][column].given_value = value
    end

    # @return [String] textual representation of this board
    def to_s
      @cells.map do |row|
        row.map{|c| c.value || "_"}.join(" ")
      end.join("\n")
    end

    # @return [Array<Cell>] flattened array of all cells on this board
    def cells
      @cells.flatten
    end

    # @return [Array<Cell>] flattened array of all empty cells on this board
    def empty_cells
      cells.select { |c| c.empty? }
    end

    # Looks up the respective row.
    # @return [CellGroup] this cell's containing row
    def row_of(cell)
      @rows_by_cell[cell]
    end

    # Looks up the respective column.
    # @return [CellGroup] this cell's containing column
    def column_of(cell)
      @columns_by_cell[cell]
    end

    # Looks up the respective box.
    # @return [CellGroup] this cell's containing box
    def box_of(cell)
      @boxes_by_cell[cell]
    end

    # @return [Boolean] whether no empty cells are left
    def complete?
      cells.none? { |cell| cell.empty? }
    end

    private

    def check_size
      return if Math.sqrt(@size).to_i**2 == @size
      raise "size not a power of an integer"
    end

    # Indexing means storing all cell groups (rows, columns and boxes) in
    # hashes, the cells being the respective key.
    def index_cell_groups
      index_rows
      index_columns
      index_boxes
    end

    def index_rows
      @rows_by_cell = Hash[
        @cells.map do |row|
          cell_group = CellGroup.new(row)
          row.map{ |c| [c, cell_group] }
        end.inject(:+)
      ]
    end

    def index_columns
      @columns_by_cell = Hash[
        # transpose and do the same as for rows
        @cells.transpose.map do |column|
          cell_group = CellGroup.new(column)
          column.map{ |c| [c, cell_group] }
        end.inject(:+)
      ]
    end

    def index_boxes
      # group cells by a unique index for each box
      box_size = Math.sqrt(@size)
      grouped_cells = @cells.flatten.group_by.with_index do |cell,index|
        index += 1
        box_y_index = (index + (index % box_size)) / box_size
        box_x_index = (index + (index % @size)) / @size
        [ box_y_index, box_x_index ]
      end.values

      @boxes_by_cell = Hash[
        grouped_cells.map do |box_cells|
          box = CellGroup.new(box_cells)
          box_cells.map { |cell| [cell, box] }
        end.inject(:+)
      ]
    end
  end

  # A cell basically only consists of its value (if set). But it also knows if
  # that value was a given (predefined) one or not, and has a reference to the
  # board to be able to calculate its {#choices} and {#related_cells}.
  class Cell
    # @return [Integer] this cell's value
    attr_accessor :value

    def initialize(board)
      @board = board
      @value = nil
      @given = false
    end

    def empty?
      !@value
    end

    # Sets this cell's value and remembers that it's a given (predefined) one.
    def given_value=(value)
      @value = value
      @given = true
    end

    # Forgets this cell's value.
    def clear
      @value = nil
    end

    # Whether value can currently be accepted in this cell. The currently set
    # value of the cell, if any, is always accepted.
    def accepts_value?(value)
      return true if value == @value
      !related_cells.has?(value)
    end

    # @return [Array<Integer>] currently possible values for this cell
    def choices
      @board.value_range.select { |v| accepts_value?(v) }
    end

    # @return [Array<CellGroup>] related cell groups: row, column, box
    def related_cell_groups
      [ @board.row_of(self), @board.column_of(self), @board.box_of(self) ]
    end

    # @return [CellGroup] all related cells (row, column, box), cached
    def related_cells
      @related_cells ||= CellGroup.new(
        related_cell_groups.map {|cg| cg.cells}.flatten.uniq)
    end
  end

  # A cell group consists solely of a collection of cells.
  class CellGroup
    # @return [Array<Cells>] the cells in this cell group
    attr_reader :cells

    def initialize(cells)
      @cells = cells
    end

    # @param value [Integer]
    # @return [Boolean] whether the value given is contained in this group
    def has?(value)
      @cells.map(&:value).include? value
    end

    # @param value [Integer]
    # @return [Boolean] whether the cells in this group contain this value
    #   exactly once
    def once?(value)
      cells.one? { |cell| value == cell.value }
    end
  end

  # A Solver consists of the board to solve.
  # @abstract Subclass and override {#step} to implement a solver.
  class Solver
    # @return [Board] the board to solve
    attr_reader :board

    def initialize(board)
      @board = board
      @steps = 0
    end

    # Keeps calling {#step} until it returns false and informs about the
    # number of steps needed to solve this board.
    def solve
      while step
        @steps += 1
      end
      warn "YAY! Solved in #{@steps} steps."
    end

    # @abstract
    # @return [Boolean] whether another step is needed
    def step
      raise NotImplementedError
    end
  end

  # Pretty simple solver using a brute force algorithm.
  # @see http://en.wikipedia.org/wiki/Sudoku_solving_algorithms#Brute-force_algorithm
  class BruteForceSolver < Solver
    def initialize(board)
      super
      @cells = board.empty_cells
      @index = 0
    end

    def step
      return false if @index == @cells.size
      if try_next_choice
#        sleep 0.1
#        warn "--> #{@index + 1}/#{@cells.size}"
        @index += 1
      else
#        warn "<-- #{@index}/#{@cells.size}"
        @cells[@index].clear
        @index -= 1
#        sleep 0.2
      end
      return true
    end

    # Tries the next choice ({Cell#choices}) for the current cell.
    # @return [false] if no choices left
    # @return [true] if choice has been made
    def try_next_choice
      cell = @cells[@index]
      choices = cell.choices

      return false if choices.empty?
      if cell.empty?
        cell.value = choices.first
      else
        next_choice = choices[choices.index(cell.value) + 1] or return false
        cell.value = next_choice
      end
      return true
    end
  end

  # This supposed to be a more intelligent solver to keep the number of steps
  # used to solve difficult boards low (lower).
  class HeuristicSolver < Solver
    class Guess
    end
    class ArbitraryCells < CellGroup
    end
  end

  # Verifies whether the values in a board are valid. It supports validating
  # an incomplete board. In that case, it just skips the empty cells.
  class Verifier
    def initialize(board)
      @board = board
    end

    # @return [Boolean] whether the set values are possible
    def valid?
      @board.cells.reject(&:empty?).all? {|c| c.related_cells.once?(c.value) }
    end
  end

  # Used to read a board and create a game.
  class Reader
    # @return [Game] game wth initialized board and given values set
    attr_reader :game

    # Instantiates a {Game} along with its {Board} of the proper size and sets
    # all the given values on the board.
    # @param input [IO] where the board should be read from
    def initialize(input)
      @input = input
      @game = Game.new
      @game.board = Board.new(rows.size)
      set_given_values
    end

    # @return [Array<Array<Integer, nil>] all rows read and their values,
    #   empty cells' values are nil
    def rows
      @rows ||= # cache
        begin
          rows = []
          @input.each_line do |line|
            next if line =~ /^\s*(#|$)/ # skip comments and blank lines
            values = line.scan(/[_-]|\d+/).map do |n|
              (n = n.to_i).zero? ? nil : n # empty cells => nil
            end
            rows << values
          end
          validate_rows(rows)
          rows
        end
    end

    private

    def validate_rows(rows)
      if not rows.all? { |r| r.size == rows.first.size }
        raise "number of cells in input rows don't match"
      end

      if rows.size != rows.first.size
        raise "number of input rows doesn't match number of cells"
      end
    end

    def set_given_values
      rows.each.with_index do |values, row_index|
        values.each.with_index do |value, column_index|
          next if value == nil
          @game.board.given(row_index, column_index, value)
        end
      end
    end
  end
end
