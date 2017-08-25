
# Path to SPIN executable:
SPIN=spin

# C compiler:
CC = gcc

# C compiler flags:
CFLAGS = -O2

# Safety Propery Flags
#F_SAFE= -DSAFETY  # (Depth-First) 
F_SAFE= -DBFS      # (Breadth-First. Returns shortest path.)

# LTL Runtime Flags:
F_LTL= -a -e 

# Note: For SPIN and pan flag descriptions, see:
# 	http://spinroot.com/spin/Man/

# ---------------------------------------------------

all: vp1 vp2 vp3

vp1: vp1.pml
	rm -rf *.trail
	$(SPIN) -a vp1.pml
	$(CC) $(CFLAGS) $(F_SAFE) -o pan pan.c
	./pan

vp2: vp2.pml 
	rm -rf *.trail
	$(SPIN) -a vp2.pml
	$(CC) $(CFLAGS) $(F_SAFE) -o pan pan.c
	./pan

vp3: vp3.pml 
	rm -rf *.trail
	$(SPIN) -a vp3.pml
	$(CC) $(CFLAGS) -o pan pan.c
	./pan $(F_LTL)
    
clean:
	rm -rf pan pan.* *.trail _spin_nvr.tmp
