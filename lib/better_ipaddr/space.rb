require "ipaddr"
require "better_ipaddr/classes"

module BetterIpaddr
  # Address space utilities
  class Space
    include Enumerable

    attr_reader :networks, :space, :family

    def initialize(networks, space: nil, family: nil)
      @family = family || infer_address_family(space, *networks)
      @networks = networks.map { |network| import(network) }.sort
      return unless space
      @space = space
      outlier = @networks.find { |net| !@space.cover?(net) }
      return unless outlier
      raise ArgumentError, "Address space #{@space.inspect} does not cover "\
                           "network #{outlier.inspect}"
    end

    def +(other)
      self.class.new(networks + other.networks, family: family)
    end

    def ==(other)
      networks == other.networks
    end

    def each
      if block_given?
        networks.each do |network|
          yield network
        end
      else
        networks.each
      end
    end

    def find_by_minimum_size(size)
      find_all { |net| net.size >= size }.min_by(&:prefix_length)
    end

    def find_by_minimum_prefix_length(length)
      find_all { |net| net.prefix_length >= length }.min_by(&:prefix_length)
    end

    def gaps
      return export([space]) if space && networks.empty?
      gap_networks = if space
                       gaps_before + gaps_between + gaps_after
                     else
                       gaps_between
                     end
      self.class.new(gap_networks, family: family)
    end

    def summarize
      out = []
      networks.each do |network|
        summary = network.summarize_with(out.last)
        if summary
          out[-1] = summary
          summarize_backtrack(out)
        else
          out << network
        end
      end
      export(out)
    end

    def summarize_backtrack(list)
      loop do
        break unless list.size >= 2
        summary = list[-1].summarize_with(list[-2])
        break unless summary
        list.pop 2
        list << summary
      end
    end

    def with_space(space)
      export(networks, space: space)
    end

    private

    def import(network)
      case network
      when String, Numeric
        IPAddr[network, family]
      else
        network
      end
    end

    def infer_address_family(*networks)
      example = networks.find { |net| net.respond_to?(:family) }
      return example.family if example
      raise "Unable to infer address family"
    end

    def export(new_networks, space: nil)
      self.class.new(new_networks, space: space, family: family)
    end

    def gaps_after
      export([networks.last.last, space.last + 1]).gaps
    end

    def gaps_before
      export([space.first - 1, networks.first.first]).gaps
    end

    def gaps_between
      gap_networks = []
      summarize.each_cons(2) do |a, b|
        gap_networks.concat(subnets_between(a, b))
      end
      export(gap_networks)
    end

    def subnets_between(before, after)
      subnets = []
      candidate = before.last + 1
      while candidate < after
        candidate = max_supernet_between(before, after, candidate)
        break unless candidate
        subnets << candidate
        candidate = candidate.last + 1
      end
      subnets
    end

    def max_supernet_between(before, after, start)
      next_candidate = start
      until next_candidate.overlap?(before) || next_candidate.overlap?(after)
        candidate = next_candidate
        next_candidate = next_candidate.grow(1)
      end
      candidate
    end
  end # class Space
end # module BetterIpaddr
