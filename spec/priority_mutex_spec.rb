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
            sleep 1.0
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
          sleep 0.1
        end
      end
    end

    # Wait a moment then add a medium priority thread, it should run next
    threads << Thread.new do
      sleep 0.25
      med_queued_at = Time.now.to_f
      pm.synchronize(2) do                # medium = priority of 2
        med_executed_at = Time.now.to_f
        completion_order << 2
        sleep 0.1
      end
    end

    # Wait a bit longer then add high and max priority thread, high should preempt medium
    threads << Thread.new do
      sleep 0.55
      high_queued_at = Time.now.to_f
      pm.synchronize(3) do                # high = priority of 3
        high_executed_at = Time.now.to_f
        completion_order << 3
        sleep 0.1
      end
    end
    threads << Thread.new do
      sleep 0.56 # Just after the high thread
      max_queued_at = Time.now.to_f
      pm.synchronize(4) do                # max = priority of 4
        max_executed_at = Time.now.to_f
        completion_order << 4
        sleep 0.1
      end
    end

    threads.each &:join

    expect(med_executed_at  - med_queued_at ).to be < 0.1 + 0.05  # one cycle plus small tolerance
    expect(high_executed_at - high_queued_at).to be < 0.2 + 0.05  # two cycles plus small tolerance
    expect(max_executed_at  - max_queued_at ).to be < 0.1 + 0.05  # one cycle plus small tolerance

    expect(completion_order.index(3)).to eq(completion_order.index(4) + 1)
  end

  it 'should know when its locked' do
    threads = []
    pm = PriorityMutex.new

    expect(pm).to_not be_locked

    # So let's pile up 10 low priority threads to run every second
    10.times do
      threads << Thread.new do
        pm.synchronize(1) { sleep 0.05 }
      end
    end

    # The above will run for 0.5 seconds, ensure its locked during that timeframe
    3.times do
      sleep 0.1
      expect(pm).to be_locked
    end

    threads.each &:join

    # After the threads are done, it should be unlocked
    expect(pm).to_not be_locked
  end

  it 'should really not let multiple thread access the shared resource simultaneously' do
    threads = []
    standard_mutex_locked_count = 0

    sm = Mutex.new # "Standard" Mutex
    pm = PriorityMutex.new

    # Basically we hammer the PriorityMutex by creating a bunch of Threads very
    # quickly and rely on a native Mutex to ensure we don't permit multiple threads
    # into the synchronization block at once
    begin
      2000.times do
        threads << Thread.new do
          pm.synchronize(rand(10)) do
            if sm.locked?
              # puts "Uh-oh, mutex was locked"
              standard_mutex_locked_count += 1
            end
            sm.synchronize { sleep 0.001 }
          end
        end
      end

    rescue ThreadError => e
      # puts "Was able to create #{threads.count} threads before failure"

    end

    threads.each &:join

    expect(standard_mutex_locked_count).to eq(0)
  end

  it 'should unlock when a Thread is killed' do
    mutex = PriorityMutex.new

    t = Thread.new { mutex.synchronize { sleep 10 } }

    sleep 0.1
    expect(mutex).to be_locked

    sleep 0.1
    Thread.kill(t)

    sleep 0.1
    expect(mutex).to_not be_locked
  end

  it 'should start a waiting thread when an active thread is killed' do
    mutex = PriorityMutex.new
    t2_finished = false

    t1 = Thread.new { mutex.synchronize { sleep 0.5 } }
    sleep 0.1
    t2 = Thread.new { mutex.synchronize { sleep 0.5; t2_finished = true } }

    sleep 0.1
    Thread.kill(t1)

    [t1, t2].each &:join

    expect(t2_finished).to be true
  end

end
