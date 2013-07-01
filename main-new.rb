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

    if string_symbol_pairs.empty? 
      puts "Oh-nose!, no matching tokens for |#{code}|"
    end
      
    longest = string_symbol_pairs.map { |x| x[:text].length }.max

    # If the same longest text matches multiple tokens, the dispute is
    # settled by the presidence determined by the order of the Token list
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
    codeResult << handled[:CODE]

    i += 1
  end
  
  return codeResult
end

def wrap(code)
  """
#include <stdio.h>
#include \"fish.h\"
int main(void) {
  #{code}
}
"""[1..-1]
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

  code.join("\n")
end

start = Time.now
tokens = []
output = ""
File.open(ARGV[1], "r") do |file|
  file = file.read.strip
  tokens = tokenize(file)
  output = format(wrap(parse(tokens)))
end

command = ARGV[0]
if command == "say" 
  puts output
end

if ["write", "compile", "run"].include?(command)
  outName = ARGV[1].split(".")[0]
  File.open("#{outName}.c", "w") do |file|
    file.write(output)
  end
  puts "File written."
end

if ["compile", "run"].include?(command)
  puts "Compiling..."
  compile = Thread.new do 
    unless system("gcc -o #{outName} -std=c99 #{outName}.c")
      puts "Error: Could not compile."
    end
  end
  compile.join
  puts "File compiled."
end

if command == "run"
  run = Thread.new do 
    unless system("./#{outName}")
      puts "Error: Could not run. (Wrote and compiled successfully)"
    end
  end
  run.join
  puts "~---------------------~"
  puts "File ran successfully."
end

if command != "say"
  puts "Elapsed Time: #{Time.now - start}"
end
