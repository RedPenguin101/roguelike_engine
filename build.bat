echo WAITING FOR PDB > ./build/lock.tmp

odin build game -build-mode:dll -out:./build/game.dll -debug -vet

del ./build/lock.tmp

odin build platform -out:./build/run.exe -debug -vet
