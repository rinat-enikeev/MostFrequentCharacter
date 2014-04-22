//
//  charfreq.c
//  CharFrequency
//
//  Created by Rinat Enikeev on 4/22/14.
//  Copyright (c) 2014 Rinat Enikeev. All rights reserved.
//
#include "charfreq.h"

// todo: supress this warnings (dunno how)
extern void most_freq_char_lock_mutex(void * mutex);
extern void most_freq_char_unlock_mutex(void * mutex);

// scans part of char array and increments char counts in
// common (for pthreads) array.
// synchronized by ARM specific mutex impl: see ARMMutex.s.
extern inline void *_most_freq_char_countChars(void* x)
{
    // 1. Get args
    CountCharsArgs_t *args = ((CountCharsArgs_t *) x);
    CountRecord_t* restrict commonCountRecords = ((CountRecord_t *)args->commonCountArray);
    char* restrict charSubArray = args->charSubArray;
    int charSubArrayLength = args->charSubArrayLength;
    
    // 2. Scan char array and increment count
    for (int i = 0; i < charSubArrayLength; i++) {
        char scannedChar = charSubArray[i];
        CountRecord_t* record = commonCountRecords+scannedChar;
        most_freq_char_lock_mutex(&record->mutex);
        record->count++;
        most_freq_char_unlock_mutex(&record->mutex);
    }
    
    return NULL;
}

// todo: determine run tests to find optimal number of threads
extern inline int _most_freq_char_optimizedNumThreads(int size)
{
    return size;
}

extern inline char _mostFrequentCharacter(char* str, int size);