from os import listdir, system, remove
from os.path import isfile, join, exists

def main():

    # get the list of trail files in working directory generated by spin
    trailDirs = [f for f in listdir("./") if (isfile(f) and "trail" in f)]
    if len(trailDirs)==0:
        print '\nERROR: Cannot find any trail file. Run "make vp3" first.\n'
        exit()
    nTrails = len(trailDirs) #number of trail files

    unique_phase_arrangements = set()

    # guided simulation output file:
    guidedFileName = "guided.txt"

    # read trail files:
    for i in range(nTrails):
        print "Processing trail "+str(i+1)+" of "+str(nTrails)

        # Run SPIN in guided simulation mode:
        system("spin -t"+str(i+1)+" vp3.pml > "+guidedFileName)
        guidedFile = open(guidedFileName,"r")
        lines = [line for line in guidedFile if line.strip()]

        # Process the output of the guided simulation to get the phasing arrangement info:
        for i in range(len(lines)):
            line = lines[i]
            if len(line)>1 and line.split()[0]=="dp":
                nroutines = 6
                phaseBegins = []
                phaseConcurrent = []

                for r in range(nroutines):
                    line = lines[i+1]
                    phaseBegins.append(int(line.split()[2]))
                    i = i+1
                for r in range(nroutines):
                    line = lines[i+1]
                    phaseConcurrent.append(int(line.split()[2]))
                    i = i+1

                phaseBegins = tuple(phaseBegins)
                phaseConcurrent = tuple(phaseConcurrent)
                unique_phase_arrangements.add(tuple([phaseBegins,phaseConcurrent]))
                break

        remove(guidedFileName)
                
    phaseConfigurations = [ ( sum(uc[0]),                   # total no of phases
                              float(sum(uc[1]))/sum(uc[0]), # concurrency rate
                              uc[0],                        # phase beginnings
                              uc[1]                         # concurrent phase beginnings
                                    ) for uc in unique_phase_arrangements]
    # Sort by concurrency rate:
    phaseConfigurations.sort(key=lambda x: x[1])

    # Print all of the unique safe phasing arrangements:
    print "\nTotal number of unique phase arrangements:", len(phaseConfigurations), "\n"
    for pc in phaseConfigurations:
        print "A:", pc[0], "   B:", pc[1], "   C:", pc[2], "   D:", pc[3]
    print "\nColumns:"
    print " A: (no. of phases)"
    print " B: (no. of concurrent phases)/(no. of phases)"
    print " C: (if C[i]==1, a phase starts at i.th routine)"
    print " D: (if D[i]==1, the phase starting with i.th routine is concurrent)"

if __name__ == "__main__":
    main()