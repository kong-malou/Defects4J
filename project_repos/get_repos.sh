#!/usr/bin/env bash

# The name of the archive that contains all project repos
ARCHIVE=defects4j-repos.zip

clean() {
    rm -rf \
    closure-compiler.git \
    commons-cli.git \
    commons-codec.git \
    commons-csv.git \
    commons-lang.git \
    commons-jxpath.git \
    commons-math.git \
    jackson-core.git \
    jackson-dataformat-xml \
    jfreechart \
    joda-time.git \
    README 
}

# The BSD version of stat does not support --version or -c
if stat --version &> /dev/null; then
    # GNU version
    cmd="stat -c %Y $ARCHIVE"
else
    # BSD version
    cmd="stat -f %m $ARCHIVE"
fi

if [ -e $ARCHIVE ]; then
    old=$($cmd)
else
    old=0
fi
# Only download repos if the server has a newer file
wget -N http://blankslatetech.com/downloads/$ARCHIVE
new=$($cmd)

# Exit if no newer file is available
[ "$old" == "$new" ] && exit 0

# Remove old files
clean

# Extract new repos
unzip -q -u $ARCHIVE && mv defects4j/project_repos/* . && rm -r defects4j
