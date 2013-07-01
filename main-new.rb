require "./handlers.rb"
require "./tokens.rb"

symbols = Array.new

def tokenize(code)
  keys = Tokens.keys
  tokens = []
  until code.empty?
    matching = keys.reject { |x| code[x].nil? }
    string_symbol_pairs = matching.map { |x| 
      { 
      :token => Tokens[x],
      :text  => code[x]
      }
    }

    longest = string_symbol_pairs.map { |x| x[:text].length }.max

    # If the same longest text matches multiple tokens, the dispute is
    # settled by the presidence determined by the Token list
    top = string_symbol_pairs.select { |x| x[:text].length == longest }.first

    tokens << top
    code = code[longest..-1]
  end
  tokens
end

$token_functions = {
  :VAR_WITH_TYPE  => $handle_VAR_WITH_TYPE,
  :INT_LITERAL    => $handle_INT_LITERAL,
  :STRING_LITERAL => $handle_STRING_LITERAL,
  :IF             => $handle_IF,
  :ELIF           => $handle_ELIF,
  :FOR            => $handle_FOR,
  :WHILE          => $handle_WHILE,
  :SPACE          => $handle_SPACE,
  :ELSE           => $handle_ELSE,
  :COMMENT        => $handle_COMMENT,
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

    if line.include?("//")
      line = line[0..line.index("//")-3]
    end

    unless ["}", "{"].include?(line[-1]) \
      || line.empty?  \
      || line[0] == "#" 

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

start = Time.now
tokens = []
File.open("myFile.fish") do |file|
  file = file.read.strip
  tokens = tokenize(file)
  puts tokens
  # puts format(wrap(parse(tokens)))
end

puts "Elapsed Time: #{Time.now - start}"
