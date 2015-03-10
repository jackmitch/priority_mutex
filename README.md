# priority_mutex [![Build Status](https://secure.travis-ci.org/mikejarema/priority_mutex.png)](http://travis-ci.org/mikejarema/priority_mutex)

This gem implements a mutex which allows access to a shared resource as determined by a priority set by each requesting thread.

Using a PriorityMutex, you can now allow a high priority thread to "jump in line" for a mutex ahead of other lower priority threads. Note, this does not preempt the resource from a thread which is currently using the resource.


## License & Notes

The MIT License - Copyright (c) 2012 [Mike Jarema](http://mikejarema.com)
