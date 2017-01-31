#ifndef __TESTLIB_H
#define __TESTLIB_H

#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h>
#include <time.h>
#include <string.h>

// This file has a hand-written .h file so that test files written in C (e.g.
// main-Poly1305.c) can use the functions from this file too (e.g.
// [compare_and_print]).

// Functions for F*-written tests, exposed via TestLib.fsti
void TestLib_touch(int32_t);
void TestLib_check(int32_t, int32_t);

// These functions are also called by HACL
void TestLib_compare_and_print(const char *txt, uint8_t *reference, uint8_t *output, int size);

void *TestLib_unsafe_malloc(size_t size);
void TestLib_print_clock_diff(clock_t t1, clock_t t2);
void TestLib_perr(unsigned int err_code);

#define TestLib_uint8_p_null NULL
#define TestLib_uint32_p_null NULL
#define TestLib_uint64_p_null NULL

typedef unsigned long long cycles;

static inline cycles TestLib_cpucycles(void)
{
  uint32_t hi, lo;
  __asm__ __volatile__ ("rdtscp" : "=a"(lo), "=d"(hi) : : "%rcx" );
  return ( (uint64_t)lo)|( ((uint64_t)hi)<<32 );
}
void TestLib_print_cycles_per_round(cycles c1, cycles c2, uint32_t rounds);


#endif
