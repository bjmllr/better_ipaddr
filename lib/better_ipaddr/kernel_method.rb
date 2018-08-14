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

module BetterIpaddr
  module InstanceMethods
    # Emits a snippet of ruby code that can be copied and pasted. Uses the
    # string representation of the address, by default in CIDR notation, instead
    # of the harder-to-read mask notation.
    #
    # @return String
    def inspect(cidr: true, full: false)
      "#{self.class}['#{better_to_s(cidr: cidr, full: full)}']"
    end
  end

  module HostMethods
    # Same as BetterIpaddr::InstanceMethods#inspect but doesn't by default
    # include the CIDR prefix length.
    #
    # @return String
    def inspect(cidr: false, full: false)
      "#{self.class}['#{better_to_s(cidr: cidr, full: full)}']"
    end
  end
end
