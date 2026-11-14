/***********************************************
 * Group 13 - Laboratory 6
 * NIOS V system with custom DACs
 * C code of sine wave generation
 ***********************************************/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "system.h"
#include "sys/alt_irq.h"
#include "altera_avalon_pio_regs.h"
#include "altera_avalon_timer_regs.h"
#include "sinus.h"

#define SINE_SAMPLES 20

volatile int sine_index = 0;

// Timer ISR outputs next sine sample
static void timer_isr(void *context)
{
    IOWR_ALTERA_AVALON_TIMER_STATUS(TIMER_0_BASE, 0);
    IOWR_ALTERA_AVALON_PIO_DATA(PIO_VAL_OUT_BASE, (unsigned int)samples[sine_index]);
    sine_index = (sine_index + 1) % SINE_SAMPLES;
}

// Initialize timer for 1000 Hz sampling
void init_timer()
{
    IOWR_ALTERA_AVALON_TIMER_CONTROL(TIMER_0_BASE, ALTERA_AVALON_TIMER_CONTROL_STOP_MSK);
    IOWR_ALTERA_AVALON_TIMER_STATUS(TIMER_0_BASE, 0);
    IOWR_ALTERA_AVALON_TIMER_PERIODL(TIMER_0_BASE, 0xC350);
    IOWR_ALTERA_AVALON_TIMER_PERIODH(TIMER_0_BASE, 0x0000);

    alt_ic_isr_register(TIMER_0_IRQ_INTERRUPT_CONTROLLER_ID, 
                        TIMER_0_IRQ, 
                        timer_isr, 
                        NULL, 
                        NULL);

    IOWR_ALTERA_AVALON_TIMER_CONTROL(TIMER_0_BASE, 
                                     ALTERA_AVALON_TIMER_CONTROL_START_MSK |
                                     ALTERA_AVALON_TIMER_CONTROL_CONT_MSK  |
                                     ALTERA_AVALON_TIMER_CONTROL_ITO_MSK);
                                     
    printf("Timer initialized at 1000 Hz.\n");
}

int main()
{
    char str_buffer[20];
    int freq_sel;
    
    // Initialize system
    IOWR_ALTERA_AVALON_PIO_DATA(PIO_FREQ_SEL_BASE, 0x0); 
    IOWR_ALTERA_AVALON_PIO_DATA(PIO_VAL_OUT_BASE, 0x0);
    IOWR_ALTERA_AVALON_PIO_DATA(LEDS_BASE, 0x00);
    init_timer();

    // Main loop - user selects DAC frequency
    while(1)
    {
        printf("Insert DAC frequency (0-3): \n");
        
        if (fgets(str_buffer, sizeof(str_buffer), stdin) != NULL) {
            freq_sel = (int)strtoul(str_buffer, NULL, 10) & 0x03;
            IOWR_ALTERA_AVALON_PIO_DATA(PIO_FREQ_SEL_BASE, freq_sel);
            IOWR_ALTERA_AVALON_PIO_DATA(LEDS_BASE, freq_sel);
        }
    }

    return 0;
}