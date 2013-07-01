require "./handlers.rb"
require "./tokens.rb"

# Public: Translate the code into tokens defined by the "tokens.rb" file.
# 
# code - A String contiaining unprocessed Fish code.
# 
# Examples
#
#   tokenize("for")
#   # => [{:token=>:FOR, :text=>"for"}]
#
# Returns an Array of Hashes containing
#   :token - Then token matched in tokens.rb.
#   :text  - The text that matched said token.
def tokenize(code)
  tokens = []
  until code.empty?
    matching_keys = Tokens.keys.reject { |x| code[x].nil? }
    string_symbol_pairs = matching_keys.map { |x| 
      { 
      :token => Tokens[x],
      :text  => code[x]
      }
    }

    if string_symbol_pairs.empty? 
      puts "Oh-nose!, no matching tokens for |#{code}|"
    end
      
    # The length of the longest matched text
    longest = string_symbol_pairs.map { |x| x[:text].length }.max

    # If the same longest text matches multiple tokens, the dispute is
    # settled by the presidence determined by the order of the Token list.
    top = string_symbol_pairs.select { |x| x[:text].length == longest }.first

    tokens << top
    code = code[longest..-1]
  end
  tokens
end

# Public: Defines how to react to different tokens.
Token_functions = {
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
  :SYMBOL         => $handle_SYMBOL
}
Token_functions.default = $handle_OTHER

# Public: Translate token hashes into valid C
#
# tokens - An array of token hashes of the form
#          :token - The token matched in tokens.rb.
#          :text  - The text that matched said token.
#          These hashes SHOULDD have been generated by the "tokenize" function.
#
# Examples
#
#   parse(tokenize("if a > b {}"))
#   # =>  "if ( a > b ) {\n}"
#
# Returns a (sans-semicolons) C translation of the given token-hashes
def parse(tokens)
  programTree = []
  codeResult = ""

  i = 0
  while i < tokens.length
    kind = tokens[i][:token]
    value = tokens[i][:text]
    
    handled = Token_functions[kind].call(tokens, i)

    i = handled[:i]
    codeResult << handled[:CODE]

    i += 1
  end
  
  return codeResult
end

# Public: Wraps generated C in boilerplate.
#
# code - A String containing C code. 
#        SHOULD be generated by the "format" function.
#
# Returns code wrapped in a main function with relevant headers.
def wrap(code)
  """
#include \"fish.h\"
#include <stdio.h>
int main(void) {
  #{code}
}
"""[1..-1] # String one line down for formatting, remove the newline.
end

# Public: Adds semicolons and indents C code.
#
# code - A String containing unformatted C code without semicolons. 
#        SHOULD be generated by "parse" function.
#
# Examples
#
#   format("int hello")
#   # => "int hello;"
#
#   format("int hello // comment")
#   # => "int hello; // comment"
#
#   format("if (a == b) {\nprintf("Foo\n")\n}")
#   # => "if (a == b) {\n    printf("foo\n")\n};"}
#
# Returns a String containting pretty-printed C code with semicolons.
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

# ~-~ Main Operation

if __FILE__ == $0
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
      if system("gcc -o #{outName} -std=c99 #{outName}.c")
        puts "File compiled."
      else
        puts "Error: Could not compile."
      end
    end
    compile.join
  end

  if command == "run"
    run = Thread.new do 
      if system("./#{outName}")
        puts "~---------------------~"
        puts "File ran successfully."
      else
        puts "Error: Could not run."
      end
    end
    run.join
  end

  if command != "say"
    puts "Elapsed Time: #{Time.now - start}"
  end

  puts "SYMBOLS: #{$symbols.map { |x| x[:text] }.uniq}"
end
