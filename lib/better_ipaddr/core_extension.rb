require "ipaddr"
require "better_ipaddr/methods"
require "better_ipaddr/classes"

class IPAddr
  include BetterIpaddr::Constants
  extend BetterIpaddr::ClassMethods
  prepend BetterIpaddr::InstanceMethods
  include Comparable
  include Enumerable
end
