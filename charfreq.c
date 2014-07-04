//
//  charfreq.c
//  CharFrequency
//
//  Created by Rinat Enikeev on 4/22/14.
//  Copyright (c) 2014 Rinat Enikeev. All rights reserved.
//
#include "charfreq.h"

extern void most_freq_char_lock_mutex(void * mutex);
extern void most_freq_char_unlock_mutex(void * mutex);

// as in task - 2 core ARM processor
static int most_freq_char_num_of_threads = 2;

// scans part of char array and increments char counts in
// common (for pthreads) array.
// synchronized by ARM specific mutex impl: see ARMMutex.s.
extern inline void *_most_freq_char_countChars(void* x)
{
    // 1. Get args
    CountCharsArgs_t* args = ((CountCharsArgs_t *) x);
    CountRecord_t* commonCountRecords = ((CountRecord_t *)args->commonCountArray);
    char* charSubArray = args->charSubArray;
    __builtin_prefetch(charSubArray);
    int charSubArrayLength = args->charSubArrayLength;
    
    // 2. Scan char array and increment count
    for (int i = 0; i < charSubArrayLength; i++) {
        char scannedChar = charSubArray[i];
        // chars start from -128
        CountRecord_t* record = commonCountRecords+(scannedChar + 128);
        
        // critical section, lock count array element
        most_freq_char_lock_mutex(&record->mutex);
        record->count++;
        most_freq_char_unlock_mutex(&record->mutex);
    }
    
    return NULL;
}

// may: add device specific values
extern inline int _most_freq_char_optimizedNumThreads(int size)
{
    return most_freq_char_num_of_threads;
}

// sets most_freq_char_num_of_threads for test purposes.
void most_freq_char_set_thread_count(int thrdCount)
{
    most_freq_char_num_of_threads = thrdCount;
}

extern inline char _mostFrequentCharacter(char* str, int size);