#!/usr/bin/perl
use strict;
use warnings;

# Input RTL file
my $rtl_file = $ARGV[0] or die "Usage: $0 <RTL_File>\n";

open my $fh, '<', $rtl_file or die "Cannot open file $rtl_file: $!\n";
my @lines = <$fh>;
close $fh;

my $line_num = 0;
my %signals;
my %fsm_states;
my %state_encodings;
my %clk_signals;
my %rst_signals;
my $in_fsm = 0;
my $fsm_encoding_type = "";
my $latch_detected = 0;
my $module_found = 0;
my $comb_loop_detected = 0;

print "Checking Design Rule Compliance for $rtl_file...\n";

foreach my $line (@lines) {
    $line_num++;
    chomp $line;
    $line =~ s/^\s+|\s+$//g;  # Trim spaces

    # Detect module
    if ($line =~ /^\s*module\s+(\w+)/) {
        print "Module detected: $1\n";
        $module_found = 1;
    }

    # Naming convention check for clock/reset signals
    if ($line =~ /input\s+logic\s+(\w+)\s*;/) {
        my $signal = $1;
        if ($signal =~ /clk/i) {
            unless ($signal =~ /^clk_/) {
                print "WARNING: Clock signal '$signal' should follow naming convention 'clk_*' (line $line_num)\n";
            }
            $clk_signals{$signal} = 1;
        }
        if ($signal =~ /rst/i) {
            unless ($signal =~ /^rst_/) {
                print "WARNING: Reset signal '$signal' should follow naming convention 'rst_*' (line $line_num)\n";
            }
            $rst_signals{$signal} = 1;
        }
    }

    # Minimum signal width constraint check
    if ($line =~ /logic\s+\[(\d+):(\d+)\]\s+(\w+)/) {
        my ($msb, $lsb, $signal) = ($1, $2, $3);
        my $width = $msb - $lsb + 1;
        if ($width < 8) {
            print "ERROR: Signal '$signal' has width $width, which is below the minimum required width of 8 (line $line_num)\n";
        }
        $signals{$signal} = $width;
    }

    # FSM Encoding Detection
    if ($line =~ /typedef enum logic\s*\[(\d+):0\]/) {
        my $state_bits = $1 + 1;
        if ($state_bits > 1) {
            print "INFO: FSM detected with $state_bits states (line $line_num)\n";
            $in_fsm = 1;
        }
    }

    # Detecting FSM state assignments
    if ($in_fsm && $line =~ /\s*(\w+)\s*=\s*(\d+)'b([01]+);/) {
        my ($state, $bits, $encoding) = ($1, $2, $3);
        $fsm_states{$state} = $encoding;
        my $num_ones = ($encoding =~ tr/1//);

        if ($num_ones == 1) {
            $state_encodings{$state} = "one-hot";
        } elsif ($encoding =~ /^1?0*1$/) {
            $state_encodings{$state} = "gray";
        } else {
            $state_encodings{$state} = "unknown";
        }
    }

    # Check for unintended latches
    if ($line =~ /always_latch/) {
        print "ERROR: Unintended latch detected (line $line_num)\n";
        $latch_detected = 1;
    }

    # Detect combinational loops (missing sensitivity lists)
    if ($line =~ /always_comb/ && $line !~ /begin\s*end/) {
        print "ERROR: Combinational loop detected (line $line_num)\n";
        $comb_loop_detected = 1;
    }
}

# Final Checks
if (!$module_found) {
    print "ERROR: No module found. This is not a valid Verilog/SystemVerilog file.\n";
}

# FSM Encoding Compliance
foreach my $state (keys %state_encodings) {
    if ($state_encodings{$state} eq "unknown") {
        print "WARNING: FSM state '$state' does not follow One-Hot or Gray encoding\n";
    }
}

print "Design Rule Compliance Check Completed.\n";
