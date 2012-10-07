def render name
  require 'erb'
  ERB.new(File.read("template/#{name}.html.erb")).result(binding)
end

def result_diff current, previous
  if previous
    diff = current - previous
    diff >= 0 ? "(+#{diff})" : "(#{diff})"
  end
end

def print_log commit, category, name, complete, error
  lines = ""
  line_numbers = ""
  github_links = ""
  n = 1
  #@test['log_complete'].map{|line| line = @test['log_error'].include?(line) ? "<span class=\"line error\">#{line}</span>" : line}.join
  complete.each do |line|
    if error.include?(line)
      line_numbers << "<span id=\"L#{n}\" rel=\"#L#{n}\" class=\"line-number line-number-error\"><a href=\"#L#{n}\">#{n}</a></span>"
      lines << "<span class=\"line line-error\">#{line}</span>"

      cleaned_line = line.gsub('In file included from', '')
      cleaned_line = cleaned_line.gsub('from', '')

      pos = cleaned_line.strip.match /^([^\/]+.+\.\w+):(\d+)[:,]/
      if pos
        link = pos[1]
        if pos[1] =~ /^(\.{2}\/){3}openFrameworks/
          link = pos[1].gsub(/^(\.{2}\/){3}openFrameworks/, "https://github.com/openframeworks/openFrameworks/tree/#{commit}/libs/openFrameworks") + "#L#{pos[2]}"
        elsif pos[1] =~ /^(\.{2}\/){3}libs/
          link = pos[1].gsub(/^(\.{2}\/){3}libs/, "https://github.com/openframeworks/openFrameworks/tree/#{commit}/libs") + "#L#{pos[2]}"
        elsif pos[1] =~ /^(\.{2}\/){3}addons/
          link = pos[1].gsub(/^(\.{2}\/){3}addons/, "https://github.com/openframeworks/openFrameworks/tree/#{commit}/addons") + "#L#{pos[2]}"
        elsif pos[1] =~ /^src\// and name !~ /projectGenerator/
          link = pos[1].gsub(/^src\//, "https://github.com/openframeworks/openFrameworks/tree/#{commit}/examples/#{category}/#{name}/src/") + "#L#{pos[2]}"
        elsif pos[1] =~ /^src\// and name =~ /projectGenerator/
          link = pos[1].gsub(/^src\//, "https://github.com/openframeworks/openFrameworks/tree/#{commit}/apps/devApps/#{name}/src/") + "#L#{pos[2]}"
        end

        github_links << "<span class=\"line-number line-number-error\"><a href=\"#{link}\"><i class=\"icon-github\"></i></a></span>"
      else
        github_links << "<span class=\"line-number line-number-error\">&nbsp;</span>"
      end
    else
      line_numbers << "<span id=\"L#{n}\" rel=\"#L#{n}\" class=\"line-number\"><a href=\"#L#{n}\">#{n}</a></span>"
      lines << "<span class=\"line\">#{line}</span>"
      github_links << "<span class=\"line-number\">&nbsp;</span>"
    end
    n += 1
  end
  "<tr>
    <td class=\"gutter\">
      <pre class=\"line-numbers\"><div class=\"line-numbers-wrap\">#{github_links}</div></pre>
    </td>
    <td class=\"gutter\">
      <pre class=\"line-numbers\"><div class=\"line-numbers-wrap\">#{line_numbers}</div></pre>
    </td>
    <td class=\"code\">
      <pre><div class=\"line-wrap\">#{lines}</div></pre>
    </td>
  </tr>"
end

def time_diff start_time, end_time
  require 'time_diff'
  d = Time.diff(start_time, end_time)
  str = []

  %w[hour minute second].each do |t|
    s = ""
    if d[t.to_sym] != 0
      s += "#{d[t.to_sym]} #{t}"
      s += "s" if d[t.to_sym] > 1
    end
    str << s if s.length > 0
  end

  str.join(' ')
end
