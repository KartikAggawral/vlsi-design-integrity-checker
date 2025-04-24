#!/usr/bin/perl
use strict;
use warnings;

# Hashes to store extracted signals
my %clock_signals;
my %reset_signals;
my %flip_flops;
my %cross_domain_flops;
my %multiple_clock_usage;
my %async_resets;
my %unreset_flops;

# Get the file list from arguments
my @files = @ARGV;
if (!@files) {
    die "Usage: perl cdc_checker.pl <RTL files>\n";
}

print "Running CDC/RDC Checker on RTL Files...\n";

foreach my $file (@files) {
    open my $fh, '<', $file or die "Cannot open file $file: $!\n";
    my $line_num = 0;
    my $current_module = "";
    my $inside_module = 0;
    
    while (<$fh>) {
        $line_num++;
        chomp;

        # Detect and store clock signals
        if (/input\s+(?:logic|wire|reg)?\s*(\w*clk\w*)\s*;/) {
            my $clk = $1;
            $clock_signals{$clk} = $file;
            print "Found clock signal: $clk in $file at line $line_num\n";
        }

        # Detect and store reset signals
        if (/input\s+(?:logic|wire|reg)?\s*(\w*rst\w*)\s*;/) {
            my $rst = $1;
            $reset_signals{$rst} = $file;
            print "Found reset signal: $rst in $file at line $line_num\n";
        }

        # Detect Flip-Flops using always_ff or always blocks
        if (/always_ff\s*@\((posedge|negedge)\s+(\w+)\)/ || /always\s*@\((posedge|negedge)\s+(\w+)\)/) {
            my $clk = $2;
            if (!exists $clock_signals{$clk}) {
                print "Warning: Flip-flop using undeclared clock '$clk' in $file at line $line_num\n";
            }
            push @{$flip_flops{$clk}}, { file => $file, line => $line_num };
        }

        # Detect improper reset usage in always blocks
        if (/always_ff\s*@\((posedge|negedge)\s+(\w+)\)/) {
            my $clk = $2;
            if (!/reset/ && !/rst/) {
                $unreset_flops{$file}{$line_num} = $clk;
            }
        }

        # Detect flops crossing clock domains without synchronization
        if (/always_ff\s*@\((posedge|negedge)\s+(\w+)\)/) {
            my $clk = $2;
            foreach my $stored_clk (keys %flip_flops) {
                if ($stored_clk ne $clk) {
                    $cross_domain_flops{$file}{$line_num} = "$stored_clk → $clk";
                }
            }
        }

        # Detect multiple clocks used in one block
        if (/always_ff\s*@\((posedge|negedge)\s+(\w+),\s*(posedge|negedge)\s+(\w+)\)/) {
            my $clk1 = $2;
            my $clk2 = $4;
            print "Multiple clocks detected in a single block: '$clk1' and '$clk2' in $file at line $line_num\n";
            $multiple_clock_usage{$file}{$line_num} = "$clk1, $clk2";
        }

        # Detect async reset usage
        if (/always_ff\s*@\((posedge|negedge)\s+(\w+),\s*(posedge|negedge)\s+(\w+)\)/) {
            my $clk = $2;
            my $reset = $4;
            if (exists $reset_signals{$reset}) {
                $async_resets{$file}{$line_num} = "$reset";
            }
        }
    }
    close $fh;
}

# Reporting detected issues

print "\nClock Domain Crossing (CDC) Analysis:\n";
foreach my $file (keys %cross_domain_flops) {
    foreach my $line (keys %{$cross_domain_flops{$file}}) {
        print "CDC Issue: Flip-flop at $file line $line crosses clock domain: $cross_domain_flops{$file}{$line}\n";
    }
}

print "\nMultiple Clock Usage:\n";
foreach my $file (keys %multiple_clock_usage) {
    foreach my $line (keys %{$multiple_clock_usage{$file}}) {
        print "Multi-Clock Issue: Flip-flop at $file line $line uses multiple clocks: $multiple_clock_usage{$file}{$line}\n";
    }
}

print "\nImproper Reset Handling:\n";
foreach my $file (keys %unreset_flops) {
    foreach my $line (keys %{$unreset_flops{$file}}) {
        print "Missing Reset: Flip-flop at $file line $line on clock: $unreset_flops{$file}{$line} has no reset!\n";
    }
}

print "\nCDC Analysis Completed.\n";
