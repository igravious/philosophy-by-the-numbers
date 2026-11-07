module Truncatable
  def truncate(s, level = 42, suffix = '…')
    if s.length > level
      s.to_s[0..level].gsub(/[^\w]\w+\s*$/, suffix)
    else
      s
    end
  end
end
