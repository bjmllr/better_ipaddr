require "spec_helper"
require "better_ipaddr/space"

module BetterIpaddr
  describe Space do
    it "round-trips arrays" do
      networks = [IPAddr::V4["1.0.0.0/24"], IPAddr::V4["1.0.1.0/24"]]
      space = BetterIpaddr::Space.new(networks)
      assert_equal space.to_a, networks
    end

    it "summarizes sets of networks" do
      networks = [IPAddr::V4["1.0.0.0/24"], IPAddr::V4["1.0.1.0/24"]]
      space = BetterIpaddr::Space.new(networks)
      assert_equal space.summarize.to_a, [IPAddr::V4["1.0.0.0/23"]]
    end

    it "summarizes with backtracking as needed" do
      networks = [IPAddr::V4["1.0.0.0/24"],
                  IPAddr::V4["1.0.1.0/25"],
                  IPAddr::V4["1.0.1.128/26"],
                  IPAddr::V4["1.0.1.192/26"]]
      space = BetterIpaddr::Space.new(networks)
      assert_equal space.summarize.to_a, [IPAddr::V4["1.0.0.0/23"]]
    end

    it "finds gaps between networks" do
      networks = [IPAddr::V4["1.0.1.0/24"], IPAddr::V4["1.0.128.0/17"]]
      unused_space = ["1.0.0.0/24",
                      "1.0.2.0/23",
                      "1.0.4.0/22",
                      "1.0.8.0/21",
                      "1.0.16.0/20",
                      "1.0.32.0/19",
                      "1.0.64.0/18"].map { |a| IPAddr::V4[a] }
      space = BetterIpaddr::Space.new(networks, space: IPAddr::V4["1.0.0.0/16"])
      gaps = BetterIpaddr::Space.new(unused_space)
      assert_equal gaps, space.gaps
      assert_equal space.gaps.find_by_minimum_prefix_length(19).cidr,
                   "1.0.32.0/19"
    end

    it "returns original space as the only gap when the space is empty" do
      networks = []
      unused_space = [IPAddr::V4["1.0.0.0/8"]]
      space = BetterIpaddr::Space.new(networks, space: unused_space.first)
      assert_equal space.gaps, BetterIpaddr::Space.new(unused_space)
    end
  end
end
