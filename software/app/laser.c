// lab4.c - read and print ADC register values from ltc2308 interface
// and display LED heartbeat on FPGA board.
// Ed.Casas 2026-2-1

/* Nios V command shell commands to rebuilt BSP and application:
   
cd <project folder>

niosv-bsp -c -t=hal --sopcinfo=lab4.sopcinfo software/bsp/settings.bsp
niosv-app -a=software/app -b=software/bsp -s=software/app/lab4.c

To view JTAG UART output, run:

juart-terminal

*/


#include "system.h"
#include <alt_types.h>
#include <io.h>
#include <stdio.h>
#include <unistd.h>

int main ( void ) {

   int firstch = 0, lastch = 3;
   IOWR_32DIRECT(LTC2308_0_BASE, 0, ((lastch & 7) << 3) | (firstch & 7));

   int chval[4] = {0};
   int offsets[4] = {0};
   float x_err, y_err;
   float deadzone = 0.10;

   printf("TL:Ch3, TR:Ch0, BL:Ch2, BR:Ch1\n");

   for ( int i=0 ; 1 ; i++ ) {
      IOWR_32DIRECT(PIO_0_BASE, 0, 1 << (i % 8));

      long sum_ch[4] = {0,0,0,0};
      for ( int j=0 ; j < 64 ; j++ ) {
         int raw = IORD_32DIRECT(LTC2308_0_BASE, 0);
         if (!(raw & 0x8000)) {
            int ch = (raw & 0x7000) >> 12;
            if (ch < 4) sum_ch[ch] += (raw & 0xfff);
         }
      }
      for(int k=0; k<4; k++) chval[k] = sum_ch[k] / 16;

      if (IORD_32DIRECT(PIO_1_BASE, 0) == 0) {
         for(int k=0; k<4; k++) offsets[k] = chval[k];
         printf("\n>>> SYSTEM ZEROED <<<\n");
         usleep(500000);
      }

      int tl = chval[3] - offsets[3];
      int tr = chval[0] - offsets[0];
      int bl = chval[2] - offsets[2];
      int br = chval[1] - offsets[1];

      if(tl < 0) tl = 0; if(tr < 0) tr = 0;
      if(bl < 0) bl = 0; if(br < 0) br = 0;

      int total_sum = tl + tr + bl + br;

      printf("RAW:[%4d %4d %4d %4d] | ", chval[3], chval[0], chval[2], chval[1]);

      if (total_sum > 40) {
         x_err = (float)((tr + br) - (tl + bl)) / total_sum;
         y_err = (float)((tl + tr) - (bl + br)) / total_sum;

         char *x_msg = (x_err > deadzone) ? "RIGHT" : (x_err < -deadzone) ? "LEFT " : "STAY ";
         char *y_msg = (y_err > deadzone) ? "UP   " : (y_err < -deadzone) ? "DOWN " : "STAY ";

         printf("SUM:%4d | X:%+1.2f Y:%+1.2f | [%s, %s]\r", total_sum, x_err, y_err, x_msg, y_msg);
      } else {
         printf("SUM:%4d | [ SEARCHING ]                         \r", total_sum);
      }

      fflush(stdout);
      usleep(20000);
   }
   return 0;
}
