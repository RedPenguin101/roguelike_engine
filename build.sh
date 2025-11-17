echo "WAITING FOR PDB" > ./build/lock.tmp

odin build game -build-mode:dll -out:./build/game.dll -debug -vet

rm ./build/lock.tmp

odin build platform -out:./build/run -debug -vet
