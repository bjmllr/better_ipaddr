module BetterIpaddr
  module HostMethods
    def initialize(*)
      super
      @mask_addr = netmask.to_i
    end

    # Returns true if the argument is the same as the receiver, false otherwise.

    def cover?(other)
      self == other
    end

    # @overload each
    #   Yield the object. Returns the object.
    #   @yield [IPAddr]
    #   @return [IPAddr]

    # @overload each
    #   Return an enumerator with the behavior described above.
    #   @return [Enumerator]

    def each
      if block_given?
        yield self
      else
        enum_for(:each)
      end
    end

    # Returns the object.
    # @return [IPAddr]

    def first
      self
    end

    # Returns true.

    def host?
      true
    end

    # Returns the object.
    # @return [IPAddr]

    def last
      self
    end

    # Returns the netmask for a host address.
    def netmask
      self.class::HOST_NETMASK
    end

    # Returns the number of bits in the address.
    def prefix_length
      self.class::BIT_LENGTH
    end

    # Returns 1.
    def size
      1
    end
  end
end
