display $xmm0.v2_double
display $xmm1.v2_double
display $xmm2.v2_double
break _start
run
tui enable
layout regs
