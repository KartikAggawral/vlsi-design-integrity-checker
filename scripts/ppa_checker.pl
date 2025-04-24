#!/usr/bin/perl
use strict;
use warnings;

# Hashes to store extracted signals and counters
my %clock_signals;
my %flip_flops;
my %toggle_count;
my %area_count;
my $total_area = 0;
my $total_toggles = 0;
my $max_clock_rate = 0;
my $critical_path_delay = 0;

# Get the file list from arguments
my @files = @ARGV;
if (!@files) {
    die "Usage: perl ppa_checker.pl <RTL files>\n";
}

print "Running PPA (Power, Performance, Area) Checker on RTL Files...\n";

foreach my $file (@files) {
    open my $fh, '<', $file or die "Cannot open file $file: $!\n";
    my $line_num = 0;
    
    while (<$fh>) {
        $line_num++;
        chomp;

        # Detect and store clock signals
        if (/input\s+(?:logic|wire|reg)?\s*(\w*clk\w*)\s*;/) {
            my $clk = $1;
            $clock_signals{$clk} = $file;
            print "Found clock signal: $clk in $file at line $line_num\n";
        }

        # Detect Flip-Flops (area check)
        if (/always_ff\s*@\((posedge|negedge)\s+(\w+)\)/) {
            my $clk = $2;
            if (!exists $clock_signals{$clk}) {
                print "Warning: Flip-flop using undeclared clock '$clk' in $file at line $line_num\n";
            }
            push @{$flip_flops{$clk}}, { file => $file, line => $line_num };
            $area_count{$file}++;  # Count flip-flops for area estimate
            $total_area++;  # Accumulate area based on flip-flops
        }

        # Detect toggle activity (power analysis)
        if (/always\s*@\((posedge|negedge)\s+(\w+)\)/) {
            my $clk = $2;
            $toggle_count{$clk}++;  # Increment toggle count for power estimation
            $total_toggles++;  # Total toggle activity
        }

        # Performance (critical path analysis, simplified)
        if (/#(\d+)\s*;\s*\/\/\s*(\w+)\s*path/) {
            my $delay = $1;  # Timing delay in the critical path
            $critical_path_delay = $delay if $delay > $critical_path_delay;
            print "Critical Path Delay: $delay ns in $file at line $line_num\n";
        }
    }
    close $fh;
}

# Reporting detected issues
print "\nPower Consumption Issues:\n";
print "Estimated Power Consumption: Based on flip-flops and toggle activity\n";
print "Total Toggles: $total_toggles\n";
print "Total Flip-Flops (Estimated Area): $total_area\n";

# Estimate power consumption (simplified model)
my $power_estimate = $total_toggles * 0.1;  # Arbitrary toggle-to-power constant
print "Estimated Power Consumption (simplified): $power_estimate mW\n";

print "\nPerformance Optimization Issues:\n";
print "Critical Path Delay (Worst Case): $critical_path_delay ns\n";

print "\nArea Optimization Issues:\n";
print "Total Area (Flip-Flops used): $total_area gates (simplified)\n";

print "\nPPA Analysis Completed.\n";
