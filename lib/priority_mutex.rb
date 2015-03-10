=begin
  Basically the PQueue manages the incoming requests from thread to access the shared resource,
  and sorting these requests by priority such that the highest priority request gains access.

  The Waiter helper class allows to pause and resume threads based on when the PQueue determines
  they should have access to the shared resource.

  The Waiter's pause/resume impementation is borrowed from http://stackoverflow.com/a/23767859/1001980,
  and the queue is specifically used to preempt any race conditions that may arise from using a
  Mutex, namely if a Waiter is #resume'd before #wait'ing.
=end

require 'pqueue'

class PriorityMutex

  class Waiter
    attr_accessor :priority
    def initialize(priority)
      @priority = priority
      @queue = Queue.new
    end
    def <=>(other)
      self.priority <=> other.priority
    end
    def wait
      @queue.deq
      nil
    end
    def resume
      @queue.enq :go
    end
  end

  def initialize
    @pq = PQueue.new
    @pq_mutex = Mutex.new
    @resource_active = false
  end

  def synchronize(priority = 0)
    wait_for_resource_if_necessary(priority)
    begin
      yield
    ensure
      release_resource rescue nil
    end
  end

  def locked?
    @resource_active || @pq.size > 0
  end

private

  def wait_for_resource_if_necessary(priority)
    waiter = nil

    @pq_mutex.synchronize do
      if @resource_active
        # So we'll need to wait, waiting happens _outside_ of this
        # synchronization block to ensure that
        waiter = Waiter.new(priority)
        @pq.push(waiter)

      else
        @resource_active = true

      end
    end

    if waiter
      waiter.wait
      @pq_mutex.synchronize { @resource_active = true }
    end
  end

  def release_resource
    @pq_mutex.synchronize do
      if next_waiter = @pq.pop
        next_waiter.resume
      else
        @resource_active = false
      end
    end
  end

end
