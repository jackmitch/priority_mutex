require 'priority_mutex'

describe 'PriorityMutex' do

  it 'should order, by priority, the execution of multiple competing threads' do
    n = 1000
    completion_order = []
    execution_order = []
    threads = []
    range = 0..n
    pm = PriorityMutex.new

    q = Queue.new # use to start the processing, inspired by http://stackoverflow.com/a/23767859/1001980
    active_threads = 0
    counter_mutex = Mutex.new

    # Thread 0 is the "pace car", it will execute first so ignore it in the ordering
    # Additionally thread 0 waits until all other threads have started and are waiting
    # on the PriorityMutex
    range.each do |i|
      t = Thread.new do
        if i.zero?
          pm.synchronize do
            q.deq
            # puts "Starting..."
          end
        else
          sleep(rand * 0.1 + 0.1) # Attempt to randomize order of execution
          counter_mutex.synchronize do
            execution_order << i
            active_threads += 1
            if active_threads == n
              # puts "Initialized..."
              q.enq(:go)
            end
          end
          pm.synchronize(i) { completion_order << i }
        end
      end

      threads << t
    end
    threads.each &:join

    # Ignore thread 0, as above
    expect(completion_order).to eq(range.to_a[1..-1].reverse)

    # Extreme sanity checks
    expect(execution_order).to_not eq(completion_order)
    expect(execution_order.sort).to eq(completion_order.sort)
  end

  it 'should respect the prioritization of requests for the shared resource as they come in' do
    threads = []
    completion_order = []
    pm = PriorityMutex.new

    med_queued_at = nil
    med_executed_at = nil
    high_queued_at = nil
    high_executed_at = nil
    max_queued_at = nil
    max_executed_at = nil

    # So let's pile up 10 low priority threads to run every second
    10.times do
      threads << Thread.new do
        pm.synchronize(1) do
          completion_order << 1
          sleep 0.05
        end
      end
    end

    # Wait a moment then add a medium priority thread, it should run next
    threads << Thread.new do
      sleep 0.125
      med_queued_at = Time.now.to_f
      pm.synchronize(2) do                # medium = priority of 2
        med_executed_at = Time.now.to_f
        completion_order << 2
        sleep 0.05
      end
    end

    # Wait a bit longer then add high and max priority thread, high should preempt medium
    threads << Thread.new do
      sleep 0.22
      high_queued_at = Time.now.to_f
      pm.synchronize(3) do                # high = priority of 3
        high_executed_at = Time.now.to_f
        completion_order << 3
        sleep 0.05
      end
    end
    threads << Thread.new do
      sleep 0.23 # Just after the high thread
      max_queued_at = Time.now.to_f
      pm.synchronize(4) do                # max = priority of 4
        max_executed_at = Time.now.to_f
        completion_order << 4
        sleep 0.05
      end
    end

    threads.each &:join

    expect(med_executed_at - med_queued_at).to be <= (0.05 + 0.01)   # Some tolerance added for overhead
    expect(high_executed_at - high_queued_at).to be <= (0.1 + 0.01)  # Some tolerance added for overhead
    expect(max_executed_at - max_queued_at).to be <= (0.05 + 0.01)   # Some tolerance added for overhead

    expect(completion_order.index(3)).to eq(completion_order.index(4) + 1)
  end

end
