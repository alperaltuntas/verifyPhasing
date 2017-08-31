
// --------------------------------------------------------- 
// Part-1: Domain

// Compound Data Type: Domain 
typedef Domain{
  bool phaseCompleted = true;
}

Domain domains[2]; // Array of domains

#define iparent 0
#define ichild 1

// true if called by the parent's process
#define isParent() \
  _pid==1

// --------------------------------------------------------- 
// Part 2: Critical domain quantities

// Global variables representing critical domain quantities' 
// version differences between parent and child
byte eta = 0;	// elevations
byte wd = 0;	// wet/dry states
byte v = 0;	// velocities
byte tau = 0;	// wind parameters

// Modify operator for critical domain quantities
inline write(var){
  printf("writing\n")
  if
  :: isParent() -> var++;
  :: else -> var--;
  fi
}

// Macro to specify a safety property:
#define CHECK_SAFETY assert(var<=threshold)

// Copy operator for critical domain quantities
inline copy(var,threshold){
  printf("copying\n")
  if
  :: isParent() -> skip;
  :: else -> CHECK_SAFETY;
  fi
}

// --------------------------------------------------------- 
// Phasing
#define NR 6  // number of routines called at a timestep.
#define NP_MAX NR // max number of phases. (user input)

byte nr = NR; 
byte dp = 0;  // Phase difference between parent and child

bool phaseBegins[NR]; 		// phaseBegins[i] is true if i.th routine corresponds to a phase beginning
bool phaseConcurrent[NR]; // phaseConcurrent[i] is true if parent can run it while child executes i-1.th phase

// Inline to non-deterministically decide how the timestep is divided 
// into phases. This is done by designating timestep routines non-deterministically
// to be the begginning of a phase

inline determinePhases(){

  byte i = 0;   // routine index
  byte np = 0;  // number of phases

  // determine the remaining phase ends non-deterministically:
  for (i:0..nr-1) {
    if
    :: np<NP_MAX -> phaseBegins[i] = true -> np++;
    :: (i!=0) -> phaseBegins[i] = false;
    fi
  }

  // determine whether the phase beginning with the i.th routine 
  // can be executed by the parent if the previous phase is not 
  // completed by the child yet.
  for (i:0..nr-1) {
    if
    :: phaseBegins[i] ->
        if
        :: phaseConcurrent[i] = true;
        :: phaseConcurrent[i] = false;
        fi
    :: else -> skip
    fi
  }
}


// Inline to check whether the domain is ready to enter into new phase
inline phase_check(domain,i){

  printf("checking for entering the routine %d\n",i);
  if
  ::phaseBegins[i] ->
    if
    :: isParent() ->
       dp==0 && (phaseConcurrent[i] || domains[ichild].phaseCompleted) ->
       atomic{
         dp++;
         domain.phaseCompleted = false;
       }
    :: else ->
       dp>0  && domains[iparent].phaseCompleted ->
       atomic{
         dp--;
         domain.phaseCompleted = false;
       }
    fi
  :: else-> skip;
  fi
  printf("checked for entering the routine %d\n",i);
}

// Inline to notify other domain that the current phase has been completed
inline phase_notify(domain,i){
  if
  :: phaseBegins[(i+1)%NR] ->
        domain.phaseCompleted = true;
  :: else-> skip;
  fi
  printf("notified completion of %d\n",i);
}

// --------------------------------------------------------- 
// Timestepping

// Inline to execute i.th routine of a timestep
inline exec_routine(i){
  if
  :: i==0 -> // Routine 0: Timestep initialization
      write(tau);
      copy(tau,0);
      copy(eta,0);
      copy(v,0);

  :: i==1 -> // Routine 1: GWCE Assembly
      skip;

  :: i==2 -> // Routine 2: GWCE Solver
      write(eta);
      copy(eta,0);

  :: i==3 -> // Routine 3: Wet/Dry Algm (1st half)
      write(eta);
      write(wd);
      copy(wd,1);

  :: i==4 -> // Routine 4: Wet/Dry Algm (2nd half)
      write(wd);
      copy(wd,0);

  :: i==5 -> // Routine 5: Momentum Eqns Solver
      write(v);
      copy(v,0);
  fi
}

// Inline to execute a single timestep
inline exec_step(domain){
  byte i=0;
  for (i:0..nr-1) {
    phase_check(domain,i);
    exec_routine(i)
    phase_notify(domain,i);
  }
}

// Executes an endless timestepping process for a domain
proctype execute(byte domainID){
  do
  :: exec_step(domains[domainID]);
  od
}

// Initial process
init{
  determinePhases();
  atomic{
    run execute(iparent);
    run execute(ichild);
  }
}

