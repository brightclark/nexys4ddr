#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <assert.h>
#include "icmp.h"
#include "ip4.h"
#include "mac.h"

void icmp_tx(uint8_t *ip, uint8_t type, uint8_t *ptr, uint16_t length)
{
   // Allocate space for the packet, including space for frame header, MAC, and IP header.
   icmpheader_t *icmpHdr = (icmpheader_t *) malloc(length + sizeof(icmpheader_t) + 
         sizeof(ipheader_t) + sizeof(macheader_t) + 2);

   // Fill in ICMP header
   memcpy(icmpHdr+1, ptr, length);
   icmpHdr->type = type;
   icmpHdr->chksum = 0;
   icmpHdr->chksum = ip_calcChecksum((uint16_t *) icmpHdr, (length+sizeof(icmpheader_t))/2);

   ip_tx(ip, IP4_PROTOCOL_ICMP, (uint8_t *) icmpHdr, length);

   free(icmpHdr);
} // end of sendARPReply

void icmp_rx(uint8_t *ip, uint8_t *ptr, uint16_t length)
{
   icmpheader_t *icmpHdr = (icmpheader_t *) ptr;

   if (length < sizeof(icmpheader_t))
   {
      printf("Undersized ICMP.\n");
      while(1) {} // Infinite loop to indicate error
   }

   // Check ICMP header checksum
   if (ip_calcChecksum((uint16_t *) icmpHdr, (length-sizeof(icmpheader_t))/2))
   {
      printf("ICMP header checksum error\n");
      return;
   }

   // Check ICMP type
   if (icmpHdr->type != ICMP_TYPE_REQUEST)
   {
      printf("Unexpected ICMP type\n");
      return;
   }

   // Check ICMP code
   if (icmpHdr->code != 0)
   {
      printf("Unexpected ICMP code\n");
      return;
   }

   printf("ICMP!\n");

   icmp_tx(ip, ICMP_TYPE_REPLY, (uint8_t *) icmpHdr, length);

} // end of processICMP
