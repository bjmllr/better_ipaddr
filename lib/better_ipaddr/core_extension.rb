require "ipaddr"
require "better_ipaddr/methods"
require "better_ipaddr/classes"

class IPAddr
  include BetterIpaddr::Constants
  prepend BetterIpaddr::InstanceMethods
  include Comparable
  include Enumerable
end
