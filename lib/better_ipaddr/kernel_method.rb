require "better_ipaddr/classes"

module Kernel
  def IPAddr(object)
    IPAddr::Base.from(object)
  end
end
