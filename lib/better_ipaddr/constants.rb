require "socket"

module BetterIpaddr
  module Constants
    # Integer codes representing supported address clases.
    # Reuse values from Socket namespace where possible.
    module Family
      IPV4 = Socket::AF_INET
      IPV6 = Socket::AF_INET6
      EUI48 = 48
      EUI64 = 64
    end

    module Regex
      OCTET = Regexp.union(
        /25[0-5]/,
        /2[0-4][0-9]/,
        /1[0-9][0-9]/,
        /[1-9][0-9]/,
        /[0-9]/
      )

      TRAILING_OCTET = /\.#{OCTET}/

      IPV4_PL = Regexp.union(
        /3[0-2]/,
        /[1-2][0-9]/,
        /[0-9]/
      )

      IPV4 = /\A#{OCTET}#{TRAILING_OCTET}{3}(?:\/#{IPV4_PL})?\z/

      # IPv6 regex adapted from http://stackoverflow.com/a/17871737
      QUAD = /[0-9a-zA-Z]{1,4}/
      LEADING_QUAD = /[0-9a-zA-Z]{1,4}:/
      TRAILING_QUAD = /:[0-9a-zA-Z]{1,4}/

      IPV6_PL = Regexp.union(
        /[0-9]/,
        /[1-9][0-9]/,
        /1[0-1][0-9]/,
        /12[0-8]/
      )

      IPV6_ADDRESS = Regexp.union(
        # full
        /#{LEADING_QUAD}{7,7}#{QUAD}/,

        # zero-compressed
        /::/,
        /#{LEADING_QUAD}{1,7}:/,
        /:#{TRAILING_QUAD}{1,7}/,
        /#{LEADING_QUAD}{1,6}#{TRAILING_QUAD}{1,1}/,
        /#{LEADING_QUAD}{1,5}#{TRAILING_QUAD}{1,2}/,
        /#{LEADING_QUAD}{1,4}#{TRAILING_QUAD}{1,3}/,
        /#{LEADING_QUAD}{1,3}#{TRAILING_QUAD}{1,4}/,
        /#{LEADING_QUAD}{1,2}#{TRAILING_QUAD}{1,5}/,
        /#{LEADING_QUAD}{1,1}#{TRAILING_QUAD}{1,6}}/,

        # IPv4-mapped / -translated
        /::(ffff(:0{1,4}){0,1}:){0,1}#{IPV4}/,

        # IPv4 embedded
        /#{LEADING_QUAD}{1,4}:#{IPV4}/
      )

      IPV6 = /\A#{IPV6_ADDRESS}(?:\/#{IPV6_PL})?\z/
    end

    # Map well known address family names to constants.
    SYMBOL_TO_FAMILY = {
      ipv4: Family::IPV4,
      ipv6: Family::IPV6,
      eui48: Family::EUI48,
      eui64: Family::EUI64,
      mac: Family::EUI48
    }

    # Map each address family to the size of its address space, in bits.
    FAMILY_TO_BIT_LENGTH = {
      Family::IPV4 => 32,
      Family::IPV6 => 128,
      Family::EUI48 => 48,
      Family::EUI64 => 64
    }

    # Map all possible prefix lengths to the corresponding netmasks.
    PREFIX_LENGTH_TO_NETMASK = {}
    FAMILY_TO_BIT_LENGTH.each_pair do |family, size|
      netmasks = []
      (0..size).each do |prefix_length|
        netmasks[prefix_length] = 2**size - 2**(size - prefix_length)
      end
      PREFIX_LENGTH_TO_NETMASK[family] = netmasks
    end

    # Map all possible netmasks to the corresponding prefix lengths.
    NETMASK_TO_PREFIX_LENGTH = {}
    PREFIX_LENGTH_TO_NETMASK.each_pair do |family, hash|
      NETMASK_TO_PREFIX_LENGTH[family] =
        Hash[hash.map.with_index { |e, i| [e, i] }]
    end
  end
end
