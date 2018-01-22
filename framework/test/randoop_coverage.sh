#!/usr/bin/env bash
################################################################################
#
# This script generates coverage data for Randoop generated tests over the defects4j suite.
# An optional first agument will replace the default project list.
# An optional second agument will replace the default bid list.
#
################################################################################
# Import helper subroutines and variables, and init Defects4J
source test.include
init

# master coverage file
master_coverage=$TMP_DIR/coverage

# Directory for Randoop test suites
randoop_dir=$TMP_DIR/randoop

if [ -z "$1" ] ; then
# Generate tests for all projects
    projects=( Chart Closure Lang Math Mockito Time )
# Generate tests for all bids
    bids=( 1 2 3 4 5 )
else
# Generate tests for supplied project list
    projects=( $1 )
    if [ -z "$2" ] ; then
# Generate tests for all bids
        bids=( 1 2 3 4 5 )
    else
# Generate tests for supplied bid list
        bids=( $2 )
    fi
fi

echo "Projects: ${projects[@]}"
echo "Bids: ${bids[@]}"

# We want the 'fixed' version of the sample.
type=f

# Test suite source and number
suite_src=randoop
suite_num=1

# probably should be a flag whether or not to keep existing data for cumlative run(s)
#rm -f $master_coverage

for pid in "${projects[@]}"; do
    for bid in "${bids[@]}"; do
        vid=${bid}$type

        # Run Randoop
        run_randoop.pl -p $pid -v $vid -n 1 -o $randoop_dir -b 100 || die "run Randoop on $pid-$vid"
    done

    suite_dir=$randoop_dir/$pid/$suite_src/$suite_num

    # Run generated test suite and determine code coverage
    test_coverage $pid $suite_dir 1

    cat $TMP_DIR/result_db/coverage >> $master_coverage

done

# delete tmp file directory
rm -rf $randoop_dir
