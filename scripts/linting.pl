#!/usr/bin/perl
use strict;
use warnings;

my @files = @ARGV;
if (!@files) {
    die "No files provided for linting.\n";
}

my %modules;
my %signals;
my %instances;
my %case_statements;
my %ports;
my %sensitivity_list;

foreach my $file (@files) {
    open my $fh, '<', $file or die "Cannot open $file: $!\n";
    my $line_num = 0;
    my $inside_case = 0;
    my %local_signals;

    while (<$fh>) {
        $line_num++;
        chomp;

        # Skip empty lines and comments
        next if /^\s*$/ || /^\s*\/\//;

        # Detect missing semicolons (excluding block statements and comments)
        if (!/;\s*$/ && !/{|}/ && !/^\s*always/ && !/^\s*if/ && !/^\s*else/ && !/^\s*case/ && !/^\s*end/ ) {
            print "Possible missing semicolon in $file at line $line_num\n";
        }

        # Detect unconnected nets
        if (/^\s*wire\s+(\w+)\s*;/ && !/assign|output|input/) {
            print "Unconnected net: '$1' in $file at line $line_num\n";
        }

        # Detect duplicate module names
        if (/^\s*module\s+(\w+)/) {
            my $module = $1;
            if (exists $modules{$module}) {
                print "Duplicate module name '$module' in $file at line $line_num\n";
            } else {
                $modules{$module} = 1;
            }
        }

        # Detect hardcoded constants (ignoring parameters)
        if (/\b\d+\b/ && !/parameter|localparam/ && !/\[.*?\d+.*?\]/) {
            print "Hardcoded constant detected in $file at line $line_num\n";
        }

        # Detect latch inference (if without else inside always block)
        if (/^\s*if\s*\(.*\)\s*begin\s*$/ .. /^\s*end\s*$/) {
            if (!/^\s*else\s*$/) {
                print "Possible latch inferred in $file at line $line_num\n";
            }
        }

        # Detect combinational loops (e.g., assign x = x;)
        if (/^\s*assign\s+(\w+)\s*=\s*\1\s*;/) {
            print "Combinational loop detected for signal '$1' in $file at line $line_num\n";
        }

        # Detect missing reset in sequential always blocks
        if (/^\s*always\s*@\(posedge\s+\w+\)/ && !/reset|rst/) {
            print "Missing reset condition in sequential block in $file at line $line_num\n";
        }

        # Detect multiple drivers for a signal
        if (/^\s*assign\s+(\w+)\s*=/) {
            $signals{$1}++;
            if ($signals{$1} > 1) {
                print "Multiple drivers detected for signal '$1' in $file at line $line_num\n";
            }
        }

        # Detect non-standard naming conventions
        if (/^\s*reg\s+(\w+)/ && $1 !~ /^r_/) {
            print "Non-standard register naming: '$1' should start with 'r_' in $file at line $line_num\n";
        }
        if (/^\s*wire\s+(\w+)/ && $1 !~ /^w_/) {
            print "Non-standard wire naming: '$1' should start with 'w_' in $file at line $line_num\n";
        }

        # Track defined signals for unused detection
        if (/^\s*(wire|reg)\s+(\w+)/) {
            $local_signals{$2} = 0;
        }

        # Detect improper case statement usage
        if (/^\s*case\s*\(/) {
            $inside_case = 1;
        }
        if ($inside_case && /^\s*default\s*:/) {
            $inside_case = 0;
        }
        if (eof && $inside_case) {
            print "Missing default case in case statement in $file at line $line_num\n";
        }

        # Detect mismatched port connections
        if (/\.(\w+)\s*\(/) {
            my $port = $1;
            $ports{$port}++;
            if ($ports{$port} > 1) {
                print "Possible port connection mismatch in $file at line $line_num\n";
            }
        }

        # Detect missing sensitivity list items
        if (/^\s*always\s*@\(([^)]*)\)/) {
            my @items = split /,/, $1;
            foreach my $item (@items) {
                $sensitivity_list{$item}++;
            }
            if (!grep { /clk|reset|rst/ } @items) {
                print "Incomplete sensitivity list in $file at line $line_num\n";
            }
        }

        # Detect deprecated keywords
        if (/^\s*defparam\s+/) {
            print "Deprecated keyword 'defparam' used in $file at line $line_num\n";
        }

        # Detect unused signals
        foreach my $sig (keys %local_signals) {
            if ($local_signals{$sig} == 0) {
                print "Unused signal detected: '$sig' in $file at line $line_num\n";
            }
        }
    }
    close $fh;
}

print "Linting completed.\n";
