module Acme
  module Distributed
    VERSION = "0.4.0-MASTER".freeze

    # Return extended version info
    def self.versioninfo
      "Acme::Distributed version #{VERSION}"
    end

    # Return copyright information
    def self.copyright
      "This software is put into the Public Domain under the terms of Unlicense\n" +
      "Please refer to https://www.unlicense.org for more details."
    end

  end
end