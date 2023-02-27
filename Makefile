# Simple makefile to create a tarball of the msman helper scripts

all:
	source msman.sh
	source .msman/version.sh
	if [[ $CURRENT_SCRIPT_VERSION == $EXTRA_SCRIPTS_VERSION]]; then
		cp -r .msman msman
		tar -czf msman-hepler.tar.gz msman
		rm -rf msman
	else
		echo "msman.sh and .msman/version.sh are not in sync"
	fi

clean:
	rm -rf msman
	rm -f msman-hepler.tar.gz
