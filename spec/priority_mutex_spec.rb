require 'priority_mutex'

describe 'PriorityMutex' do

  # before(:each) do
  #   @m = Mutex.new
  # end

  it 'should order, by priority, the execution of multiple competing threads' do
    order = []
    threads = []
    range = 0..10
    pm = PriorityMutex.new

    # Thread 0 is the "pace car", it will execute first so ignore it in the ordering
    range.each do |i|
      t = Thread.new do
        sleep(rand) unless i.zero? # Attempt to randomize order of execution
        priority = i
        pm.synchronize(priority) do
          sleep 0.1 # "Sleeping" is the protected resource here
          order << i
        end
      end
      threads << t
    end
    threads.each &:join

    expect(order).to eq(range.to_a)
  end

end
