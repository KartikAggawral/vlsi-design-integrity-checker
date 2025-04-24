#!/usr/bin/perl
use strict;
use warnings;

# Get the file list from arguments
my ($file_1, $file_2) = @ARGV;
if (!defined $file_1 || !defined $file_2) {
    die "Usage: perl lec_checker.pl <File_1> <File_2>\n";
}

print "Running Logical Equivalence Checker (LEC) on RTL Files: $file_1 and $file_2...\n";

# Function to read signals and assignments from file
sub read_file {
    my ($file) = @_;
    open my $fh, '<', $file or die "Cannot open file $file: $!\n";

    my %signals;
    my %assigns;
    my $line_num = 0;

    while (<$fh>) {
        $line_num++;
        chomp;

        # Remove inline comments
        s/\/\/.*$//;

        # Match signal declarations
        if (/^\s*(input|output|wire|reg)\s+(\[.*?\]\s*)?([\w, ]+);/) {
            my $signal_list = $3;
            my @signal_names = split /\s*,\s*/, $signal_list;
            foreach my $sig (@signal_names) {
                $signals{$sig} = 1;
                print "Found signal: $sig in $file at line $line_num\n";
            }
        }

        # Match simple assign statements
        if (/^\s*assign\s+(\w+)\s*=\s*(.+);/) {
            my ($lhs, $rhs) = ($1, $2);
            $rhs =~ s/\s+//g;  # Remove whitespace for clean comparison
            $assigns{$lhs} = $rhs;
            print "Found assign: $lhs = $rhs in $file at line $line_num\n";
        }
    }

    close $fh;
    return (\%signals, \%assigns);
}

# Read and store info from both files
my ($signals_1, $assigns_1) = read_file($file_1);
my ($signals_2, $assigns_2) = read_file($file_2);

my @differences;

# Compare signals
foreach my $sig (keys %$signals_1) {
    if (!exists $signals_2->{$sig}) {
        push @differences, "Signal '$sig' found in $file_1 but missing in $file_2";
    }
}
foreach my $sig (keys %$signals_2) {
    if (!exists $signals_1->{$sig}) {
        push @differences, "Signal '$sig' found in $file_2 but missing in $file_1";
    }
}

# Compare assign statements
foreach my $lhs (keys %$assigns_1) {
    if (!exists $assigns_2->{$lhs}) {
        push @differences, "Assignment to '$lhs' in $file_1 not found in $file_2";
    } elsif ($assigns_1->{$lhs} ne $assigns_2->{$lhs}) {
        push @differences, "Different assignment for '$lhs':\n  $file_1: $assigns_1->{$lhs}\n  $file_2: $assigns_2->{$lhs}";
    }
}
foreach my $lhs (keys %$assigns_2) {
    if (!exists $assigns_1->{$lhs}) {
        push @differences, "Assignment to '$lhs' in $file_2 not found in $file_1";
    }
}

# Final LEC Result
if (@differences) {
    print "\nLEC Errors: Logical Equivalence Issues Found!\n";
    foreach my $diff (@differences) {
        print "$diff\n";
    }
} else {
    print "\nLEC Passed: Both files are logically equivalent.\n";
}

print "LEC Analysis Completed.\n";
