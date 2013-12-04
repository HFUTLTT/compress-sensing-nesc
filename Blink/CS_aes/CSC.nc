#include "printfZ1.h"
#include "main.h"
#include "compress_sensing.h"
#include "reliableradio.h"
#include "calib.h"

module CSC @safe() {
  uses interface Leds;
  uses interface Boot;
  uses interface Random;
  uses interface Compressor;
  uses interface SplitControl as RadioControl;
  /* uses interface Timer<TMilli> as Timer; */
  uses interface Alarm<TMilli, uint16_t>;
  uses interface LocalTime<TMilli>;
  uses interface SPlugControl;
  uses interface ReliableTx;
  uses interface AES;
}

implementation {

  uint32_t counter=0;
  uint16_t val2;
  uint32_t packet_start = 0;
  uint32_t packet_n = 0;
  uint32_t packet_acc_trans = 0;
  uint32_t start, stop;

  // for AES
  uint8_t exp[240];
  uint8_t K[16] = {
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
    0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F,
  };


  // len is the number of ENTRY
  void enc(ACC_ENTRY* src, uint16_t len)
  {
    uint16_t i;
    uint32_t start_time, end_time;
    start_time = call LocalTime.get();
    for (i=0;i < len; i+= (16/sizeof(ACC_ENTRY)))
      call AES.encrypt((uint8_t*)(&src[i]),exp,(uint8_t*)(&src[i]));
    end_time = call LocalTime.get();
    printfz1("Encrypt %4d bytes for : %lu ms\n", len*sizeof(ACC_ENTRY) ,end_time-start_time);
  }



  event void Compressor.complete(uint16_t compressed_size) {
    uint16_t i;	

    for (i=0; i< compressed_size; ++i)
      printfz1("%lu ",output_buffer[!clean_buffer][i]);
    printfz1("\n");

    enc( output_buffer[!clean_buffer], COMPRESS_SIZE);

    call ReliableTx.cancel();
    call ReliableTx.send( (uint16_t*) output_buffer[!clean_buffer], compressed_size * RATIO, start, stop);
    packet_start = call LocalTime.get();

    //printfz1("Transmission done.\n");
  }

  event void Boot.booted() {
    printfz1_init();

    call SPlugControl.init();
    call SPlugControl.setState(SPLUG_ON_STATE);

    call ReliableTx.init();    

    /* call Timer.startPeriodic(SAMPLE_RATE); */
    call Alarm.start(SAMPLE_RATE);
   	call RadioControl.start();
    call AES.keyExpansion(exp,K);
  }

  event void RadioControl.startDone(error_t err) {
    if (err != SUCCESS)
      call RadioControl.start();
  }

  event void RadioControl.stopDone(error_t err) {}

  /* event void Timer.fired() {} */

  async event void Alarm.fired() {
    uint16_t power;

#ifdef TEST
    uint16_t power_data[] = {25,27,25,25,27,24,24,26,24,25,24,25,24,26,24,24,26,24,25,27,22,27,24,25,24,25,25,25,24,27,25,24};
    call Alarm.start(SAMPLE_RATE);
    power = power_data[counter%32];
#else
    call Alarm.start(SAMPLE_RATE);
    power = convert(call SPlugControl.read(RAENERGY), TOS_NODE_ID, SAMPLE_RATE);
    /* power = call SPlugControl.read(RAENERGY); */
#endif

    // Timestamp
    if (counter == 0)
      start = call LocalTime.get();
    else if (counter == BLOCK_SIZE - 1)
      stop = call LocalTime.get();

    if (counter == 0)
      call Compressor.set(NULL, BLOCK_SIZE);
    call Compressor.compress(power);
    counter++;
    if (counter >= BLOCK_SIZE)
      counter = 0;
  }

  event void ReliableTx.sendDone(uint16_t dropnum) {
    packet_acc_trans += call LocalTime.get() - packet_start;
    //printfz1("Retry: %u\n", dropnum);
    //printfz1("Transmission: %lu/%lu\n", packet_acc_trans,++packet_n);
    packet_start = call LocalTime.get();
  }
}

