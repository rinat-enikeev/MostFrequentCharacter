//
//  charfreq.h
//  CharFrequency
//
//  Created by Rinat Enikeev on 4/22/14.
//
//  Test task.
//  Provides method to count most frequent charachter in given
//  char array - mostFrequentCharacter(char* str, int size).
//
//  C99 compiler required

#include <pthread.h>
#include <assert.h>

#define CHAR_COUNT 256 // total number of possible chars

typedef unsigned int count_record_count_t;
typedef struct CountRecord {
    unsigned int mutex;
    // given signature of mostFrequentCharacter funct accepts up to
    // int size of chars, uint is enough for this contract.
    count_record_count_t count;
} CountRecord_t __attribute__ ((aligned (16)));

// arguments are passing through pthread method, wrap them in struct
typedef struct CountCharsArgs {
    char* charSubArray;
    int charSubArrayLength;
    CountRecord_t *commonCountArray;
} CountCharsArgs_t;

void most_freq_char_set_thread_count(int thrdCount);
// todo: supress this warnings (dunno how). This functions are defined in ARMMutex.s.
inline int _most_freq_char_optimizedNumThreads(int size);
inline void *_most_freq_char_countChars(void* x);


// returns most frequent character in given char* str.
// if there are several most frequent chars, returns one
// with least value.
// assumes that size is greater than zero
inline char _mostFrequentCharacter(char* str, int size)
{
    assert(size > 0); // this behavior is undefined in task
    
    if (size == 1) return *str;
    
    int i;
    
    // 1. Initializes array of counts.
    //    Each entry in array represents number of chars
    //    found in str, plus mutex.
    CountRecord_t countRecords[CHAR_COUNT];
    static const CountRecord_t emptyRecord;
    //  may: make "frostbyte" impl: write structs by
    //        hand in order to avoid loop (bottleneck?)
    for (int i = 0; i < CHAR_COUNT; i++) {
        countRecords[i] = emptyRecord;
    }
    
    // 2. Compute optimal number of threads for given str size
    int numThreads = _most_freq_char_optimizedNumThreads(size);

    // 3. Calc number of chars, storing count in countRecords[]
    if (numThreads <= 1) {
        
        // 3.1 Prepare arguments for _most_freq_char_countChars func, called
        //    from newly created pthreads below.
        CountCharsArgs_t args;
        args.commonCountArray = countRecords;
        args.charSubArray = str;
        args.charSubArrayLength = size;
        _most_freq_char_countChars((void *) &args);
        
    } else {

        // 3.2.1 Prepare arguments for _most_freq_char_countChars func, called
        //    from newly created pthreads below.
        CountCharsArgs_t args[numThreads];
        for (i = 0; i < numThreads; i++) {
            args[i].commonCountArray = countRecords;
        }
        
        //  3.2.2 Divide str to parts in order to process them in parallel
        const int blockSize = size / numThreads;
        for (i = 0; i < numThreads - 1; i++) {
            char* charPosition = str + (i* blockSize);
            args[i].charSubArray = charPosition;
            args[i].charSubArrayLength = blockSize;
        }
        int lastPartIndex = ((numThreads - 1) * blockSize);
        args[numThreads - 1].charSubArray = str + lastPartIndex;
        args[numThreads - 1].charSubArrayLength = size - lastPartIndex;
        
        // 3.2.3 Run more threads to count chars.
        //       -1 because of current thread.
        pthread_t count_chars_threads[numThreads - 1];
        for (i = 0; i < numThreads - 1; i++)
        {
            pthread_create(&count_chars_threads[i],
                           NULL,
                           _most_freq_char_countChars,
                           (void *) &args[i]);
        }
        
        // 3.2.4 Calc last chunk in current thread
        _most_freq_char_countChars((void *) &args[numThreads - 1]);
        
        // 3.2.5 wait for threads to finish
        for (i = 0;i < numThreads; i++) {
            pthread_join(count_chars_threads[i], NULL);
        }
    }
    
    // 4. Find maximum. Parallelizing search seems to
    //    be not cost effective for 256 element array,
    //    so just lookup maximum value;
    char result = 0;
    count_record_count_t max = 0;
    for (i = 0; i < CHAR_COUNT; i++) {
        if (countRecords[i].count > max) {
            max = countRecords[i].count;
            result = i - 128;
        }
    }
    
    return result;
}