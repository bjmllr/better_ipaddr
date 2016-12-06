require "better_ipaddr/classes"

module Kernel
  def IPAddr(object)
    IPAddr::Base.from(object)
  end
end

class IPAddr
  def self.Host(object)
    Base.host_from(object)
  end
end
