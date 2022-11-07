# do a clean build of all designs
# TODO: add Linux support

# workarounds for Xilinx GNU tool issues
SLEEP=/usr/bin/sleep

set -o errexit

# incomplete designs
exlusions=("bpp_digilent_nexys_video" "bpp_qmtech_wukong")

dirs=$(find . -maxdepth 2 -mindepth 2 -type d)
base_dir=$(pwd)
find . \( -name 'finished' -or -name '*.bit' -or -name '*.sof' \) -type f -exec rm -f {} +

# check for executables
printf "\nChecking Vivado...\n"
cmd.exe /C "vivado -version"
printf "\nChecking Vitis...\n"
cmd.exe /C "xsct -eval \"puts [version]\""
printf "\nChecking Quartus...\n"
cmd.exe /C "quartus_sh --version"

# spawn all builds
printf "\nspawning builds...\n"
num_builds=0
for dir in $dirs; do
	if [[ ! " ${exlusions[*]} " =~ " $(basename ${dir}) " ]]; then
		cd $dir
		cmd.exe /C "start cmd.exe /C \"make clean & make 1> make.log 2>&1 & touch finished\""
		cd $base_dir
		num_builds=$((num_builds+1))
	fi;
done

# wait for all builds to finish
printf "\nwaiting for %d builds...\n" $num_builds
finished=0
interval=5
start_time=$(date +%s)
next=$(( $interval+$start_time ))
while (( $finished != $num_builds ))
do
	while (( $(date +%s) < next )) ; do $SLEEP 1 ; done
	finished=$(( "$(wc -w <<< $(find . -name finished -type f))" ))
	now=$(date +%s)
	printf "time: %ds   finished: %d    \r" $(( $now-$start_time )) $finished
	next=$(( $now+$interval ))
done
printf "\nall finished\n\n" $count

# check results
failures=0
for dir in $dirs; do
	if [[ ! " ${exlusions[*]} " =~ " $(basename ${dir}) " ]]; then
		cd $dir
		bin=$(find . \( -name '*.bit' -or -name '*.sof' \) -type f)
		if [ -z $bin ]; then
			printf "failed: %s\n" $dir
			failures=$((failures+1))
		fi
		cd $base_dir
	fi;
done
if (( failures )); then
	printf "%d failures\n" $failures
	exit 1
else
	printf "SUCCESS\n"
fi
