/* Nios V command shell commands to rebuilt BSP and application:
   
cd <project folder>

niosv-bsp -c -t=hal --sopcinfo=lab4.sopcinfo ./software/bsp/settings.bsp
niosv-app -a=software/app -b=software/bsp -s=./software/app/lab4.c


To view JTAG UART output, run:

juart-terminal

*/


#include <stdio.h>
#include <unistd.h>
#include <io.h>
#include "system.h"
#include "altera_avalon_pio_regs.h"

int main() {
    printf("QPD ADC VALUES.....\n");
    printf("Q0 (TR) | Q1 (BR) | Q2 (BL) | Q3 (TL)\n");
    printf("--------------------------------------\n");

    while (1) {

        // Read each quadrant from its respective PIO
        // Using IORD_ALTERA_AVALON_PIO_DATA is the safest way to access PIOs
        int q0 = IORD_ALTERA_AVALON_PIO_DATA(PIO_Q0_BASE);
        int q1 = IORD_ALTERA_AVALON_PIO_DATA(PIO_Q1_BASE);
        int q2 = IORD_ALTERA_AVALON_PIO_DATA(PIO_Q2_BASE);
        int q3 = IORD_ALTERA_AVALON_PIO_DATA(PIO_Q3_BASE);

        // Print values on one line.
        // %4d ensures the numbers don't "jump" around if they change digits.
        // \r returns the cursor to the start of the line.
        printf(" %4d   |  %4d   |  %4d   |  %4d   \r", q0, q1, q2, q3);

        // Flush the output to ensure it updates immediately in RiscFree
        fflush(stdout);

        // Small delay so the console is readable (100ms = 10Hz update)
        usleep(100000);
    }

    return 0;
}
