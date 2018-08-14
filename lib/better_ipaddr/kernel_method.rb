require "better_ipaddr/classes"

module Kernel
  def IPAddr(object, exception: false, classful: false)
    IPAddr::Base.from(object, exception: exception, classful: classful)
  end
end

class IPAddr
  def self.Host(object, exception: false)
    Base.host_from(object, exception: exception)
  end
end
