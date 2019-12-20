CODE_LENGTH = 4

NUM_COLORS = 6

COLORS = [
  :EM,
  :BK,
  :WH,
  :RD,
  :YW,
  :GR,
  :BU]

COLOR_CODES = {EM: "empty", BK: "Black", WH: "White", RD: "Red", YW: "Yellow", GR: "Green", BU: "Blue"}


class Row
  attr_reader :pegs

  def self.convert_string_to_code guess
    code = []
    guess.length.times{|index| code << COLORS[guess[index].to_i]}
    code
  end

  def self.convert_code_to_string code
    guess = ""
    code.length.times{|color| guess << COLORS.find_index(color).to_s}
    guess
  end

  def initialize
    @pegs = [:EM,:EM,:EM,:EM]
  end

  def to_s
    "#{pegs[0]}.#{pegs[1]}.#{pegs[2]}.#{pegs[3]}"
  end

  def dup #deep copy
    dupRow = Row.new
    self.pegs.each_with_index {|peg,index| dupRow.pegs[index] = self.pegs[index].dup}
    dupRow
  end
end

class CodeRow < Row

  def initialize code
    @pegs = Row.convert_string_to_code(code)
  end

  def empty?
    pegs.all? {|peg| peg == :EM}
  end

end

class KeyRow < Row

  def initialize keys
    @pegs = keys
  end
end

class AnswerRow < Row

  def initialize answer
    @pegs = Row.convert_string_to_code(answer)
  end
end

class Board
  attr_accessor :codeRows, :keyRows, :answerRow, :guessesUsed

  def initialize numRows, answerRow
    @codeRows = Array.new(numRows) {Row.new}
    @keyRows = Array.new(numRows) {Row.new}
    @answerRow = AnswerRow.new(answerRow)
    @guessesUsed = 0
  end

  def add_code_row guess
    codeRows[guesses_used] = CodeRow.new(guess)
  end

  def add_key_row keyRow
    keyRows[guesses_used] = KeyRow.new(keyRow)
  end

  def check_code
    #returns the keycode based on the code to be checked
    #codeRow looks like [:BU, :BL, :WH, :RD]...
    rowNumber = guesses_used
    answerPegs = answerRow.dup.pegs
    codePegs = codeRows[rowNumber].dup.pegs

    keys_used = 0
    max_keys = CODE_LENGTH
    keyPegs = Array.new(CODE_LENGTH,:EM)

    CODE_LENGTH.times{|index|
      if codePegs[index] == answerPegs[index]
        keyPegs[keys_used] = :BK
        keys_used += 1
        codePegs[index] = :NC
        answerPegs[index] = :NA
      end
    }

    return keyPegs if keys_used == max_keys

    CODE_LENGTH.times{|index|
      if answerPegs.include? (codePegs[index])
        keyPegs[keys_used] = :WH
        keys_used += 1
        answerPegs[answerPegs.find_index(codePegs[index])] = :NA
        codePegs[index] = :NC
        return keyPegs if keys_used == max_keys
      end
    }

    return keyPegs
  end

  def number_of_guesses
    return codeRows.length
  end

  def guesses_left
    return number_of_guesses - guessesUsed
  end

  def guesses_used
    return guessesUsed
  end

  def out_of_guesses?
    return guesses_used >= number_of_guesses
  end

  def won?
    return keyRows.any?{|keyRow| keyRow.pegs == [:BK, :BK, :BK, :BK]}
  end

  def display
    keyRows.length.times{ |row| puts codeRows[row].to_s << " | " << keyRows[row].to_s}
  end

end

class Player

  def guess board
  end

  def make_code
  end

end

class HumanPlayer < Player


  def guess board
      human_prompt "guess"
  end

  def make_code
      human_prompt "code for the computer to guess"
  end

  def to_s
    "human"
  end

  private

  def valid_code? code
    begin
      #return false if user guessed an invalid color
      return false unless code.split("").all?{ |color| (1..6).include? color.to_i}
    rescue
      #return false if string contained nonsense
      return false
    end

    if code.length == CODE_LENGTH
      return true
    else
      return false
    end
  end

  def human_prompt request
    loop do
      puts "please provide a #{request}.  1 for black, 2 for white, 3 for red, 4 for yellow, 5 for green, 6 for blue, from left to right.  E.g. 1234 or 5422"
      response = gets.chomp

      if valid_code?(response)
        return response
      else
        puts "'#{response}' is not a valid code.  Please try again."
      end
    end
  end
