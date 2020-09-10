
all: 
	./tools/image.py > src/bitmap.s
	ca65 -g -o src/main.o src/main.s -I.
	ld65 -C 3ep.cfg -m game.map -Ln game.labels -vm -o game.3ep src/main.o 
	./tools/labelconvert.py game.labels game.sym

clean:
	-rm -r src/*.o *.sym *.map *.labels *.3ep src/bitmap.s


