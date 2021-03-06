#! /usr/bin/env ruby
#  encoding: UTF-8
#   <script name>
#
# DESCRIPTION:
#   This plugin uses the /proc file-system to collect open file count metrics, produces
#   Graphite formated output.
#
# OUTPUT:
#   metric data
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: socket
#
# USAGE:
#
# NOTES:
#
# LICENSE:
#   Copyright 2015 Catamorphic, Inc <chefs@sonian.net>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/metric/cli'
require 'socket'

class VMStat < Sensu::Plugin::Metric::CLI::Graphite
  option :scheme,
         description: 'Metric naming scheme, text to prepend to .$parent.$child',
         long: '--scheme SCHEME',
         default: "#{Socket.gethostname}.openfiles"

  def convert_integers(values)
    values.each_with_index do |value, index|
      begin
        converted = Integer(value)
        values[index] = converted
        # #YELLOW
      rescue ArgumentError # rubocop:disable HandleExceptions
      end
    end
    values
  end

  def run
    result = convert_integers(`cat /proc/sys/fs/file-nr`.split(' '))
    timestamp = Time.now.to_i
    metrics = {
      counts: {
        allocated: result[0],
        used: result[1],
        max: result[2],
      },
      percentages: {
        allocated: result[0] / result[2],
        used: result[1] / result[2]
      }
    }
    metrics.each do |parent, children|
      children.each do |child, value|
        output [config[:scheme], parent, child].join('.'), value, timestamp
      end
    end
    ok
  end
end
