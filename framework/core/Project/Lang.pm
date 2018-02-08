#-------------------------------------------------------------------------------
# Copyright (c) 2014-2018 René Just, Darioush Jalali, and Defects4J contributors.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#-------------------------------------------------------------------------------

=pod

=head1 NAME

Project::Lang.pm -- L<Project> submodule for Commons-lang.

=head1 DESCRIPTION

This module provides all project-specific configurations and subroutines for the
Commons-lang project.

=cut
package Project::Lang;

use strict;
use warnings;

use Constants;
use Vcs::Git;

our @ISA = qw(Project);
my $PID  = "Lang";

sub new {
    @_ == 2 or die $ARG_ERROR;
    my ($class, $work_dir) = @_;

    my $name = "commons-lang";
    my $src  = "src/main/java";
    my $test = "src/test";
    my $vcs  = Vcs::Git->new($PID,
                             "$REPO_DIR/$name.git",
                             "$work_dir/$PID/commit-db",
                             \&_post_checkout);

    return $class->SUPER::new($PID, $name, $vcs, $src, $test, $work_dir);
}

sub initialize_revision {
    my ($self, $revision, $vid) = @_;
    $self->SUPER::initialize_revision($revision);
    # TODO: define the file name for random tests in Constants
    my $RANDOM_TEST_FILE = "$self->{_work_dir}/$self->{pid}/random_tests";
    _log_random_tests($self->{prog_root} . "/" . $self->test_dir($vid), $RANDOM_TEST_FILE);
}

# Search for randomly failing tests in all java files
sub _log_random_tests {
    my ($test_dir, $out_file) = @_;
    @_ == 2 or die $ARG_ERROR;
    # TODO: Move to Constants
    my $PREFIX = "---";
    my @list = `cd $test_dir && find . -name *.java`;
    die if $?!=0 or !@list;

    foreach my $file (@list) {
        chomp $file;
        open(IN, "<$test_dir/$file") or die $!;
        my @reason = ();
        my $rnd=0;
        while (<IN>) {
            if (!$rnd) {
                next unless /(\*|\/\/).*randomly/;
                $rnd=1;
            }
            if ($rnd and /\s*public\s*void\s*([^\(]*)\s*\(/) {
                my $method=$1;
                my $class = $file;
                $class =~ s/\.\/(.*).java/$1/; $class =~ s/\//\./g;
                my $key = "${class}::$method";
                # Only print method if it is not already in the result file
                Utils::append_to_file_unless_matches($out_file,
                    join('', @reason) . "$PREFIX $key\n\n",
                    qr/$PREFIX $key/
                );
                @reason = ();
                $rnd=0; next;
            }
            push(@reason, $_);
        }
        close(IN);
    }
}

sub src_dir {
    @_ == 2 or die $ARG_ERROR;
    my ($self, $vid) = @_;
    Utils::check_vid($vid);

    # Init dir_map if necessary
    $self->_build_dir_map();

    # Get revision hash
    my $revision_id = $self->lookup($vid);

    # Get src directory from lookup table
    my $src = $self->{_dir_map}->{$revision_id}->{src};
    return $src if defined $src;

    # Get default src dir if not listed in _dir_map
    return $self->SUPER::src_dir($vid);
}

sub test_dir {
    @_ == 2 or die $ARG_ERROR;
    my ($self, $vid) = @_;
    Utils::check_vid($vid);

    # Init dir_map if necessary
    $self->_build_dir_map();

    # Get revision hash
    my $revision_id = $self->lookup($vid);

    # Get test directory from lookup table
    my $test = $self->{_dir_map}->{$revision_id}->{test};
    return $test if defined $test;

    # Get default test dir if not listed in _dir_map
    return $self->SUPER::test_dir($vid);
}

#
# Remove randomly failing tests in addition to the broken ones
#
sub fix_tests {
    @_ == 2 or die $ARG_ERROR;
    my ($self, $vid) = @_;
    # Call fix_tests in super class to fix all broken methods
    $self->SUPER::fix_tests($vid);

    # Remove randomly failing tests
    my $work_dir = $self->{prog_root};
    my $dir = $self->test_dir($vid);

    my $file = "$SCRIPT_DIR/projects/$PID/random_tests";
    if (-e $file) {
        # Remove broken test methods
        system("$UTIL_DIR/rm_broken_tests.pl $file $work_dir/$dir") == 0 or die;
    }
}

sub _post_checkout {
    my ($self, $revision_id, $work_dir) = @_;

    # TODO this used to convert maven to ant build files, might need that functionality again.
    # Check whether ant build file exists
    unless (-e "$work_dir/build.xml") {
        system("cp $SCRIPT_DIR/projects/$PID/build_files/$revision_id/* $work_dir");
    }
}

sub _build_dir_map {
    my $self = shift;

    return if defined $self->{_dir_map};

    my $map_file = "$SCRIPT_DIR/projects/$PID/dir_map.csv";
    open (IN, "<$map_file") or die "Cannot open directory map $map_file: $!";
    my $cache = {};
    while (<IN>) {
        chomp;
        /([^,]+),([^,]+),(.+)/ or next;
        $cache->{$1} = {src=>$2, test=>$3};
    }
    close IN;
    $self->{_dir_map}=$cache;
}

1;
