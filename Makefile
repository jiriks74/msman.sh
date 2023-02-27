# Simple makefile to create a tarball of the msman helper scripts
# Turn off verbose mode
MAKEFLAGS += -s

all:
	CURRENT_SCRIPT_VERSION=`grep "CURRENT_SCRIPT_VERSION=" msman.sh | sed -e "s/CURRENT_SCRIPT_VERSION=//g"`; \
	EXTRA_VERSION=`grep "EXTRA_SCRIPTS_VERSION=" .msman/version.sh | sed -e "s/EXTRA_SCRIPTS_VERSION=//g"`; \
	if [ "$$CURRENT_SCRIPT_VERSION" != "$$EXTRA_VERSION" ]; then \
		echo "ERROR: The version in msman.sh and .msman/version.sh are not the same!"; \
		echo "ERROR: Please make sure they are the same."; \
		exit 1; \
	fi
	rm -rf msman
	mkdir msman
	cp -r .msman msman
	tar -czf msman-helper.tar.gz msman
	rm -rf msman

clean:
	rm -rf msman
	rm -f msman-hepler.tar.gz
