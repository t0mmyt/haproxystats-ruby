$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = 'haproxystats'
  s.version     = '0.0.2'
  s.date        = '2015-02-16'
  s.summary     = "Reads and parses stats from HAProxy Unix socket"
  s.description = "Reads and parses stats from HAProxy Unix socket."
  s.authors     = ["Tom Taylor"]
  s.email       = 'tom@tommyt.co.uk'
  s.files       = [
                    "lib/haproxystats.rb", 
                    "lib/haproxystats/socket.rb",
                    "lib/haproxystats/stats.rb",
                  ]
  s.homepage    =
    'https://githib.com/t0mmyt/haproxystats-ruby'
  s.license       = 'ModifiedBSD'
end
