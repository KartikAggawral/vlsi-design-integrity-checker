// Package for DSP operations (Fixed Version)
package dsp_pkg;
    parameter int DATA_WIDTH = 16;
    
    typedef struct packed {
        logic signed [DATA_WIDTH-1:0] real;
        logic signed [DATA_WIDTH-1:0] imag;
    } complex_t;
    
    function automatic complex_t add_complex(complex_t a, complex_t b);
        add_complex.real = a.real + b.real;
        add_complex.imag = a.imag + b.imag;
        return add_complex; // Added return statement
    endfunction
endpackage
