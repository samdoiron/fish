require "./tokens.rb"


def tokenize(code)
  tokens = []
  (0...code.length).each do |i|
    # this loop is backwards so that it grabs
    # the longest matching key ("10" vs. "1", "0")
    (code.length-1).downto(i).each do |e| 
      sub = code[i..e]

      matching_tokens = Tokens.keys.select { |x| x =~ sub }
        .collect { |x| Tokens[x] }

      unless matching_tokens.empty? 
        code = code[sub.length-1..-1]
        tokens << [matching_tokens[0], sub]
        break
      end
    end
  end
  tokens
end

def parse(tokens)
  programTree = []
  codeResult = ""

  # TODO rework assignment to use 
  # last node
  register    = nil
  partial_var = nil

  i = 0
  while i < tokens.length
    kind, value = tokens[i]
    
    case kind
    when :INT_LITERAL
      codeResult << value

    when :VAR_WITH_TYPE
      codeResult << value.split(";")[1] + " " + value.split(";")[0]

    when :STRING_LITERAL
      codeResult << "#{value}"

    when :IF
      condition = []
      myToken = []
      until myToken[0] == :OPEN
        i += 1

        if i > tokens.length
          throw "Missing token :OPEN"
        end

        myToken = tokens[i]
        condition << myToken
      end

      condition = condition[0..-2] # Leave off the {
      codeResult << "if (#{parse(condition)}) {"

    when :FOR
      after_for = []

      i += 1
      until tokens[i][0] == :OPEN

        if i >= tokens.length
          throw "Missing token :OPEN"
        end

        after_for << tokens[i]
        i += 1
      end
      
      var = (after_for.select { |x| x[0] == :SYMBOL })[0][1]
      after_for = after_for.drop_while { |x| x[0] != :IN }.drop(1)

      section = []
      sections = []

      after_for.each do |i|
        unless i == [:COMMA, ","]
          unless i == [:SPACE, " "]
            section << i
          end
        else
          sections << section
          section = []
        end
      end

      sections << section
      start = parse(sections[0])
      ends =  parse(sections[1])

      step = [[:INT_LITERAL, "1"]]

      if sections.length == 3
        step = sections[2]
      end

      step = parse(step)

      codeResult << "for (int #{var}=#{start}; #{var} <= #{ends}; #{var}+=#{step}) {"

    when kind == :WHILE
      myToken = []
      condition = []
      until myToken[0] == :OPEN
        i += 1

        if i > tokens.length
          throw "Missing token :OPEN"
        end

        myToken = tokens[i]
        condition << myToken
      end

      codeResult << "while (#{parse(condition)}) {"

    when :SPACE # Ignore spaces!

    else 
      codeResult << value
    end

    i += 1
  end
  
  return codeResult
end

def wrap(code)
  """#include <stdio.h>
#include \"fish.h\"
int main(void) {
  #{code}
}
"""
end

def format(code)
  indent = 4
  depth = 0
  code = code.lines.collect do |line|
    line.strip!

    unless ["}", "{"].include?(line[-1]) or line.empty? \
      or line[0] == "#"
      line += ";"
    end


    if line[-1] == "}"
      depth -= 1
    end

    line = line.prepend(" " * (indent * depth))

    if line[-1] == "{"
      depth += 1
    end

    
    line
  end

  code
end
tokens = []
File.open("myFile.fish") do |file|
  file = file.read.strip
  tokens = tokenize(file)
  puts format(wrap(parse(tokens)))
end

