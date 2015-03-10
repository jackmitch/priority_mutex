require 'priority_mutex'

describe 'PriorityMutex' do

  it 'should order, by priority, the execution of multiple competing threads' do
    n = 1000
    completion_order = []
    threads = []
    range = 0..n
    pm = PriorityMutex.new

    q = Queue.new # use to start the processing, inspired by http://stackoverflow.com/a/23767859/1001980
    active_threads = 0
    counter_mutex = Mutex.new

    # Thread 0 is the "pace car", it will execute first so ignore it in the ordering

    range.each do |i|
      t = Thread.new do
        if i.zero?
          pm.synchronize do
            q.deq
            puts "Starting..."
          end
        else
          sleep(rand * 0.1 + 0.1) # Attempt to randomize order of execution
          counter_mutex.synchronize do
            active_threads += 1
            if active_threads == n
              puts "Initialized..."
              q.enq(:go)
            end
          end
          pm.synchronize(i) { completion_order << i }
        end
      end

      threads << t
    end
    threads.each &:join

    expect(completion_order).to eq(range.to_a[1..-1].reverse) # Ignore thread 0
  end

end
