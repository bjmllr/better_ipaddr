require "ipaddr"
require "better_ipaddr/constants"

module BetterIpaddr
  module ClassMethods
    include Constants

    # @overload [](address, family)
    #   @param address [Integer] the integer representation of the address
    #   @param family [Symbol] a symbol named for the address's
    #     address family, one of +:ipv4+, +:ipv6+, or +:mac+.
    #   @return [IPAddr]
    #   Wrapper for IPAddr.new that accepts a symbolic family name and
    #   returns a specialized IPAddr subclass.
    #
    # @overload [](address, family)
    #   @param address [Integer] the integer representation of the address
    #   @param family [Integer] the magic number representing the address's
    #     address family.
    #   @return [IPAddr]
    #   Wrapper for IPAddr.new that accepts a symbolic family name and
    #   returns a specialized IPAddr subclass.
    #
    # @overload [](address)
    #   @param address [String] the string representation of the address
    #   @return [IPAddr]
    #   Wrapper for IPAddr.new that accepts the string representation
    #   of an address returns a specialized IPAddr subclass.

    def [](address, family = nil)
      instance = case family
                 when Symbol
                   self[address, SYMBOL_TO_FAMILY.fetch(family)]
                 when IPAddr
                   address
                 when nil
                   new(address)
                 else
                   new(address, family)
                 end
      IPAddr::Base.specialize(instance)
    end
  end

  module InstanceMethods
    include Constants

    def self.included(base)
      return unless base <= IPAddr
      base.class_eval do
        define_method :stdlib_to_s, IPAddr.instance_method(:to_s)
      end
    end

    # Return the magic number representing the address family.
    # @return [Integer]
    attr_reader :family

    # Return the integer representation of the netmask.
    # @return [Integer]
    attr_reader :mask_addr

    # Return the string representation of the netmask.
    # @return [String]
    def netmask
      self.class[mask_addr].to_s
    end

    # Return the address greater than the original address by the
    # given offset. Note that the result will always be a host
    # address.
    # @param offset [Integer] the difference between the original
    #   address and the returned address
    # @return [IPAddr]

    def +(offset)
      self.class.new(@addr + offset, family)
    end

    # Return the address less than the original address by the given
    # offset. Note that the result will always be a host
    # address.
    # @param offset [Integer] the difference between the original
    #   address and the returned address
    # @return [IPAddr]

    def -(offset)
      self + (-offset)
    end

    # @overload <=>(other)
    #   Compare this address with another address of the same address
    #   family.
    #   @param [IPAddr] other
    #   @return [Integer]

    # @overload <=>(other)
    #   Compare this address with the integer representation of another
    #   address of the same address family.
    #   @param [Integer] other
    #   @return [Integer]

    def <=>(other)
      if other.is_a?(IPAddr)
        family_difference = family <=> other.family
        return family_difference unless family_difference == 0
      elsif !other.is_a?(Integer)
        fail ArgumentError, "Can't compare #{self.class} with #{other.class}"
      end

      address_difference = to_i <=> other.to_i

      if address_difference != 0 || !other.is_a?(IPAddr)
        return address_difference
      end

      other.instance_variable_get(:@mask_addr) <=> @mask_addr
    end

    # Test the equality of two IP addresses, or an IP address an
    # integer representing an address in the same address family.
    #
    # Returns false for any other type.
    #
    # @param other [IPAddr, Integer] the address to compare with
    # @return [Boolean]

    def ==(other)
      (other.is_a?(IPAddr) || other.is_a?(Integer)) && (self <=> other) == 0
    end

    # The address at the given offset relative to the network address
    # of the network. A negative offset will be used to count
    # backwards from the highest addresses within the network.
    # @param offset [Integer] the index within the network of the
    # desired address
    # @return [IPAddr] the address at the given index

    def [](offset)
      return self if offset.zero? && host?
      offset2 = offset >= 0 ? offset : size + offset
      self.class[to_i + offset2, family: family]
    end

    # Returns the number of bits allowed by the address family.
    # A more efficient form of this method is available to the
    # specialized IPAddr child classes.
    #
    # @return [Integer]

    def address_family_bit_length
      FAMILY_TO_BIT_LENGTH.fetch(family)
    end

    # Returns a string representation of the address without a prefix length.
    #
    # @return [String]

    def base(full: false)
      if full
        to_string
      else
        stdlib_to_s
      end
    end

    def better_to_s(cidr: false, full: false)
      if cidr
        "#{base(full: full)}/#{prefix_length}"
      else
        base(full: full)
      end
    end

    # Return a string containing the CIDR representation of the address.
    #
    # @return [String]

    def cidr(cidr: nil, full: false)
      better_to_s(cidr: true, full: full)
    end

    # Test whether or not this address completely encloses the other address.

    def cover?(other)
      first <= other.first && other.last <= last
    end

    # @overload each
    #   Yield each host address contained within the network. A host
    #   address, such as +1.1.1.1/32+, will yield only itself. Returns
    #   the original object.
    #   @yield [IPAddr]
    #   @return [IPAddr]

    # @overload each
    #   Return an enumerator with the behavior described above.
    #   @return [Enumerator]

    def each
      if block_given?
        (0...size).each do |offset|
          yield self[offset]
        end
        self
      else
        enum_for(:each)
      end
    end

    # The first host address in the network.
    # @return [IPAddr]

    def first
      self[0]
    end

    # Return a new address with the prefix length reduced by the given
    # amount. The new address will cover the original address.
    # @param shift [Integer] the decrease in the prefix length
    # @return [IPAddr]

    def grow(shift)
      mask(prefix_length - shift)
    end

    # Return true if the address represents a host (i.e., only one address).

    def host?
      prefix_length >= address_family_bit_length
    end

    # Return the last address in the network, which by convention is
    # the broadcast address in IP networks.
    # @return [IPAddr]

    def last
      self[-1]
    end

    alias_method :broadcast, :last

    # Test whether or not two networks have any addresses in common
    # (i.e., if either entirely encloses the other).

    def overlap?(other)
      cover?(other) || other.cover?(self)
    end

    # Return the prefix length.
    # A more efficient form of this method is available to the
    # specialized +IPAddr+ child classes.
    # @return [Integer]

    def prefix_length
      NETMASK_TO_PREFIX_LENGTH[family][mask_addr]
    end

    alias_method :prefixlen, :prefix_length

    # Return a new address with the prefix length increased by the
    # given amount. The old address will cover the new address.
    # @param shift [Integer] the increase in the prefix length
    # @return [Boolean]

    def shrink(shift)
      mask(prefix_length + shift)
    end

    # Return the number of host addresses representable by the network
    # given its size.
    # @return [Integer]

    def size
      2**(address_family_bit_length - prefix_length)
    end

    # Returns a summary address if the two networks can be combined
    # into a single network without covering any other networks.
    # Returns +nil+ if the two networks can't be combined this way.
    # @return [IPAddr?]

    def summarize_with(other)
      if other.nil?
        nil
      elsif cover?(other)
        self
      elsif other.cover?(self)
        other
      elsif other.grow(1) == grow(1)
        grow(1)
      end
    end

    # Return a range representing the network. A block can be given to
    # specify a conversion procedure, for example to convert the first
    # and last addresses to integers before building the range.
    # @return [Range(IPAddr)]

    def to_range
      if block_given?
        (yield first)..(yield last)
      else
        first..last
      end
    end

    # Return a wildcard mask representing the network.
    # @return [IPAddr]

    def wildcard
      _to_string(@mask_addr.to_i ^ (2**address_family_bit_length - 1))
    end
  end
end
