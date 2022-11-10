# do a clean build of all designs
# TODO: add Linux support

# workaround for Xilinx GNU tool issues
alias sleep="/usr/bin/sleep"

set -o errexit

# check for executables
printf "\nChecking Vivado...\n"
cmd.exe /C "vivado -version"
printf "\nChecking Vitis...\n"
cmd.exe /C "xsct -eval \"puts [version]\""
printf "\nChecking Quartus...\n"
cmd.exe /C "quartus_sh --version"

# build array of directories by searching for makefiles
designs=( \
	'ddr3_test' \
	'hdmi_tpg' \
	'np6532_poc' \
	)
makefiles=($(find ${designs[@]} -name makefile -type f))
dirs=()
for makefile in ${makefiles[@]}; do
	dirs+=($(dirname $makefile))
done
base_dir=$(pwd)

# spawn all builds
printf "\nspawning builds...\n"
num_builds=0
for dir in ${dirs[@]}; do
	cd $dir
	echo $(pwd)
	rm -f finished
	# VIVADO_JOBS=1 reduces/eliminates Vivado hang on exit (following wait_on_run)
	cmd.exe /C "start cmd.exe /C \"pwd & make clean & rm -f *.bit & rm -f *.sof & set VIVADO_JOBS=1 & make & touch finished & if exist *.bit exit & if exist *.sof exit & pause\""
	cd $base_dir
	num_builds=$((num_builds+1))
done

# wait for all builds to finish
printf "\nwaiting for %d builds...\n" $num_builds
finished=0
interval=5
start_time=$(date +%s)
next=$(( $interval+$start_time ))
while (( $finished != $num_builds ))
do
	while (( $(date +%s) < next )) ; do sleep 1 ; done
	finished=$(( "$(wc -w <<< $(find . -name finished -type f))" ))
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
