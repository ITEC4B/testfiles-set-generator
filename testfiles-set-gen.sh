#!/bin/sh

# Generate a set of n test files (with random data OR empty)
# By default creates 100 tests files with random data between 0 and 10MB in /home/<user>/TESTS

readonly N_FILES="${1:-100}"             # Number of test files to create. Default=100
readonly FCONTENT="${2:-DATA}"           # EMPTY, DATA
readonly TESTS_DIR="${3:-$HOME/TESTS}"   # Directory where to create test files. Default=/home/<user>/TESTS

readonly RC_FAILED=1

# Test files' name prefix
readonly PREFIX_TEST_FNAME='test-file-'

readonly _1KB=$((1024))
readonly _1MB=$((1024*1024))
readonly _4MB=$((4*$_1MB))
readonly _10MB=$((10*$_1MB))
readonly _100MB=$((100*$_1MB))
readonly _1GB=$((1024*1024*1024))

# Check N_FILES
printf %s "$N_FILES"| grep '^[1-9][0-9]*$' > /dev/null || {
    printf %s\\n "NOT a valid number: $N_FILES"
    exit $RC_FAILED
}

# Create TESTS directory
mkdir -p "$TESTS_DIR" || {
    printf %s\\n "NOT a valid path: $TESTS_DIR"
    exit $RC_FAILED
}


random_num(){
    local N_NUMBERS="${1:-1}"
    local RANGE_TO="${2:-100}"
    local RANGE_FROM="${3:-1}"

    shuf -i $RANGE_FROM-$RANGE_TO -n $N_NUMBERS
}


random_datasize(){
    local RANGE_TO="${1:-$_10MB}"
    local RANGE_FROM="${2:-1}"

    random_num 1 $RANGE_TO $RANGE_FROM
}


case $FCONTENT in

    DATA)
        seq $N_FILES | {
            while read -r current_n
            do
                fdata_size_min=$_4MB; fdata_size_max=$_10MB
                [ $current_n -le $((N_FILES*3/4)) ] && { fdata_size_min=$_1MB; fdata_size_max=$_4MB; }
                [ $current_n -le $((N_FILES*2/4)) ] && { fdata_size_min=$_1KB; fdata_size_max=$_1MB; }
                [ $current_n -le $((N_FILES*1/4)) ] && { fdata_size_min=0; fdata_size_max=$_1KB; }

                fdata_size=$( random_datasize $fdata_size_max $fdata_size_min )

                str_current_n=$( printf %0.${#N_FILES}d $current_n )
                fpath="${TESTS_DIR}"/"${PREFIX_TEST_FNAME}${str_current_n}"

                blocks4KB=$( awk -v _size=$fdata_size 'BEGIN{ printf "%.0f\n", ( _size/4096 )+0.5}' )

                printf %s\\n "Generating $str_current_n/$N_FILES  $fpath  Size: $fdata_size bytes  4KB_Blocks: $blocks4KB"

                cat /dev/random | tr -cd '[:print:]' | tr ' ' '\n' | head -c $fdata_size > "$fpath"
            done
        }
    ;;

    *|EMPTY) 
        seq $N_FILES | {
            while read -r current_n
            do
               str_current_n=$( printf %0.${#N_FILES}d $current_n )
               fpath="${TESTS_DIR}"/"${PREFIX_TEST_FNAME}${str_current_n}"

               printf %s\\n "Generating $str_current_n/$N_FILES  $fpath  Size: 0 bytes"

               > "$TESTS_DIR"/"$PREFIX_TEST_FNAME"${str_current_n}
            done
        }
    ;;
esac
