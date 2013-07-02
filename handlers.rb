$variables = {}
$functions = []

Builtins = {
  :print => {
    :int    => "printf(\"%d\\n\", <A>)",
    :string => "printf(\"%s\\n\", <A>)",
    :float  => "printf(\"%f\\n\", <A>)",
  }
}

$handle_OTHER = lambda do |tokens, i|
  {
    :i => i,
    :code => tokens[i][:text]
  }
end

$handle_VAR_WITH_TYPE = lambda do |tokens, i|
  both = tokens[i][:text].split(";")
  $variables[both[0]] = both[1].to_sym
  {
    :i    => i,
    :code => "#{both[1]} #{both[0]}"
  }
end

$handle_INT_LITERAL = lambda do |tokens, i|
  {
   :i    => i,
   :code => tokens[i][:text]
  }
end

$handle_STRING_LITERAL = lambda do |tokens, i|
  {
    :i    => i,
    :code => tokens[i][:text]
  }
end

$handle_IF = lambda do |tokens, i|
  condition = []

  until tokens[i][:token] == :OPEN
    i += 1
    
    if i > tokens.length
      throw "Missing token :OPEN"
    end

    condition << tokens[i]
  end

  condition = condition[0..-2] # Leave off the :OPEN
  {
    :i    => i,
    :code => "if (#{parse(condition)}) {"
  }
end

$handle_ELIF = lambda do |tokens, i|
  condition = []

  until tokens[i][:token] == :OPEN
    i += 1
    
    if i > tokens.length
      throw "Missing token :OPEN"
    end

    condition << tokens[i]
  end

  condition = condition[0..-2] # Leave off the :OPEN
  {
    :i    => i,
    :code => "else if (#{parse(condition)}) {"
  }
end

$handle_ELSE = lambda do |tokens, i|
  {
    :i    => i,
    :code => "else"
  }
end

$handle_FOR = lambda do |tokens, i|
  after_for = []

  # i += 1 ?
  until tokens[i][:token] == :OPEN
    if i >= tokens.length
      throw "Missing token :OPEN"
    end

    after_for << tokens[i]
    i += 1
  end

  var = (after_for.select { |x| x[:token] == :SYMBOL }).first[:text]
  after_for = after_for.drop_while { |x| x[:token] != :IN }.drop(1)

  section  = []
  sections = []

  after_for.each do |i|
    unless i[:token] == :COMMA
      unless i[:token] == :SPACE
        section << i
      end
    else
      sections << section
      section = []
    end
  end

  sections << section
  start = parse(sections[0])
  ends  = parse(sections[1])

  step = [{:token => :INT_LITERAL, :text => "1"}]

  if sections.length == 3
    step = sections[2]
  end

  step = parse(step)

  {
    :i => i,
    :code => "for (int #{var}=#{start}; #{var}<=#{ends}; #{var}+=#{step}) {"
  }
end

$handle_WHILE = lambda do |tokens, i|
  condition = []
  until tokens[i][:token] == :OPEN
    i += 1

    if i > tokens.length
      throw "Missing token :OPEN"
    end

    condition << tokens[i]
  end

  {
    :i => i,
    :code => "while (#{parse(condition)}) {"
  }
end

$handle_SPACE = lambda do |tokens, i|
  {
    :i    => i,
    :code => " "
  }
end

$handle_COMMENT = lambda do |tokens, i|
    {
        :i => i,
        :code => " //"
    }
end

$handle_SYMBOL = lambda do |tokens, i|
  $handle_OTHER.call(tokens, i)
end


$handle_FUNCTION_CALL = lambda do |tokens, i|
  function, params = tokens[i][:text].split("(")
  params = params[0..-2]
  $functions << function
  {
    :i    => i,
    :code => "#{function}(#{parse(tokenize(params))})"
  }
end

$handle_INT_LITERAL_ASSIGN = lambda do |tokens, i|
  #i = 10  
  split = tokens[i][:text].split(" ")
  name, value = split[0], split[2]
  $variables[name] = :int

  {
    :i    => i,
    :code => "int #{name} = #{value}"
  }
end


$handle_STRING_LITERAL_ASSIGN = lambda do |tokens, i|
  split = tokens[i][:text].split(" ")
  name, value = split[0], split[2]
  $variables[name] = :string

  {
    :i    => i,
    :code => "char #{name}[] = #{value}"
  }
end

$handle_FLOAT_LITERAL_ASSIGN = lambda do |tokens, i|
  split = tokens[i][:text].split(" ")
  name, value = split[0], split[2]
  $variables[name] = :float

  {
    :i    => i,
    :code => "double #{name} = #{value}"
  }
end

$handle_SYMBOL_ASSIGN = lambda do |tokens, i|
  # "x = y"
   
  name, _, value = tokens[i][:text].split(" ")
  $variables[name] = $variables[value]
  {
    :i    => i,
    :code => "#{$variables[name]} #{name} = #{value}"
  }
end

$handle_PRINT = lambda do |tokens, i|
  text = tokens[i][:text]
  arg = text.split("(")[1][0..-2]
  type = :unknown

  if /\A[0-9]+\z/ =~ arg
    type = :int

  elsif /".+"/ =~ arg
    type = :string

  elsif /\A[0-9]+.[0-9]+\z/ =~ arg
    type = :float

  elsif $variables.include?(arg)
    type = $variables[arg]
  else
    puts "WARNING: Unable to infer value for print, assuming int"
    type = :int
  end

  {
    :i    => i,
    :code => Builtins[:print][type].sub("<A>", arg)
  }

end
