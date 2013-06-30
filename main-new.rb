require "./handlers.rb"
require "./tokens.rb"

symbols = Array.new

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
        tokens << {:token => matching_tokens[0], :text => sub}
        break
      end
    end
  end
  tokens
end

$token_functions = {
  :VAR_WITH_TYPE  => $handle_VAR_WITH_TYPE,
  :INT_LITERAL    => $handle_INT_LITERAL,
  :STRING_LITERAL => $handle_STRING_LITERAL,
  :IF             => $handle_IF,
  :FOR            => $handle_FOR,
  :WHILE          => $handle_WHILE,
  :SPACE          => $handle_SPACE,
}

$token_functions.default = $handle_OTHER

def parse(tokens)
  programTree = []
  codeResult = ""

  i = 0
  while i < tokens.length
    kind = tokens[i][:token]
    value = tokens[i][:text]
    
    handled = $token_functions[kind].call(tokens, i)

    i = handled[:i]
    codeResult += handled[:CODE]

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

