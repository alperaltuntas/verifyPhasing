# verifyPhasing
Promela models to verify the phasing mechanism of ADCIRC++

## Models:
Description of models to come.

## Building the models:
### Prerequisite:
- GNU make, gcc compiler, Python
- Install SPIN and add SPIN executable to your path. (See http://spinroot.com/spin/whatispin.html)
### Building and running the verification model:
```
$ make vp3
```
### Extracting safe phase configurations:
```
$ python extractPhaseArrangements.py
```
