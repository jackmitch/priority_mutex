describe 'Mutex' do

  it 'should unlock when a Thread is killed' do
    mutex = Mutex.new

    t = Thread.new { mutex.synchronize { sleep 10 } }

    sleep 0.1
    expect(mutex).to be_locked

    sleep 0.1
    Thread.kill(t)

    sleep 0.1
    expect(mutex).to_not be_locked
  end

  it 'should start a waiting thread when an active thread is killed' do
    mutex = Mutex.new
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
