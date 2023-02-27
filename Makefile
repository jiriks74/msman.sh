all:
	cp -r .msman msman
	tar -czf msman-hepler.tar.gz msman
	rm -rf msman

clean:
	rm -rf msman
	rm -f msman-hepler.tar.gz
