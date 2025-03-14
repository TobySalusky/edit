#ifdef _WIN32 // WINDOWS ===============================

// Windows does not include all POSIX functions, so we patch in the ones we need here!

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>

#include <direct.h>
// ^ gives us _mkdir

// stole from: https://stackoverflow.com/questions/8512958/is-there-a-windows-variant-of-strsep-function
static inline char* strsep(char** stringp, const char* delim) {
  char* start = *stringp;
  char* p;

  p = (start != NULL) ? strpbrk(start, delim) : NULL;

  if (p == NULL)
  {
    *stringp = NULL;
  }
  else
  {
    *p = '\0';
    *stringp = p + 1;
  }

  return start;
}

// stole from: https://stackoverflow.com/questions/78655661/is-there-a-windows-equivalent-of-strndup
// static inline size_t strnlen(const char* src, size_t n) {
//     size_t len = 0;
//     while (len < n && src[len]) { len++; }
//     return len;
// }

// stole from: https://stackoverflow.com/questions/78655661/is-there-a-windows-equivalent-of-strndup
static inline char* strndup(const char* s, size_t n) {
    size_t len = strnlen(s, n);
    char* p = (char*) malloc(len + 1);
    if (p) {
        memcpy(p, s, len);
        p[len] = '\0';
    }
    return p;
}

static inline int rpp_std_mkdir(const char* f) {
	return _mkdir(f);
}

// stole from (edited somewhat): https://github.com/sol-prog/fgets-getline-usage-examples/blob/master/t3.c#L13
/*
POSIX getline replacement for non-POSIX systems (like Windows)
Differences:
    - the function returns int64_t instead of ssize_t
    - does not accept NUL characters in the input file
Warnings:
    - the function sets EINVAL, ENOMEM, EOVERFLOW in case of errors. The above are not defined by ISO C17,
    but are supported by other C compilers like MSVC
*/
static inline size_t getline(char** line, size_t* len, FILE* fp) {
    // Check if either line, len or fp are NULL pointers
    if (line == NULL || len == NULL || fp == NULL) {
        errno = EINVAL;
        return -1;
    }
    
    // Use a chunk array of 128 bytes as parameter for fgets
    char chunk[128];

    // Allocate a block of memory for *line if it is NULL or smaller than the chunk array
    if(*line == NULL || *len < sizeof(chunk)) {
        *len = sizeof(chunk);
        if((*line = (char*) malloc(*len)) == NULL) {
            errno = ENOMEM;
            return -1;
        }
    }

    // "Empty" the string
    (*line)[0] = '\0';

    while(fgets(chunk, sizeof(chunk), fp) != NULL) {
        // Resize the line buffer if necessary
        size_t len_used = strlen(*line);
        size_t chunk_used = strlen(chunk);

        if(*len - len_used < chunk_used) {
            // Check for overflow
            if(*len > SIZE_MAX / 2) {
                errno = EOVERFLOW;
                return -1;
            } else {
                *len *= 2;
            }
            
            if((*line = (char*) realloc(*line, *len)) == NULL) {
                errno = ENOMEM;
                return -1;
            }
        }

        // Copy the chunk to the end of the line buffer
        memcpy(*line + len_used, chunk, chunk_used);
        len_used += chunk_used;
        (*line)[len_used] = '\0';

        // Check if *line contains '\n', if yes, return the *line length
        if((*line)[len_used - 1] == '\n') {
            return len_used;
        }
    }

    return -1;
}


#else // MAC ====================================
#include <sys/stat.h>

static inline int rpp_std_mkdir(const char* f) {
	return mkdir(f, 511); // 511 for flags we want :)
}

#endif // =======================================
