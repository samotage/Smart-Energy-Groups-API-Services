
module SExpression

  def self.parse(s)
    result, _ = scan(s, 0)
    result
  end

  def self.scan(s, i)
    i = skip_whitespace(s, i)
    case s[i,1]
      when '('
        result, i = scan_array(s, i)
      else
        result, i = scan_atom(s, i)
    end
    i = skip_whitespace(s, i)
    [result, i]
  end

  def self.scan_atom(s, i)
    i = skip_whitespace(s, i)
    head = i
    while i < s.length && s[i,1] !~ /[\s\)]/
      i += 1
    end
    tail = i - 1
    i = skip_whitespace(s, i)
    [s[head..tail], i]
  end

  def self.scan_array(s, i)
    i = skip_whitespace(s, i)
    array = []
    if i < s.length && s[i,1] == '('
      i = skip_whitespace(s, i + 1)
      while i < s.length && s[i,1] != ')'
        element, i = scan(s, i)
        array << element
      end

      if i < s.length && s[i, 1] == ')'
        i = skip_whitespace(s, i + 1)
      end
    end
    [array, i]
  end

  def self.skip_whitespace(s, i)
    while i < s.length && s[i,1] =~ /\s/
      i += 1
    end
    i
  end

end
