$handle_VAR_WITH_TYPE = Proc.new do |tokens, i|
  both = tokens[i][:text].split(";")
  {
    :i    => i,
    :CODE => "#{both[1]} #{both[0]}"
  }
end

$handle_INT_LITERAL = Proc.new do |tokens, i|
  {
   :i    => i,
   :CODE => tokens[i][:text]
  }
end

$handle_STRING_LITERAL = Proc.new do |tokens, i|
  {
    :i    => i,
    :CODE => tokens[i][:text]
  }
end

$handle_IF = Proc.new do |tokens, i|
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
    :CODE => "if (#{parse(condition)}) {"
  }
end

$handle_ELSE = Proc.new do |tokens, i|
  {
    :i    => i,
    :CODE => "else "
  }
end

$handle_FOR = Proc.new do |tokens, i|
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
    :CODE => "for (int #{var}=#{start}; #{var}<=#{ends}; #{var}+=#{step}) {"
  }
end

$handle_WHILE = Proc.new do |tokens, i|
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
    :CODE => "while (#{parse(condition)}) {"
  }
end

$handle_SPACE = Proc.new do |tokens, i|
  {
    :i    => i,
    :CODE => ""
  }
end

$handle_OTHER = Proc.new do |tokens, i|
  {
    :i => i,
    :CODE => tokens[i][:text]
  }
end

