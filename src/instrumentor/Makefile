all: clean instrument move

instrument: 
		clang++ -g -c *.cc
		ar rcs libinstrumentor.a *.o

move:
		mv libinstrumentor.a ../../bin/

clean:
		rm -f *.o entry trace