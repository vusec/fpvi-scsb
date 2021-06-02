all:
	+$(MAKE) -C common
	+$(MAKE) -C leakers
	+$(MAKE) -C leak_rate_win_size
	+$(MAKE) -C fp_reverse_engineering
