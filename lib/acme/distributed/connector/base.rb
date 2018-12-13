require 'acme/distributed/logger'

require 'acme/distributed/connector_error'

module Acme::Distributed::Connector; end

# This is the base class for fullfillment of ACME authorization requests.
#
# Each authorizer class must derive from this class.
#
class Acme::Distributed::Connector::Base

  def initialize(name, config, options, defaults)
    @logger = Acme::Distributed::Logger.new
    @name = name
    @config = config
    @options = options
    @defaults = defaults || {}
  end

  # The following are dummy methods that raise exceptions. These are the
  # methods that each subclass needs to implement.
  # 
  def connect!(force_reconnect = false)
    raise Acme::Distributed::ConnectorError, "#connect! is not implemented in derived class"
  end

  def disconnect!
    raise Acme::Distributed::ConnectorError, "#disconnect! is not implemented in derived class"
  end

  def create_challenge(challenge_name, challenge_content)
    raise Acme::Distributed::ConnectorError, "#create_challenge is not implemented in derived class"
  end

  def remove_challenge(challenge_name)
    raise Acme::Distributed::ConnectorError, "#remove_challenge is not implemented in derived class"
  end

  def connected?
    raise Acme::Distributed::ConnectorError, "#connected? is not implemented in derived class"
  end
end
