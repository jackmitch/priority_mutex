class PriorityMutex < Mutex

  def synchronize(priority)
    super()
  end

end
