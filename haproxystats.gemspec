$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = 'haproxystats'
  s.version     = '0.0.7'
  s.date        = '2015-03-02'
  s.summary     = "HAProxy Stats Parser"
  s.description = "Reads and parses stats from HAProxy Unix socket."
  s.authors     = ["Tom Taylor"]
  s.email       = 'tom@tommyt.co.uk'
  s.files       = [
                    "lib/haproxystats.rb", 
                    "lib/haproxystats/socket.rb",
                    "lib/haproxystats/stats.rb",
                  ]
  s.homepage    =
    'https://github.com/t0mmyt/haproxystats-ruby'
  s.license       = 'BSD'
end
