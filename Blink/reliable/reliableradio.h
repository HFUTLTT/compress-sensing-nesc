#ifndef RELIABLERADIO_H
#define RELIABLERADIO_H

#define BASEID 1234
#define SAMPLE_NUM 16
#define ACK_TIMEOUT 82

enum { 
  AM_ACK_MSG = 22,
  AM_DATA_MSG = 23 
};

typedef nx_struct reliable_msg {
  nx_uint16_t nodeid;
  nx_uint32_t start;
  nx_uint32_t stop;
  nx_uint16_t cookie;
  nx_uint16_t blkno;
  nx_uint16_t pktno;
  nx_uint16_t dropnum;
  nx_uint16_t data[];
} reliable_msg_t;

typedef nx_struct ack_msg {
  nx_uint16_t cookie;
} ack_msg_t;

#endif
