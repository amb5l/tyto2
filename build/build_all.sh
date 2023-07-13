# do a clean build of all designs
# TODO: add Linux support

if [[ "$OSTYPE" != "msys"* ]]; then
    @echo "This script currently supports Windows/MSYS2 only"; exit 1
fi

# put MSYS2 binaries at the front of the path
if [ -z "$MSYS2" ]; then echo "MSYS2 not defined"; exit 1; fi
PATH=$MSYS2/usr/bin:$PATH

set -o errexit

# check for executables
if [ -z $(type -P vivado) ]; then echo "Vivado not in path"; exit 1; fi
if [ -z $(type -P xsct) ]; then echo "Vitis not in path"; exit 1; fi
if [ -z $(type -P quartus_sh) ]; then echo "Quartus not in path"; exit 1; fi

# build array of directories by searching for makefiles
designs=( \
	'ddr3_test' \
	'hdmi_idbg' \
	'hdmi_io' \
	'hdmi_tpg' \
	'mb_cb' \
	'mb_cb_ps2' \
	'mb_fb' \
	'np6532_poc' \
	'tmds_cap' \
	)
makefiles=($(find ${designs[@]} -maxdepth 2 -name makefile -type f))
dirs=()
for makefile in ${makefiles[@]}; do
	dirs+=($(dirname $makefile))
done
base_dir=$(pwd)

# spawn all builds
printf "\nspawning builds...\n"
num_builds=0
for dir in ${dirs[@]}; do
	# VIVADO_JOBS=1 reduces/eliminates Vivado hang on exit (following wait_on_run)
    echo "cd $(cygpath -a -w $dir) & del *.bit *.sof"
	echo "start cmd.exe /C \"pwd & make clean & make VIVADO_JOBS=1 & if exist *.bit exit & if exist *.sof exit & pause\""
	cd $base_dir
	num_builds=$((num_builds+1))
done > build_all.bat

exit 0

# wait for all builds to finish
printf "\nwaiting for %d builds...\n" $num_builds
finished=0
interval=5
start_time=$(date +%s)
next=$(( $interval+$start_time ))
while (( $finished != $num_builds ))
do
	while (( $(date +%s) < next )) ; do sleep 1 ; done
	finished=0
	for dir in ${dirs[@]}; do
		if compgen -G "${dir}/*.bit" > /dev/null || \
		   compgen -G "${dir}/*.sof" > /dev/null
		then
			finished=$(( $finished+1 ))
		fi
	done
	now=$(date +%s)
	printf "time: %ds   finished: %d    \r" $(( $now-$start_time )) $finished
	next=$(( $now+$interval ))
done
printf "\nall finished\n\n"

# check results
failures=0
for dir in ${dirs[@]}; do
	cd $dir
	bin=$(find . \( -name '*.bit' -or -name '*.sof' \) -type f)
	if [ -z $bin ]; then
		printf "failed: %s\n" $dir
		failures=$((failures+1))
	fi
	cd $base_dir
done
if (( failures )); then
	printf "%d failures\n" $failures
	exit 1
else
	printf "SUCCESS\n"
fi
