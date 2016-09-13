require "better_ipaddr/methods"

class IPAddr
  class Base < IPAddr
    include BetterIpaddr::Constants
    include BetterIpaddr::InstanceMethods
    include Comparable
    include Enumerable

    def inherited(cls)
      cls.extend BetterIpaddr::ClassMethods
    end

    # Create an IPAddr from the given object.
    #
    # Returns nil if the object is of a type that can't be converted to an
    # IPAddr.
    #
    # @param address [Integer, IPAddr, String]
    # @param mask [Integer, IPAddr, String, Nil]
    # @param family [Integer]
    # @return [IPAddr, Nil]
    def self.[](address, mask = nil, family: self::FAMILY)
      prefix_length = mask && object_to_prefix_length(mask, family)

      case address
      when Integer
        from_integer(address, prefix_length, family: family)
      when IPAddr
        from_ipaddr(address, prefix_length, family: family)
      when String
        from_string(address, prefix_length, family: family)
      end
    end

    # Create an IPAddr from an Integer.
    #
    # @param address [Integer]
    # @param mask [Integer, String] a netmask or prefix length
    # @param family [Integer, Nil]
    # @return [IPAddr]
    def self.from_integer(address, prefix_length, family: self::FAMILY)
      new(address, family).mask(prefix_length || FAMILY_TO_BIT_LENGTH[family])
    end

    # Create an IPAddr from an IPAddr.
    #
    # @param address [IPAddr]
    # @param mask [Integer, String] a netmask or prefix length
    # @param family [Integer, Nil]
    # @return [IPAddr]
    def self.from_ipaddr(address, prefix_length, family: self::FAMILY)
      address = specialize(address)
      new(address.to_i, family).mask(prefix_length || address.prefix_length)
    end

    # Create an IPAddr from a String.
    #
    # @param address [String]
    # @param mask [Integer, String] a netmask or prefix length
    # @param family [Integer, Nil]
    # @return [IPAddr]
    def self.from_string(address, mask = nil, family: self::FAMILY)
      if mask
        new(address, family).mask(mask)
      else
        new(address, family)
      end
    end

    # Convert an object to a prefix length.
    #
    # @param mask [Integer, String]
    # @param family [Integer, Nil]
    # @return [Integer]
    def self.object_to_prefix_length(mask, family = self::FAMILY)
      case mask
      when Integer
        integer_to_prefix_length(mask, family)
      when String
        string_to_prefix_length(mask, family)
      when IPAddr
        ipaddr_to_prefix_length(mask, family)
      else
        raise ArgumentError, "Can't convert #{mask.class} to prefix length"
      end
    end

    # Convert an integer to a prefix length.
    #
    # If the integer is within the range of possible prefix lengths, returns the
    # same integer. Otherwise it assumes that the given integer is the integer
    # representation of a netmask.
    #
    # Returns nil if the integer can't be converted.
    #
    # @param mask [Integer]
    # @return [Integer]
    def self.integer_to_prefix_length(mask, family = self::FAMILY)
      if valid_prefix_length?(mask)
        mask
      else
        NETMASK_TO_PREFIX_LENGTH[family][mask] ||
          (raise ArgumentError, "Can't convert #{mask} to prefix length")
      end
    end

    # Convert a netmask represented as an IPAddr to a prefix length.
    #
    # Returns nil if the IPAddr can't be converted.
    #
    # @param mask [IPAddr]
    # @return [Integer]
    def self.ipaddr_to_prefix_length(mask, family = self::FAMILY)
      NETMASK_TO_PREFIX_LENGTH[family][mask.to_i]
    end

    # Convert a string to a prefix length.
    #
    # Accepts the decimal representations of integers as well as netmasks in
    # dotted quad notation.
    #
    # Returns nil if the string can't be converted.
    #
    # @param mask [String]
    # @return [Integer]
    def self.string_to_prefix_length(mask, family = self::FAMILY)
      if mask =~ /^\d+$/
        integer_to_prefix_length(mask.to_i, family)
      else
        NETMASK_TO_PREFIX_LENGTH[family][new(mask).to_i]
      end
    end

    # Return true if the given number is a valid prefix length, false otherwise.
    #
    # @param prefix_length [Integer]
    # @return [Boolean]
    def self.valid_prefix_length?(prefix_length, family: self::FAMILY)
      0 <= prefix_length && prefix_length <= FAMILY_TO_BIT_LENGTH[family]
    end

    # Convert the given string to an IPAddr subclass.
    #
    # @param address [String] the string to convert
    # @return [IPAddr::V4, IPAddr::V6, IPAddr::EUI48]
    def self.parse(address)
      specialize IPAddr.new(address)
    end

    # Return the given address as an instance of a class specific to
    # its address family.
    #
    # @param address [IPAddr] the address to convert
    # @return [IPAddr::V4, IPAddr::V6, IPAddr::EUI48]
    def self.specialize(address)
      return address unless address.class == IPAddr
      case address.family
      when Family::IPV4
        IPAddr::V4[address.to_i, address.instance_variable_get(:@mask_addr)]
      when Family::IPV6
        IPAddr::V6[address.to_i, address.instance_variable_get(:@mask_addr)]
      when Family::EUI48
        IPAddr::MAC[address.to_i, address.instance_variable_get(:@mask_addr)]
      end
    end

    def self.specialize_constants(family)
      const_set(:FAMILY, family)
      const_set(:BIT_LENGTH, FAMILY_TO_BIT_LENGTH.fetch(self::FAMILY))
      const_set(:NETMASK_TO_PREFIX_LENGTH,
                NETMASK_TO_PREFIX_LENGTH.fetch(self::FAMILY))
      const_set(:PREFIX_LENGTH_TO_NETMASK,
                PREFIX_LENGTH_TO_NETMASK.fetch(self::FAMILY))
    end

    def address_family_bit_length
      self.class::BIT_LENGTH
    end

    def network?
      prefix_length < self.class::BIT_LENGTH
    end

    def prefix_length
      self.class::NETMASK_TO_PREFIX_LENGTH[mask_addr]
    end
  end

  class V4 < Base
    specialize_constants Family::IPV4
  end

  class V6 < Base
    specialize_constants Family::IPV6
  end

  class MAC < Base
    specialize_constants Family::EUI48
  end
end
