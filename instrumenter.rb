class Instrumenter
  Event = Struct.new(:name, :payload, :result)

  attr_reader :events

  def initialize
    @events = []
  end

  def instrument(name, payload = {})
    # Copy the payload to guard against later modifications to it, and to
    # ensure that all instrumentation code uses the payload passed to the
    # block rather than the one passed to #instrument.
    payload = payload.dup

    result = (yield payload if block_given?)
    @events << Event.new(name, payload, result)
    result
  end

  def clear_all
    @events = []
  end
end
