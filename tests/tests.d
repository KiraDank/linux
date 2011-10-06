##################################################################
# These tests are designed to validate core functionality in dtrace
# on the installed operating system, such as bad address handling,
# and various probe functions. We dont really care about the output -
# other than some form of forward progress.
##################################################################
name: systrace-stringof-bad
note:
	20110329 Validate pgfault handler intercepts bad addresses on
	the bogus value from a return
d:
	BEGIN {
	cnt = 0;
	tstart = timestamp;
	}
	syscall::open*:
	{
		this->pid = pid;
		this->ppid = ppid;
		this->execname = execname;
		this->arg0 = stringof(arg0);
		cnt++;
	}
	tick-1ms /timestamp - tstart > 5 * 1000 * 1000 * 1000 / {exit(0);}
	tick-1s { printf("count so far: %d", cnt); }
	tick-5s { exit(0); }

##################################################################
name: systrace-stringof-bad2
note:
	Use some arg to generate a page fault - systrace-stringof-bad
	may not generate a page fault depending on the value of arg0
	when returning from the function.
d:
	BEGIN {
		cnt = 0;
		tstart = timestamp;
	}
	syscall::open*: {
		this->pid = pid;
		this->ppid = ppid;
		this->execname = execname;
		this->arg0 = stringof(arg0);
		this->arg1 = stringof(arg1);
		this->arg2 = stringof(arg2);
		cnt++;
	}
	syscall::open*: /timestamp - tstart > 5 * 1000 * 1000 * 1000 / {exit(0);}
	tick-1ms /timestamp - tstart > 5 * 1000 * 1000 * 1000 / {exit(0);}
	tick-1s { printf("count so far: %d", cnt); }
	tick-5s { exit(0); }

##################################################################
name: systrace-stringof-bad3
note:
	Be more dastardly trying to trigger a fault in dtrace_getarg -
	just do stringof any of the args of any syscalls.
d:
	BEGIN {
		cnt = 0;
		tstart = timestamp;
	}
	syscall::: {
		this->pid = pid;
		this->ppid = ppid;
		this->execname = execname;
		this->arg0 = stringof(arg0);
		this->arg1 = stringof(arg1);
		this->arg2 = stringof(arg2);
		cnt++;
	}
	syscall::: /timestamp - tstart > 5 * 1000 * 1000 * 1000 / {exit(0);}
	tick-1ms /timestamp - tstart > 5 * 1000 * 1000 * 1000 / {exit(0);}
	tick-1s { printf("count so far: %d", cnt); }
	tick-5s { exit(0); }
##################################################################
name: high-profile1
note:
	Lots of ticks to try and induce interrupt stacking/xcall
	issues.
d:
	BEGIN {
		cnt = 0;
	}
	syscall::: {
		this->pid = pid;
		this->ppid = ppid;
		this->execname = execname;
		this->arg0 = stringof(arg0);
		this->arg1 = stringof(arg1);
		this->arg2 = stringof(arg2);
		cnt++;
	}
	syscall::: /timestamp - tstart > 5 * 1000 * 1000 * 1000 / {exit(0);}
	tick-5000 { }
	tick-1s { printf("count so far: %d", cnt); }
	tick-5s { exit(0); }
##################################################################
name: high-profile2
note:
	Lots of ticks but no probes on syscalls.
	issues.
d:
	BEGIN {
		cnt = 0;
	}
	tick-5000 { cnt++; }
	tick-1s { printf("count so far: %d", cnt); }
	tick-10s { exit(0); }
##################################################################
name: fbt-a
note: Do stuff to measure fbt heavy duty access.
d:
	BEGIN {
		tstart = timestamp;
	}
	fbt::a*:
	{
	cnt++;
	}
	tick-1ms /timestamp - tstart > 5 * 1000 * 1000 * 1000 / {exit(0);}
	tick-1s { printf("count so far: %d", cnt); }
	tick-5s { exit(0); }

