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

    def self.[](address, mask = nil, family: self::FAMILY)
      case mask
      when Integer
        if 0 <= mask && mask <= FAMILY_TO_BIT_LENGTH[family]
          new(address, family).mask(mask)
        else
          new(address, family).mask(new(mask, family).to_s)
        end
      when String, IPAddr
        new(address, family).mask(mask.to_s)
      else
        new(address, family)
      end
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
