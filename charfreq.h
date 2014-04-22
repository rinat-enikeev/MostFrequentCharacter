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
struct CountRecord {
    unsigned int mutex;
    // given signature of mostFrequentCharacter fun accepts up to
    // int size of chars, uint is enough for this contract.
    count_record_count_t count;
};
typedef struct CountRecord CountRecord_t;

// arguments are passing through pthread method, wrap them in struct
struct CountCharsArgs {
    char* restrict charSubArray;
    int charSubArrayLength;
    int* restrict commonCountArray;
};
typedef struct CountCharsArgs CountCharsArgs_t;

// todo: supress this warnings (dunno how)
inline int _most_freq_char_optimizedNumThreads(int size);
inline void *_most_freq_char_countChars(void* x);

inline char _mostFrequentCharacter(char* str, int size)
{
    assert(size > 0); // this behavior is undefined in task
    
    int i;
    
    // 1. Initializes array of counts.
    //    Each entry in array represents number of chars
    //    found in str, plus mutex.
    CountRecord_t countRecords[CHAR_COUNT];
    static const CountRecord_t emptyRecord;
    //  todo: make "frostbyte" impl: write structs by
    //        hand in order to avoid loop in bottleneck.
    for (int i = 0; i < CHAR_COUNT; i++) {
        countRecords[i] = emptyRecord;
    }
    
    // 2. Compute optimal number of threads for given str size FIXME
    int numThreads = _most_freq_char_optimizedNumThreads(size);
    if (numThreads == 0) { numThreads = 1; }
    
    // 3. Prepare arguments for countChars func, called
    //    from newly created pthreads below.
    CountCharsArgs_t args[numThreads];
    for (i = 0; i < numThreads; i++) {
        args[i].commonCountArray = (int *)countRecords;
    }
    //  3.1 Divide str to parts in order to process it in parallel
    const int blockSize = size / numThreads;
    for (i = 0; i < numThreads - 1; i++) {
        args[i].charSubArray = str + (i * blockSize);
        args[i].charSubArrayLength = blockSize;
    }
    int lastPartIndex = ((numThreads - 1) * blockSize);
    args[numThreads - 1].charSubArray = str + lastPartIndex;
    args[numThreads - 1].charSubArrayLength = size - lastPartIndex;
    
    // 4. Run threads to count chars.
    pthread_t count_chars_threads[numThreads];
    for (i = 0; i < numThreads; i++)
    {
        pthread_create(&count_chars_threads[i], NULL, _most_freq_char_countChars, (void *) &args[i]);
    }
    
    // 5. wait for threads to finish
    for (i = 0;i < numThreads; i++) {
        pthread_join(count_chars_threads[i], NULL);
    }
    
    // 6. Find maximum. Parallelizing search seems to
    //    be not cost effective for 256 element array,
    //    so just lookup maximum value;
    char result = 0;
    count_record_count_t max = 0;
    for (i = 0; i < CHAR_COUNT; i++) {
        if (countRecords[i].count > max) {
            max = countRecords[i].count;
            result = i;
        }
    }
    
    return result;
}