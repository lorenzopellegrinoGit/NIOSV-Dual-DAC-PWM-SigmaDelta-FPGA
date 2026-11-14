/***********************************************
 * Group 13 - Laboratory 6
 * NIOS V system with custom DACs
 * C code of Keyboard-driven DAC operation
 ***********************************************/

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "system.h"
#include "altera_avalon_pio_regs.h"
#include "altera_avalon_timer_regs.h"
#include "sys/alt_irq.h"
#include "alt_types.h"

// HEX display segments encoding
#define HEX_DEC_0 0b1000000
#define HEX_DEC_1 0b1111001
#define HEX_DEC_2 0b0100100
#define HEX_DEC_3 0b0110000
#define HEX_DEC_4 0b0011001
#define HEX_DEC_5 0b0010010
#define HEX_DEC_6 0b0000010
#define HEX_DEC_7 0b1111000
#define HEX_DEC_8 0b0000000
#define HEX_DEC_9 0b0010000
#define HEX_DEC_A 0b0001000
#define HEX_DEC_B 0b0000011
#define HEX_DEC_C 0b1000110
#define HEX_DEC_D 0b0100001
#define HEX_DEC_E 0b0000110
#define HEX_DEC_F 0b0001110
#define HEX_DEC_BLANK 0b1111111

// Write hex digit to 7-segment display
int writeHEX(uint32_t hex_base, uint8_t code)
{
    switch (code)
    {
    case 0x00:
        IOWR_ALTERA_AVALON_PIO_DATA(hex_base, HEX_DEC_0);
        break;
    case 0x01:
        IOWR_ALTERA_AVALON_PIO_DATA(hex_base, HEX_DEC_1);
        break;
    case 0x02:
        IOWR_ALTERA_AVALON_PIO_DATA(hex_base, HEX_DEC_2);
        break;
    case 0x03:
        IOWR_ALTERA_AVALON_PIO_DATA(hex_base, HEX_DEC_3);
        break;
    case 0x04:
        IOWR_ALTERA_AVALON_PIO_DATA(hex_base, HEX_DEC_4);
        break;
    case 0x05:
        IOWR_ALTERA_AVALON_PIO_DATA(hex_base, HEX_DEC_5);
        break;
    case 0x06:
        IOWR_ALTERA_AVALON_PIO_DATA(hex_base, HEX_DEC_6);
        break;
    case 0x07:
        IOWR_ALTERA_AVALON_PIO_DATA(hex_base, HEX_DEC_7);
        break;
    case 0x08:
        IOWR_ALTERA_AVALON_PIO_DATA(hex_base, HEX_DEC_8);
        break;
    case 0x09:
        IOWR_ALTERA_AVALON_PIO_DATA(hex_base, HEX_DEC_9);
        break;
    case 0x0A:
        IOWR_ALTERA_AVALON_PIO_DATA(hex_base, HEX_DEC_A);
        break;
    case 0x0B:
        IOWR_ALTERA_AVALON_PIO_DATA(hex_base, HEX_DEC_B);
        break;
    case 0x0C:
        IOWR_ALTERA_AVALON_PIO_DATA(hex_base, HEX_DEC_C);
        break;
    case 0x0D:
        IOWR_ALTERA_AVALON_PIO_DATA(hex_base, HEX_DEC_D);
        break;
    case 0x0E:
        IOWR_ALTERA_AVALON_PIO_DATA(hex_base, HEX_DEC_E);
        break;
    case 0x0F:
        IOWR_ALTERA_AVALON_PIO_DATA(hex_base, HEX_DEC_F);
        break;
    default:
        IOWR_ALTERA_AVALON_PIO_DATA(hex_base, HEX_DEC_BLANK);
        break;
    }
    return 0;
}

// Initialize system peripherals
int system_init()
{
    writeHEX(HEX0_BASE, 0x00);
    writeHEX(HEX1_BASE, 0x00);
    IOWR_ALTERA_AVALON_PIO_DATA(LEDS_BASE, 0x00);
    return 0;
}

int main()
{
    char str_buffer[20];
    uint8_t valueToConvert = 0;
    uint8_t valueFrequency = 0;

    system_init();

    // Main loop - get value and frequency from user
    while (1)
    {
        printf("Insert value to convert (0-255):\n");
        if (fgets(str_buffer, sizeof(str_buffer), stdin) != NULL)
        {
            valueToConvert = (uint8_t)(strtoul(str_buffer, NULL, 10) & 0xFF);
        }

        printf("Insert frequency (0-3):\n");
        if (fgets(str_buffer, sizeof(str_buffer), stdin) != NULL)
        {
            valueFrequency = (uint8_t)(strtoul(str_buffer, NULL, 10) & 0x03);
        }

        // Update outputs
        IOWR_ALTERA_AVALON_PIO_DATA(PIO_VAL_OUT_BASE, valueToConvert);
        IOWR_ALTERA_AVALON_PIO_DATA(PIO_FREQ_SEL_BASE, valueFrequency);
        IOWR_ALTERA_AVALON_PIO_DATA(LEDS_BASE, valueFrequency);
        writeHEX(HEX0_BASE, valueToConvert & 0x0F);
        writeHEX(HEX1_BASE, (valueToConvert >> 4) & 0x0F);
    }

    return 0;
}