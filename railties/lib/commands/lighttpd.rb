unless RUBY_PLATFORM !~ /mswin/ && `lighttpd -version 2>/dev/null`.size > 0
  puts "lighttpd is not available on your system (or not in your path)"
  exit 1
end

def tail_f(input)
  loop do
    line = input.gets
    yield line if line
    if input.eof?
      sleep 1
      input.seek(input.tell)
    end
  end
end

config_file = "#{RAILS_ROOT}/config/lighttpd.conf"

port = IO.read(config_file).scan(/^server.port\s*=\s*(\d+)/).first rescue 3000
puts "=> Rails application started on http://0.0.0.0:#{port}"

if ARGV.first == "-d"
  puts "=> Configure in config/lighttpd.conf"
  detach = true
else
  puts "=> Call with -d to detach (requires absolute paths in config/lighttpd.conf)"
  puts "=> Ctrl-C to shutdown server (see config/lighttpd.conf for options)"
  detach = false

  Process.detach(fork do
    begin
      File.open("#{RAILS_ROOT}/log/#{RAILS_ENV}.log", 'r') do |log|
        log.seek(0, IO::SEEK_END)
        tail_f(log) {|line| puts line}
      end
    rescue Exception
    end
    exit
  end)
end

trap(:INT) {exit}
`lighttpd #{!detach ? "-D " : ""}-f #{config_file}`
