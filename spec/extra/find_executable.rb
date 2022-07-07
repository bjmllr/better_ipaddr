# -*- coding: us-ascii -*-
# frozen_string_literal: true

# Copyright (c) 2002 Hajimu UMEMOTO <ume@mahoroba.org>
# Copyright (c) 2007-2017 Akinori MUSHA <knu@iDaemons.org>

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
# notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.

# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

require "rbconfig"

module EnvUtil
  def find_executable(cmd, *args)
    exts = RbConfig::CONFIG["EXECUTABLE_EXTS"].split | [RbConfig::CONFIG["EXEEXT"]]
    ENV["PATH"].split(File::PATH_SEPARATOR).each do |path|
      next if path.empty?
      path = File.join(path, cmd)
      exts.each do |ext|
        cmdline = [path + ext, *args]
        begin
          return cmdline if yield(IO.popen(cmdline, "r", err: [:child, :out], &:read))
        rescue
          next
        end
      end
    end
    nil
  end
  module_function :find_executable
end
