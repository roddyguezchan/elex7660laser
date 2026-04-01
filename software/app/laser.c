/* Nios V command shell commands to rebuilt BSP and application:
   
cd <project folder>

niosv-bsp -c -t=hal --sopcinfo=lab4.sopcinfo ./software/bsp/settings.bsp
niosv-app -a=software/app -b=software/bsp -s=./software/app/lab4.c


To view JTAG UART output, run:

juart-terminal

*/


#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <unistd.h>
#include <io.h>
#include <fcntl.h>
#include "system.h"
#include "altera_avalon_pio_regs.h"

#define THRESHHOLD 100

int main() {
    printf("QPD ADC VALUES.....\n");
    head();

    bool pin_on = false;
    while (1) {

        // Read each quadrant from its respective PIO
        // Using IORD_ALTERA_AVALON_PIO_DATA is the safest way to access PIOs
        int q0 = IORD_ALTERA_AVALON_PIO_DATA(PIO_Q0_BASE);
        int q1 = IORD_ALTERA_AVALON_PIO_DATA(PIO_Q1_BASE);
        int q2 = IORD_ALTERA_AVALON_PIO_DATA(PIO_Q2_BASE);
        int q3 = IORD_ALTERA_AVALON_PIO_DATA(PIO_Q3_BASE);
        int status = IORD_ALTERA_AVALON_PIO_DATA(PIO_STATUS_BASE);

        float dx = ((q0 + q1) - (q3 + q2)) / (q0 + q1 + q2 + q3);
		float dy = ((q0 + q3) - (q1 + q2)) / (q0 + q1 + q2 + q3);

		int wr = 0;

		if ( abs(dx) > THRESHHOLD )
		{
			wr |= 0b1;
			if (dx > 0) wr |= 0b10;
		}

		if ( abs(dy) > THRESHHOLD )
		{
			wr |= 0b100;
			if (dx > 0) wr |= 0b1000;
		}

		IOWR_ALTERA_AVALON_PIO_DATA(PIO_STEPPER_BASE, wr);

		// Print values on one line.
		// %4d ensures the numbers don't "jump" around if they change digits.
		// \r returns the cursor to the start of the line.
		printf(" %4d   |  %4d   |  %4d   |  %4d   |   %1d   |  %1d  |  %1d  |  %1d  |  %1.4f  |  %1.4f  | %4d \n", q0, q1, q2, q3, status&1, (status>>1)&1, (status>>2)&1, (status>>3)&1, dx, dy, status);

		// Flush the output to ensure it updates immediately in RiscFree
		fflush(stdout);

//        char input;
//        if (read(0, &input, 1) > 0) {
//            // 0 is the file descriptor for stdin
//            printf("I received: %c\n\n", input);
//            if(pin_on)
//            {
//            	IOWR_ALTERA_AVALON_PIO_DATA(PIO_STEPPER_BASE, 255);
//            }
//            else
//            {
//            	IOWR_ALTERA_AVALON_PIO_DATA(PIO_STEPPER_BASE, 0);
//            }
//            pin_on = !pin_on;
//
//			head();
//        }

        // Small delay so the console is readable (100ms = 10Hz update)
        //usleep(100000);
    }

    return 0;
}

void head()
{
	printf("Q0 (TR) | Q1 (BR) | Q2 (BL) | Q3 (TL) | MDisp | Idle | Left | Right | Up | Down | RAW \n");
	printf("--------------------------------------\n");
}
