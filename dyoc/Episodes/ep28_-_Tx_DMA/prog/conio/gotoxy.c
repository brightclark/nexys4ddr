#include <stdint.h>     // uint8_t, etc.
#include <conio.h>

#include "memorymap.h"
#include "comp.h"

uint8_t pos_x;
uint8_t pos_y;

void gotoxy(uint8_t x, uint8_t y)
{
   pos_x = x;
   pos_y = y;

   curs_pos = &MEM_CHAR[H_CHARS*pos_y+pos_x];
} // end of gotoxy


