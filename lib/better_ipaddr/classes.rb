require "better_ipaddr/constants"
require "better_ipaddr/methods"
require "better_ipaddr/host_methods"

class IPAddr
  # An intermediate superclass for all BetterIpaddr classes
  class Base < IPAddr
    include BetterIpaddr::Constants
    include BetterIpaddr::InstanceMethods
    include Comparable
    include Enumerable

    # Create an IPAddr from the given object.
    #
    # Returns nil if the object is of a type that can't be converted to an
    # IPAddr.
    #
    # @param address [Integer, IPAddr, String]
    # @param mask [Integer, IPAddr, String, Nil]
    # @param family [Integer]
    # @param classful [Boolean] see Base.from_string
    # @return [IPAddr, Nil]
    def self.[](address, mask = nil, family: self::FAMILY, classful: false)
      prefix_length = mask && object_to_prefix_length(mask, family)

      case address
      when Integer
        from_integer(address, prefix_length, family: family)
      when IPAddr
        from_ipaddr(address, prefix_length, family: family)
      when String
        from_string(address, prefix_length, family: family, classful: classful)
      end
    end

    # rubocop: disable CyclomaticComplexity

    # Create an IPAddr from the given object, guessing the type of address given
    # based on its type and content.
    #
    # Note that an Integer that corresponds to an IPv4 address will be converted
    # to an IPAddr::V4, even though all such Integers also correspond to valid
    # IPv6 addresses.
    #
    # Returns nil if the object can't be converted based on its type and
    # content.
    #
    # @param address [Integer, IPAddr, String]
    # @param exception [Boolean] If true, then when the given object can't be
    #   converted to an IPAddr, a TypeError will be raise rather than returning
    #   nil.
    # @param classful [Boolean] see Base.from_string
    # @return [IPAddr, Nil]
    def self.from(address, exception: false, classful: false)
      if class_converter?(address)
        return class_convert(address, classful: classful, exception: exception)
      end

      case address
      when IPAddr
        specialize address
      when Regex::IPV4, 0..V4::MAX_INT
        V4[address, classful: classful]
      when Regex::IPV6, 0..V6::MAX_INT
        V6[address]
      end || (
        if exception
          (raise TypeError, "can't convert #{address.inspect} to #{self}")
        end
      )
    end

    # rubocop: enable CyclomaticComplexity

    # A Hash of classes and class names which can be converted to IPAddr::Base
    # subclasses, but which are not necessarily loaded at the same time as this
    # file.
    #
    # Conversion callables for custom classes can be registered here, e.g., with
    # custom class Foo:
    #
    #   IPAddr::Base.class_converters[Foo] = proc { |foo, _| foo.to_ipaddr }
    #
    # The arguments passed to the callable will be the same as the parameters of
    # Kernel#IPAddr.
    #
    # @return [Hash{String, Class => Proc, Method}]
    def self.class_converters
      @class_converters ||= {
        'Resolv::IPv4' => V4.method(:from_string_representable),
        'Resolv::IPv6' => V6.method(:from_string_representable)
      }
    end

    # Return the class_converter for the given object, if one exists.
    #
    # Checks by both class identity and class name so that every class with a
    # converter doesn't need to be loaded for this file to load.
    #
    # @return [Proc, Method, Nil]
    def self.class_converter(address)
      class_converters[address.class] ||= class_converters[address.class.name]
      class_converters[address.class]
    end

    def self.class_converter?(address)
      class_converters.key?(address.class) ||
        class_converters.key?(address.class.name)
    end

    # Convert the given object using its class_converter, if one exists.
    #
    # @return [IPAddr, Nil]
    def self.class_convert(address, mask = nil, classful: nil, exception: false)
      converter = class_converter(address)
      converter && converter.call(
        address,
        mask,
        classful: classful,
        exception: exception
      ) || (
        if exception
          (raise TypeError, "can't convert #{address.inspect} to #{self}")
        end
      )
    end

    # Create an IPAddr host subclass from the given object, guessing the type of
    # address given based on its type and content.
    #
    # Uses .from internally, so the same concerns apply, though the returned
    # object is guaranteed to be of a Host class or nil.
    #
    # @param address [Integer, IPAddr, String]
    # @param exception [Boolean] See IPAddr::Base.from
    # @return [IPAddr::Host, Nil]

    def self.host_from(address, exception: false)
      ip = from(address, exception: exception)
      if ip && ip.ipv4?
        V4::Host[ip]
      elsif ip && ip.ipv6?
        V6::Host[ip]
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
    # @param classful [Boolean] controls the conversion of IPv4 addresses
    #   without a prefix length in CIDR notation. When false, these are assumed
    #   to be host networks (/32). When true, these are assumed to be classful
    #   (rfc791) networks, with an implicit prefix length. Has no effect on IPv6
    #   addresses.
    # @return [IPAddr]
    def self.from_string(
      address,
      mask = nil,
      family: self::FAMILY,
      classful: false
    )
      if mask
        new(address, family).mask(mask)
      elsif !classful || address.include?('/')
        new(address, family)
      else
        ipaddr = new(address, family)
        return ipaddr unless ipaddr.ipv4?
        ipaddr.classful || ipaddr
      end
    end

    # Create an IPAddr from an object that can be converted to a String via
    # #to_s.
    #
    #
    # @param address [#to_s]
    # @param mask [Integer, String] a netmask or prefix length
    # @param family [Integer, Nil]
    # @param classful [Boolean] controls the conversion of IPv4 addresses
    #   without a prefix length in CIDR notation. When false, these are assumed
    #   to be host networks (/32). When true, these are assumed to be classful
    #   (rfc791) networks, with an implicit prefix length. Has no effect on IPv6
    #   addresses.
    # @return [IPAddr]
    def self.from_string_representable(
      address,
      mask = nil,
      family: self::FAMILY,
      classful: false,
      exception: false
    )
      from_string(address.to_s, mask, family: family, classful: classful)
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
      const_set(:MAX_INT, 2**self::BIT_LENGTH - 1)
      const_set(:HOST_NETMASK,
                self::PREFIX_LENGTH_TO_NETMASK.fetch(self::BIT_LENGTH))
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

    def to_s(cidr: false, full: false)
      better_to_s(cidr: cidr, full: full)
    end
  end

  # An IPv4 address, 32 bits
  class V4 < Base
    specialize_constants Family::IPV4

    REGEX = Regex::IPV4

    NETWORK_CLASSES = {
      new('0.0.0.0/1')   =>  8, # A
      new('128.0.0.0/2') => 16, # B
      new('192.0.0.0/3') => 24  # C
    }.freeze

    # If the address falls in one of the address classes defined in rfc791,
    # return a new IPAddr with the appropriate prefix length, otherwise return
    # nil.
    #
    # * Class A: networks of 16,777,216 addresses each,
    #   from 0.0.0.0/8 to 127.0.0.0/8
    # * Class B: networks of 65,537 addresses each,
    #   from 128.0.0.0/16 to 191.255.0.0/16
    # * Class C: networks of 256 addresses each,
    #   from 192.0.0.0/24 to 223.255.255.0/24
    #
    # @return [IPAddr::V4, nil]
    def classful
      prefix_length = classful_prefix_length || return
      mask(prefix_length)
    end

    # If the address falls in one of the address classes defined in rfc791,
    # return the corresponding prefix length, otherwise return nil.
    #
    # @return [Integer, nil]
    def classful_prefix_length
      key = NETWORK_CLASSES.keys.find do |block|
        block.to_range(&:to_i).cover?(to_i)
      end
      NETWORK_CLASSES[key]
    end

    # An IPv4 host address, 32 bits
    class Host < V4
      include BetterIpaddr::HostMethods
    end
  end

  # An IPv6 address, 128 bits
  class V6 < Base
    specialize_constants Family::IPV6

    REGEX = Regex::IPV6

    # An IPv6 host address, 128 bits
    class Host < V6
      include BetterIpaddr::HostMethods
    end
  end

  # A MAC address, 48 bits
  class MAC < Base
    specialize_constants Family::EUI48
  end
end