##################################################################
name: fbt-abc
note: Do more stuff to measure fbt heavy duty access.
d:
	fbt::a*:
	{
	cnt++;
	}
	tick-1s { printf("count so far: %d", cnt); }
	tick-10s { exit(0); }
##################################################################
name: io-1
note: check io provider isnt causing page faults.
d:
	BEGIN {
		tstart = timestamp;
	}
	io::: { cnt++;}
	tick-1ms /timestamp - tstart > 5 * 1000 * 1000 * 1000 / {exit(0);}
	tick-1s { printf("count so far: %d", cnt); }
	tick-5s { exit(0); }

##################################################################
name: execname-1
note: Simple use of execname
d:
	BEGIN {
		tstart = timestamp;
	}
	syscall::open*:entry { 
		cnt++;
		printf("%s",execname);
	}
	tick-1ms /timestamp - tstart > 5 * 1000 * 1000 * 1000 / {exit(0);}
	tick-5s { exit(0); }
##################################################################
name: copyinstr-1
note: Validate copyinstr isnt generating badaddr messages
d:
	BEGIN {
		tstart = timestamp;
	}
	syscall::open*:entry { 
		cnt++;
		printf("%s %s",execname,copyinstr(arg0)); 
	}
	tick-1ms /timestamp - tstart > 5 * 1000 * 1000 * 1000 / {exit(0);}
	tick-5s { exit(0); }
##################################################################
name: badptr-1
note: Simple badptr test (thanks Nigel Smith)
d:
	BEGIN
	{
	        x = (int *)NULL;
	        y = *x;
	        trace(y);
		exit(0);
	}
	tick-1s { exit(0); }
##################################################################
name: profile-1
note: Check we dont lose a rare timer in the midst of lots of timers.
d:
	int cnt;
	tick-1s { 
		printf("got %d * 1mS ticks\n", cnt);
		exit(0); 
		}
	tick-1ms { cnt++; }
##################################################################
name: profile-2
note: Check we dont lose a rare timer in the midst of lots of timers.
d:
	int cnt;
	tick-1s { 
		printf("got %d * tick-5000 ticks\n", cnt);
		exit(0); 
		}
	tick-5000 { cnt++; }
##################################################################
name: profile-3
note: Check we dont lose a rare timer in the midst of lots of timers.
d:
	int cnt_1ms, cnt_1s;
	tick-1ms { cnt_1ms++; } 
	tick-1s { cnt_1s++; 
		printf("got %d + %d\n", cnt_1ms, cnt_1s);
		}
	tick-5s { 
		printf("the end: got %d + %d\n", cnt_1ms, cnt_1s);
		exit(0); 
		}
##################################################################
name: profile-4
note: Check we dont lose a rare timer in the midst of lots of timers.
d:
	int cnt_1ms, cnt_1s;
	fbt::a*: {}
	tick-1ms { cnt_1ms++; } 
	tick-1s { cnt_1s++; 
		printf("got %d + %d\n", cnt_1ms, cnt_1s);
		}
	tick-5s { 
		printf("the end: got %d + %d\n", cnt_1ms, cnt_1s);
		exit(0); 
		}
##################################################################
name: quantize-1
note: Some random quantize invocations
d:
	syscall:::entry { self->t = timestamp; }
	syscall:::return { 
		@s[probefunc] = quantize(timestamp - self->t); 
		self->t = 0;
		}
	tick-5s { 
		exit(0); 
		}
##################################################################
name: quantize-2
note: Some random quantize invocations
d:
	syscall:::entry { self->t = timestamp; }
	syscall:::return { 
		@s[probefunc] = lquantize(timestamp - self->t, 0, 100000, 200); 
		self->t = 0;
		}
	tick-5s { 
		exit(0); 
		}

##################################################################
name: BEGIN-fbt:a-exec-time
note: Test from Nigel Smith
d:
	fbt:kernel:a*: {} 
	dtrace:::BEGIN { exit(0); }