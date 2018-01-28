require "spec_helper"
require "better_ipaddr"
require "better_ipaddr/kernel_method"

describe BetterIpaddr do
  it "has a version number" do
    refute_nil ::BetterIpaddr::VERSION
  end

  it "allows instantiation of specialist IPAddr objects" do
    addr = IPAddr.new("1.0.0.1")
    assert_equal IPAddr::V4[addr.to_i], addr
    assert_equal IPAddr::Base.specialize(addr).class, IPAddr::V4
  end

  it "allows instantiation of specialist IPAddr objects from a string" do
    assert_equal IPAddr::V4, IPAddr::Base.parse("1.0.0.1").class
    assert_equal IPAddr::V6, IPAddr::Base.parse("::1").class
  end

  it "allows instantiation of IPAddrs using various formats" do
    assert_equal IPAddr::V4["1.0.0.0/24"],
                 IPAddr::V4["1.0.0.0", IPAddr::V4["255.255.255.0"].to_i]

    assert_equal IPAddr::V4["1.0.0.0/24"],
                 IPAddr::V4["1.0.0.0", IPAddr::V4["255.255.255.0"]]

    assert_equal IPAddr::V4["1.0.0.0/24"],
                 IPAddr::V4["1.0.0.0", "255.255.255.0"]

    assert_equal IPAddr::V4["1.0.0.0/24"],
                 IPAddr::V4["1.0.0.0", "24"]

    assert_equal IPAddr::V4["1.0.0.0/24"],
                 IPAddr::V4["1.0.0.0", 24]

    assert_equal IPAddr::V4["1.0.0.0/24"],
                 IPAddr::V4[IPAddr.new("1.0.0.0/24")]
  end

  it "allows instantiation of IPAddrs using existing IPAddrs" do
    addr = IPAddr::V4['1.0.0.0/1']
    assert_equal IPAddr::V4[addr], addr
  end

  it "can convert various types of objects to IPAddr" do
    assert_equal IPAddr::V4["1.0.0.0"], IPAddr("1.0.0.0")
    assert_equal IPAddr::V4["0.0.0.1"], IPAddr(1)

    assert_equal IPAddr::V6["::1"], IPAddr("::1")
    assert_equal IPAddr::V6["::"], IPAddr("::")
    assert_equal IPAddr::V6["::1000:0:0"], IPAddr(0x1000_0000_0000)

    assert_nil IPAddr(nil)
    assert_nil IPAddr("1.0.0")
    assert_nil IPAddr("1.0.0.256")
    assert_nil IPAddr(-1)
  end

  it "round trips ipv4 with strings" do
    addr = "1.0.0.0/24"
    assert_equal addr, IPAddr::V4[addr].cidr
  end

  it "round trips ipv4 prefix lengths with CIDR strings" do
    assert_equal 24, IPAddr::V4["1.0.0.0/24"].prefix_length
  end

  it "reduces ipv4 network addresses" do
    addr = "1.0.0.1/24"
    refute_equal addr, IPAddr::V4[addr].cidr
  end

  it "round trips ipv4 with integers" do
    addr = IPAddr::V4["1.0.0.1"].to_i
    assert_equal addr, IPAddr::V4[addr].to_i
  end

  it "calculates ipv4 offsets" do
    assert_equal IPAddr::V4["1.0.0.1"] + 1, IPAddr::V4["1.0.0.2"]
    assert_equal IPAddr::V4["1.0.0.1"] - 1, IPAddr::V4["1.0.0.0"]
    assert_equal IPAddr::V4["1.0.0.6"] + 3, IPAddr::V4["1.0.0.9"]
    assert_equal IPAddr::V4["1.0.0.6"] - 3, IPAddr::V4["1.0.0.3"]
  end

  it "calculates ipv6 offsets" do
    assert_equal IPAddr::V6["1::1/128"] + 1, IPAddr::V6["1::2/128"]
    assert_equal IPAddr::V6["1::1/128"] - 1, IPAddr::V6["1::0/128"]
    assert_instance_of IPAddr::V6, IPAddr::V6["1::1/128"] + 1
    assert_instance_of IPAddr::V6, IPAddr::V6["1::1/128"] - 1
  end

  it "calculates network sizes" do
    assert_equal 1, IPAddr::V4["1.0.0.1"].size
    assert_equal 256, IPAddr::V4["1.0.0.0/24"].size
    assert_equal 1, IPAddr::V6["::1/128"].size
  end

  it "converts ipv4 networks to ranges" do
    assert_equal((0..255), IPAddr::V4["0.0.0.0/24"].to_range(&:to_i))
    assert_equal((IPAddr::V4["0.0.0.0"]..IPAddr::V4["0.0.0.255"]),
                 IPAddr::V4["0.0.0.0/24"].to_range)
  end

  it "enumerates host addresses within an ipv4 range" do
    host = IPAddr::V4["0.0.0.1"]
    assert_equal [host], host.each.to_a
    assert_equal host, (host.each {})

    net = IPAddr::V4["1.0.0.0/30"]
    assert_equal net.to_a, net.each.to_a
    assert_equal [IPAddr::V4["1.0.0.0"],
                  IPAddr::V4["1.0.0.1"],
                  IPAddr::V4["1.0.0.2"],
                  IPAddr::V4["1.0.0.3"]],
                 net.to_a
  end

  it "returns itself for a zero-offset in a host address" do
    host = IPAddr::V4[1]
    assert_equal host.object_id, host[0].object_id
    refute_equal host.object_id, host[1].object_id
  end

  it "calculates ipv4 broadcast addresses" do
    assert_equal IPAddr::V4["1.0.0.255"], IPAddr::V4["1.0.0.0/24"].broadcast
  end

  it "provides ipv4 netmasks in integer or string form" do
    net = IPAddr::V4["1.0.0.0/24"]
    assert_equal net.mask_addr, IPAddr::V4["255.255.255.0"].to_i
    assert_equal net.netmask, "255.255.255.0"
  end

  it "calculates ipv4 wildcard mask strings" do
    assert_equal IPAddr::V4["1.0.0.0/24"].wildcard, "0.0.0.255"
    assert_equal IPAddr::V6["1::/120"].wildcard,
                 IPAddr::V6["::FF"].base(full: true)
  end

  it "calculates whether an ipv4 network covers another" do
    refute IPAddr::V4["1.0.0.0/24"].cover?(IPAddr::V4["1.0.1.0/24"])
    refute IPAddr::V4["1.0.0.0/24"].cover?(IPAddr::V4["1.0.0.0/23"])
    assert IPAddr::V4["1.0.0.0/24"].cover?(IPAddr::V4["1.0.0.0/25"])
    assert IPAddr::V4["1.0.0.0/24"].cover?(IPAddr::V4["1.0.0.64/26"])
    assert IPAddr::V4["1.0.0.0/24"].cover?(IPAddr::V4["1.0.0.128/25"])
  end

  it "pre-computes ipv4 netmasks" do
    # all possible ipv4 netmasks spelled out here, then converted to integers
    ipv4_netmasks = ["0.0.0.0", "128.0.0.0", "192.0.0.0", "224.0.0.0",
                     "240.0.0.0", "248.0.0.0", "252.0.0.0", "254.0.0.0",
                     "255.0.0.0", "255.128.0.0", "255.192.0.0", "255.224.0.0",
                     "255.240.0.0", "255.248.0.0", "255.252.0.0",
                     "255.254.0.0", "255.255.0.0", "255.255.128.0",
                     "255.255.192.0", "255.255.224.0", "255.255.240.0",
                     "255.255.248.0", "255.255.252.0", "255.255.254.0",
                     "255.255.255.0", "255.255.255.128", "255.255.255.192",
                     "255.255.255.224", "255.255.255.240", "255.255.255.248",
                     "255.255.255.252", "255.255.255.254", "255.255.255.255"]
                    .map { |a| IPAddr::V4[a].to_i }

    assert_equal ipv4_netmasks, IPAddr::V4::PREFIX_LENGTH_TO_NETMASK
  end

  it "compares addresses" do
    assert IPAddr::V4["1.1.1.1"] < IPAddr::V6["::"]
    assert IPAddr::V4[1] == 1
    assert_raises(ArgumentError) { IPAddr::V4[1] <=> 'cow' }
  end

  it "distingushes ipv4 networks from hosts based on prefix length" do
    assert IPAddr::V4["1.0.0.1"].host?
    refute IPAddr::V4["1.0.0.1/31"].host?

    refute IPAddr::V4["1.0.0.1"].network?
    assert IPAddr::V4["1.0.0.1/31"].network?
  end

  it "distinguishes ipv4 addresses based on address and prefix length" do
    assert(IPAddr::V4["1.0.0.1"] == IPAddr::V4["1.0.0.1/32"])
    refute(IPAddr::V4["1.0.0.0/32"] == IPAddr::V4["1.0.0.0/31"])
  end

  # https://bugs.ruby-lang.org/issues/12799
  it "can be tested for inequality against other types" do
    addr = IPAddr::V4["1.1.1.1"]
    refute addr == []
    refute addr == {}
    refute addr == "1.1.1.1"
    refute addr == "1.1.1.1/32"
    refute addr == :"1.1.1.1"

    addr = IPAddr.new("1.1.1.1")
    addr.extend(BetterIpaddr::InstanceMethods)
    refute addr == []
    refute addr == {}
    refute addr == "1.1.1.1"
    refute addr == "1.1.1.1/32"
    refute addr == :"1.1.1.1"
  end

  it "orders ipv4 networks based on address and prefix length" do
    assert(IPAddr::V4["1.0.0.1"] < IPAddr::V4["1.0.0.2/31"])
    assert(IPAddr::V4["1.0.0.1/31"] < IPAddr::V4["1.0.0.1"])
  end

  it "calculates containing networks" do
    assert_equal(IPAddr::V4["1.0.0.0/25"].grow(1), IPAddr::V4["1.0.0.0/24"])
    assert_equal(IPAddr::V4["1.0.0.0/25"].grow(2), IPAddr::V4["1.0.0.0/23"])

    assert_equal IPAddr::V4["1.0.0.0/25"].shrink(1), IPAddr::V4["1.0.0.0/26"]
    assert_equal IPAddr::V4["1.0.0.0/24"].shrink(1), IPAddr::V4["1.0.0.0/25"]
    assert_equal IPAddr::V4["1.0.0.0/24"].shrink(2), IPAddr::V4["1.0.0.0/26"]
  end

  it "identifies network pairs which can be summarized" do
    assert_equal IPAddr::V4["1.0.0.0/23"],
                 IPAddr::V4["1.0.0.0/24"]
      .summarize_with(IPAddr::V4["1.0.1.0/24"])

    assert_nil IPAddr::V4["1.0.2.0/24"]
      .summarize_with(IPAddr::V4["1.0.0.0/24"])

    assert_equal IPAddr::V4["1.0.0.0/24"],
                 IPAddr::V4["1.0.0.0/24"]
      .summarize_with(IPAddr::V4["1.0.0.0/25"])

    assert_equal IPAddr::V4["1.0.0.0/24"],
                 IPAddr::V4["1.0.0.0/25"]
      .summarize_with(IPAddr::V4["1.0.0.0/24"])

    assert_nil IPAddr::V4["1.0.1.0/24"]
      .summarize_with(IPAddr::V4["1.0.2.0/24"])
  end

  it "converts to specialized host classes" do
    assert_equal IPAddr::V6::Host, IPAddr::Base.host_from('::1').class
    assert_equal IPAddr::V6::Host, IPAddr::Base.host_from('::1/48').class
    assert_equal 1, IPAddr::Base.host_from('::1/48').size
    assert_equal 128, IPAddr::Base.host_from('::1/48').prefix_length
  end

  it "produces compressed and uncompressed cidr and base strings" do
    addr = IPAddr('1::/64')

    assert_equal '1::', addr.better_to_s(cidr: false, full: false)
    assert_equal "0001:0000:0000:0000:0000:0000:0000:0000",
                 addr.better_to_s(cidr: false, full: true)
    assert_equal '1::/64', addr.better_to_s(cidr: true, full: false)
    assert_equal "0001:0000:0000:0000:0000:0000:0000:0000/64",
                 addr.better_to_s(cidr: true, full: true)

    assert_equal '1::', addr.to_s(cidr: false, full: false)
    assert_equal "0001:0000:0000:0000:0000:0000:0000:0000",
                 addr.to_s(cidr: false, full: true)
    assert_equal '1::/64', addr.to_s(cidr: true, full: false)
    assert_equal "0001:0000:0000:0000:0000:0000:0000:0000/64",
                 addr.to_s(cidr: true, full: true)

    # honor stdlib defaults
    assert_equal IPAddr.new('1::/64').to_s, addr.better_to_s
    assert_equal IPAddr.new('1::/64').to_s, addr.to_s
  end

  it "exposes its family" do
    assert_equal 2, IPAddr::V4['1.2.3.0/24'].family
    assert_equal 10, IPAddr::V6['1::1/64'].family
  end

  it "exposes the bit length of its family" do
    ipaddr = IPAddr.new('0.0.0.1')
    ipaddr.extend(BetterIpaddr::InstanceMethods)
    assert_equal 32, ipaddr.address_family_bit_length

    ipaddr = IPAddr.new('::')
    ipaddr.extend(BetterIpaddr::InstanceMethods)
    assert_equal 128, ipaddr.address_family_bit_length

    assert_equal 32, IPAddr::V4[1].address_family_bit_length
    assert_equal 128, IPAddr::V6[1].address_family_bit_length
  end

  it "guesses whether it is a host address or not" do
    assert IPAddr::V4[1].host?
    refute IPAddr::V4['1.0.0.0/24'].host?
    assert IPAddr::V6[1].host?
    refute IPAddr::V6['1::/64'].host?
  end
end
