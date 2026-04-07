/* Nios V command shell commands to rebuilt BSP and application:
   
cd <project folder>

niosv-bsp -c -t=hal --sopcinfo=ccom.sopcinfo ./software/bsp/settings.bsp
niosv-app -a=software/app -b=software/bsp -s=./software/app/laser.c


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
#include "limits.h"

#define THRESHHOLD 0.15f
void head();
char* int_to_binary(int n);

int main() {
    printf("Transmitter monitor.....\n");
    head();

    bool pin_on = false;
    while (1) {
        int status = IORD_ALTERA_AVALON_PIO_DATA(PIO_STATUS_BASE);
		status &= 0b11111111;
		char* status_bin = int_to_binary(status);

		printf(" %4d | %s | %s | %s \n", status, status_bin, );

		// Flush the output to ensure it updates immediately in RiscFree
		fflush(stdout);
		free(status_bin);

    }
    return 0;
}

void head()
{
	printf("MESSAGE");
	printf("--------------------------------------\n");
}

char* int_to_binary(int n) {
    int bits = 8; // Locked to 8 bits
    char* binary_str = (char*)malloc(bits + 1);

    if (!binary_str) return NULL;

    binary_str[bits] = '\0';
    unsigned int temp = (unsigned int)n;

    for (int i = bits - 1; i >= 0; i--) {
        binary_str[i] = (temp & 1) ? '1' : '0';
        temp >>= 1;
    }

    return binary_str;
}
