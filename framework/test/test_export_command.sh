#!/usr/bin/env bash
################################################################################
#
# This script tests the export command.
# By default, executed for all projects.
# Test one or more specific projects by appending "-p" arguments.
# Examples: 
# * Verify Lang:    ./test_export_command.sh -p Lang
# * Verify Lang and Collections: ./test_export_command.sh -p Lang -p Collections
#
################################################################################

HERE=$(cd `dirname $0` && pwd)

# Import helper subroutines and variables, and init Defects4J
source "$HERE/test.include" || exit 1
init

# ------------------------------------------------------------- Common functions

_run_export_command() {
    [ $# -eq 2 ] || die "Usage: ${FUNCNAME[0]} <working directory> <export command>"

    local work_dir="$1"
    local exp_cmp="$2"
    local exp_out=""

    pushd . > /dev/null 2>&1
    cd "$work_dir"
        exp_out=$(defects4j export -p "$exp_cmp")
        if [ $? -ne 0 ]; then
            popd > /dev/null 2>&1
            return 1
        fi
    popd > /dev/null 2>&1

    echo "$exp_out"
    return 0
}

# ------------------------------------------------------------------- Test Cases

test_ExportTestClassesDir() {
    local pid=$1
    local test_dir="$TMP_DIR/test_ExportTestClassesDir"
    rm -rf "$test_dir"; mkdir -p "$test_dir"

    # Iterate over all bugs
    local bids=$(cut -f1 -d',' "$BASE_DIR/framework/projects/$pid/commit-db")
    for bid in $bids; do
        local work_dir="$test_dir/$pid/$bid"
        mkdir -p "$work_dir"

        defects4j checkout -p "$pid" -v "${bid}b" -w "$work_dir" || die "Checkout of $pid-$bid has failed"

        local test_classes_dir=""
        test_classes_dir=$(_run_export_command "$work_dir" "dir.bin.tests")
        if [ $? -ne 0 ]; then
            die "Export command of $pid-$bid has failed"
        fi

        local expected=""
        if [ "$pid" == "Chart" ]; then
            expected="build-tests"
        elif [ "$pid" == "Cli" ]; then
            expected="target/test-classes"
        elif [ "$pid" == "Closure" ]; then
            expected="build/test"
        elif [ "$pid" == "Codec" ]; then
            if [ "$bid" -ge "1" ] && [ "$bid" -le "16" ]; then
                expected="target/tests"
            elif [ "$bid" -ge "17" ] && [ "$bid" -le "18" ]; then
                expected="target/test-classes"
            fi
        elif [ "$pid" == "Collections" ]; then
            if [ "$bid" -ge "1" ] && [ "$bid" -le "21" ]; then
                expected="build/tests"
            elif [ "$bid" -ge "22" ] && [ "$bid" -le "28" ]; then
                expected="target/tests"
            fi
        elif [ "$pid" == "Compress" ]; then
            expected="target/test-classes"
        elif [ "$pid" == "Csv" ]; then
            expected="target/test-classes"
        elif [ "$pid" == "Gson" ]; then
            expected="target/test-classes"
        elif [ "$pid" == "JacksonCore" ]; then
            expected="target/test-classes"
        elif [ "$pid" == "JacksonDatabind" ]; then
            expected="target/test-classes"
        elif [ "$pid" == "JacksonXml" ]; then
            expected="target/test-classes"
        elif [ "$pid" == "Jsoup" ]; then
            expected="target/test-classes"
        elif [ "$pid" == "JxPath" ]; then
            expected="target/test-classes"
        elif [ "$pid" == "Lang" ]; then
            if [ "$bid" -ge "1" ] && [ "$bid" -le "20" ]; then
                expected="target/tests"
            elif [ "$bid" -ge "21" ] && [ "$bid" -le "41" ]; then
                expected="target/test-classes"
            elif [ "$bid" -ge "42" ] && [ "$bid" -le "65" ]; then
                expected="target/tests"
            fi
        elif [ "$pid" == "Math" ]; then
            expected="target/test-classes"
        elif [ "$pid" == "Mockito" ]; then
            if [ "$bid" -ge "1" ] && [ "$bid" -le "11" ]; then
                 expected="build/classes/test"
            elif [ "$bid" -ge "12" ] && [ "$bid" -le "17" ]; then
                expected="target/test-classes"
            elif [ "$bid" -ge "18" ] && [ "$bid" -le "21" ]; then
                expected="build/classes/test"
            elif [ "$bid" -ge "22" ] && [ "$bid" -le "38" ]; then
                expected="target/test-classes"
            fi
        elif [ "$pid" == "Time" ]; then
            if [ "$bid" -ge "1" ] && [ "$bid" -le "11" ]; then
                expected="target/test-classes"
            elif [ "$bid" -ge "12" ] && [ "$bid" -le "27" ]; then
                expected="build/tests"
            fi
        fi

        # Assert
        [ "$test_classes_dir" == "$expected" ] || die "Actual test classes directory of $pid-$bid ('$test_classes_dir') is not the one expected ('$expected')"

        # Clean up
        rm -rf "$work_dir"
    done

    # Clean up
    rm -rf "$test_dir"
}


# Print usage message and exit
usage() {
    local known_pids=$(cd "$BASE_DIR"/framework/core/Project && ls *.pm | sed -e 's/\.pm//g')
    echo "usage: $0 -p <project id>"
    echo "Project ids:"
    for pid in $known_pids; do
        echo "  * $pid"
    done
    exit 1
}

# Check arguments
while getopts ":p:" opt; do
    case $opt in
        p) PIDS="$PIDS $OPTARG"
            ;;
        \?)
            echo "Unknown option: -$OPTARG" >&2
            usage
            ;;
        :)
            echo "No argument provided: -$OPTARG." >&2
            usage
            ;;
  esac
done

# If no arguments provided, iterate over all projects
if [ "$PIDS" == "" ]; then
    PIDS=$(cd "$BASE_DIR/framework/core/Project" && ls *.pm | sed -e 's/\.pm//g')
fi

for PID in $PIDS; do
    # Run all test cases (and log all results), regardless of whether errors occur
    HALT_ON_ERROR=0

    test_ExportTestClassesDir $PID || die "Test 'test_ExportTestClassesDir' has failed!"

    HALT_ON_ERROR=1

    # Print a summary of what went wrong
    if [ "$ERROR" -ne "0" ]; then
        printf '=%.s' $(seq 1 80) 1>&2
        echo 1>&2
        echo "The following errors occurred:" 1>&2
        cat $LOG 1>&2
    fi

    # Indicate whether an error occurred
    exit "$ERROR"
done
