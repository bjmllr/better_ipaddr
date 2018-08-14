require "better_ipaddr/classes"

module Kernel
  # @see IPAddr::Base.from
  def IPAddr(object, exception: false, classful: false)
    IPAddr::Base.from(object, exception: exception, classful: classful)
  end
end

class IPAddr
  # @see IPAddr::Base.host_from
  def self.Host(object, exception: false)
    Base.host_from(object, exception: exception)
  end
end
