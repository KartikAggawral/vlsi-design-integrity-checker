#!/usr/bin/perl
use strict;
use warnings;

# Input SDC and Timing Report Files
my $sdc_file = "C:/Users/Admin/Desktop/vlsi_integrity_checker/scripts/design_constraints.sdc";
my $timing_report = "C:/Users/Admin/Desktop/vlsi_integrity_checker/scripts/timing_report.txt";

# Hash to store constraints from SDC
my %constraints = ();
my @unconstrained_paths = ();
my @clock_skew_issues = ();

# Read SDC File and Store Constraints
sub parse_sdc {
    open(my $fh, "<", $sdc_file) or die "Cannot open $sdc_file: $!";
    while (my $line = <$fh>) {
        chomp($line);

        if ($line =~ /create_clock\s+-period\s+([\d.]+)\s+\[get_ports\s+(\w+)\]/) {
            $constraints{"clock_$2"} = $1;
        }
        elsif ($line =~ /set_input_delay\s+-max\s+([\d.]+)\s+-clock\s+(\w+)\s+\[get_ports\s+(\w+)\]/) {
            $constraints{"input_$3"} = $1;
        }
        elsif ($line =~ /set_output_delay\s+-max\s+([\d.]+)\s+-clock\s+(\w+)\s+\[get_ports\s+(\w+)\]/) {
            $constraints{"output_$3"} = $1;
        }
        elsif ($line =~ /set_false_path\s+-from\s+\[get_ports\s+(\w+)\]/) {
            $constraints{"false_path_$1"} = 1;
        }
    }
    close($fh);
}

# Read Timing Report and Identify Issues
sub parse_timing_report {
    open(my $fh, "<", $timing_report) or die "Cannot open $timing_report: $!";
    my $current_path = "";
    
    while (my $line = <$fh>) {
        chomp($line);
        
        if ($line =~ /Path Group:\s+(\w+)/) {
            $current_path = $1;
        }
        elsif ($line =~ /Clock:\s+(\w+)\s+\(Clock Period:\s+([\d.]+)\s+ns\)/) {
            my ($clock, $period) = ($1, $2);
            
            if (exists $constraints{"clock_$clock"} && $constraints{"clock_$clock"} != $period) {
                push @clock_skew_issues, "Clock skew detected: $clock (Expected: $constraints{\"clock_$clock\"} ns, Found: $period ns)";
            }
        }
        elsif ($line =~ /Slack:\s+(-?[\d.]+)\s+ns/) {
            my $slack = $1;
            if ($slack < 0) {
                print " Timing Violation Detected! Slack: $slack ns\n";
            }
        }
    }
    close($fh);
}

# Check for Unconstrained Paths
sub check_unconstrained_paths {
    foreach my $key (keys %constraints) {
        if ($key =~ /^input_(\w+)$/ && !exists $constraints{"output_$1"}) {
            push @unconstrained_paths, "Unconstrained input detected: $1";
        }
        if ($key =~ /^output_(\w+)$/ && !exists $constraints{"input_$1"}) {
            push @unconstrained_paths, "Unconstrained output detected: $1";
        }
    }
}

# Run All Checks
parse_sdc();
parse_timing_report();
check_unconstrained_paths();

# Print Issues
print "------ Clock Skew Issues ------\n";
print "$_\n" for @clock_skew_issues;

print "\n------ Unconstrained Paths ------\n";
print "$_\n" for @unconstrained_paths;

print "\n------ STA Analysis Completed ------\n";