end

class ComputerPlayer < Player

  attr_reader :solutionSpace
  attr_accessor :board

  def initialize
    @solutionSpace = []
  end

  def guess board
    if board.guesses_used == 0
      create_solution_space
      #wikipedia said this was a good guess to start with...
      return "1122"
    else
      update_solution_space board
      return solutionSpace.sample
    end

  end

  def make_code
    code = ""
    4.times{code << (1 + rand(6)).to_s}
    code
  end

  def to_s
    "computer"
  end

  private

  def create_solution_space
    NUM_COLORS.times{|index0|
      NUM_COLORS.times{|index1|
        NUM_COLORS.times{|index2|
          NUM_COLORS.times{|index3|
        solutionSpace << ((index0+1).to_s << (index1+1).to_s << (index2+1).to_s << (index3+1).to_s)
          }
        }
      }
    }
  end

  def update_solution_space board
    lastGuess = board.codeRows[board.guesses_used-1].dup.pegs
    lastAnswer = board.keyRows[board.guesses_used-1].dup.pegs

    solutionSpace.filter! {|solution|
      if matches(Row.convert_string_to_code(solution), lastGuess) == [lastAnswer.count(:BK),lastAnswer.count(:WH)]
        true
      end
    }
  end

  def matches solution, lastGuess
    #return an array of [blackMatches, whiteMatches] indicating the number of each
    blackMatches = 0
    whiteMatches = 0
    emptyMatches = 0
    
    whiteSolution = []
    solution.each{|item| whiteSolution << item.dup}
    whiteGuess = []
    lastGuess.each{|item| whiteGuess << item.dup}


    CODE_LENGTH.times{|index|
      #for black matches, check if the exact indices match
      if solution[index] == lastGuess[index]
        blackMatches += 1
        whiteSolution[index] = :NA
        whiteGuess[index] = :NA
      end
    }

    #for white matches: There can't be more than 2 for any color (there would have been a black match).  
    #Take what's left after black matches are done, and see if player guessed the right color in the wrong place.
    COLORS.each{ |color|
      if whiteSolution.count(color) == 2 and whiteGuess.count(color) >= 2
        whiteMatches += 2
      elsif whiteSolution.count(color) >= 1 and whiteGuess.count(color) >= 1
        whiteMatches += 1
      end
    }

    return [blackMatches,whiteMatches]
  end

end

class Game
  attr_accessor :board
  attr_reader :codeMaker, :codeBreaker

  def initialize numRows, codeBreaker, codeMaker
    @codeBreaker = codeBreaker
    @codeMaker = codeMaker
    @board = Board.new(numRows,codeMaker.make_code)
  end


  def self.create
    breaker = self.who_is_codebreaker
    maker = breaker.class == HumanPlayer ? ComputerPlayer.new : HumanPlayer.new
    Game.new 12, breaker, maker
  end



  def play!

    until board.won? || board.out_of_guesses?
      board.display

      puts "#{codeBreaker}, you have #{board.guesses_left} guesses left."

      current_guess = codeBreaker.guess(board)

      respond_to_guess(current_guess)

      board.guessesUsed = board.guesses_used + 1
    end

    board.display
    if board.won?
      puts "Congratulations, #{codeBreaker}, you guessed the code in #{board.guesses_used} guesses!"
      puts "The secret code was #{board.answerRow}"
    else
      puts "Congratulations, #{codeMaker}, you stumped the #{codeBreaker}!"
    end
  end

  def respond_to_guess guess
    board.add_code_row(guess)
    keyCode = board.check_code
    board.add_key_row(keyCode)
  end

  private

  def self.who_is_codebreaker
    loop do
      puts "Who will be the codebreaker?  '1' for human, '2' for computer"
      begin
        codeBreaker = gets.chomp.to_i
        if codeBreaker == 1
          puts "you have selected 'human' as the codebreaker."
          return HumanPlayer.new
        elsif codeBreaker == 2
          puts "you have selected 'computer' as the codebreaker."
          return ComputerPlayer.new
        else
          puts "you need to enter 1 or 2."
        end
      rescue
        puts "you need to enter 1 or 2."
      end
    end
  end
end

game = Game.create
game.play!


























