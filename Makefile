EXEC=leapfrog
all: $(EXEC)
leapfrog:
	nitc leapfrog_curses.nit --cc-lib-name curses
