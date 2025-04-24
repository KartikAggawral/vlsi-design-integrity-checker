#!/usr/bin/perl
use strict;
use warnings;

# Input RTL file
my $rtl_file = $ARGV[0] or die "Usage: $0 <RTL_File>\n";

open my $fh, '<', $rtl_file or die "Cannot open file $rtl_file: $!\n";
my @lines = <$fh>;
close $fh;

my $line_num = 0;
my $module_found = 0;
my %ports;
my %signals;
my %packages_used;
my $clock_signal = "";
my %cdc_signals;
my $fsm_state_detected = 0;
my $error_state_detected = 0;

print "Checking $rtl_file...\n";

foreach my $line (@lines) {
    $line_num++;
    chomp $line;
    $line =~ s/^\s+|\s+$//g;  # Trim spaces

    # Detect missing package imports
    if ($line =~ /import\s+(\w+)::\*/ ) {
        $packages_used{$1} = 1;
    }
    
    if ($line =~ /^\s*module\s+(\w+)/) {
        print "Module detected: $1\n";
        $module_found = 1;
    }

    # Detect missing package import (specific for DSP)
    if ($line =~ /complex_t|dsp_pkg/) {
        unless (exists $packages_used{"dsp_pkg"}) {
            print "ERROR: Missing 'import dsp_pkg::*;' on line $line_num\n";
        }
    }

    # Detect unconnected input/output ports
    if ($line =~ /input|output\s+logic\s+(\w+)/) {
        $ports{$1} = 0;
    }
    
    # Detect signals
    if ($line =~ /logic\s+(\[.*?\])?\s*(\w+)/) {
        $signals{$2} = 1;
    }

    # Detect hardcoded constants instead of parameters/macros
    if ($line =~ /=\s*\d+/) {
        print "WARNING: Hardcoded constant found on line $line_num. Consider using parameters/macros.\n";
    }

    # Detect Clock and Reset signals
    if ($line =~ /input\s+logic\s+(\w+)\s*;/) {
        my $signal = $1;
        if ($signal =~ /clk/i) {
            if ($clock_signal && $clock_signal ne $signal) {
                print "ERROR: Multiple clock signals detected! $clock_signal and $signal on line $line_num\n";
            }
            $clock_signal = $signal;
        }
    }

    # Detect unsynchronized clock domain crossings
    if ($line =~ /\.(\w+)\s*\(\s*(\w+)\s*\)/) {
        my ($port, $signal) = ($1, $2);
        if ($port =~ /clk/i) {
            $cdc_signals{$signal} = 1;
        }
    }

    # FSM Encoding Check
    if ($line =~ /typedef enum logic\s*\[/) {
        $fsm_state_detected = 1;
    }
    if ($fsm_state_detected && $line =~ /\bERROR\b/) {
        print "ERROR: 'ERROR' state detected in FSM on line $line_num\n";
        $error_state_detected = 1;
    }

    # Detect uninitialized registers
    if ($line =~ /logic\s+\[.*?\]\s+(\w+);/ && $line !~ /=/) {
        print "WARNING: Register '$1' is declared but uninitialized on line $line_num\n";
    }

    # Detect unintended latches
    if ($line =~ /always_ff/ && $line !~ /rst|clk/) {
        print "ERROR: Possible unintended latch formation on line $line_num.\n";
    }

    # Detect combinational loops
    if ($line =~ /always_comb/ && $line !~ /begin\s*end/) {
        print "ERROR: Combinational loop detected on line $line_num\n";
    }

    # Detect array index out-of-bounds
    if ($line =~ /(\w+)\s*\[\s*(\w+)\s*\]/) {
        my ($array, $index) = ($1, $2);
        if ($index =~ /\D/ && !exists $signals{$index}) {
            print "ERROR: Array index '$index' might be out of bounds on line $line_num\n";
        }
    }

    # Detect incorrect width assignments
    if ($line =~ /assign\s+(\w+)\s*=\s*{\s*(\w+)\s*,\s*\d+\s*\'b/) {
        print "WARNING: Bit-width mismatch found on line $line_num\n";
    }
}

# Final Checks
if (!$module_found) {
    print "ERROR: No module found in file. This is not a valid Verilog/SystemVerilog file.\n";
}

# Check for unconnected ports
foreach my $port (keys %ports) {
    unless ($signals{$port}) {
        print "ERROR: Unconnected port '$port'.\n";
    }
}

# Check for unsynchronized CDC signals
if (keys %cdc_signals > 1) {
    print "ERROR: Clock domain crossing issues detected. Ensure proper synchronization.\n";
}

print "Linting completed.\n";
