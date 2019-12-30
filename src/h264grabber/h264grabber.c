/*
 * Copyright (c) 2019 roleo.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

/*
 * Scans the buffer and sends h264 frames to stdout.
 */

//USAGE ./h264grabber HIGH/LOW --debug

#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <dirent.h>
#include <getopt.h>

#define RESOLUTION_LOW 360
#define RESOLUTION_HIGH 1080

unsigned char SPS[] = { 0x00, 0x00, 0x00, 0x01 };

// Returns the 1st process id corresponding to pname
int pidof(const char *pname)
{
  DIR *dirp;
  FILE *fp;
  struct dirent *entry;
  char path[1024], read_buf[1024];
  int ret = 0;

  dirp = opendir ("/proc/");
  if (dirp == NULL) {
    fprintf(stderr, "error opening /proc");
    return 0;
  }

  while ((entry = readdir (dirp)) != NULL) {
    if (atoi(entry->d_name) > 0) {
      sprintf(path, "/proc/%s/comm", entry->d_name);

      /* A file may not exist, Ait may have been removed.
       * dut to termination of the process. Actually we need to
       * make sure the error is actually file does not exist to
       * be accurate.
       */
      fp = fopen (path, "r");
      if (fp != NULL) {
        fscanf (fp, "%s", read_buf);
        if (strcmp (read_buf, pname) == 0) {
            ret = atoi(entry->d_name);
            fclose (fp);
            break;
        }
        fclose (fp);
      }
    }
  }

  closedir (dirp);
  return ret;
}

// Converts virtual address to physical address
unsigned int rmm_virt2phys(unsigned int inAddr) {
    int pid;
    unsigned int outAddr;
    char sInAddr[16];
    char sMaps[1024];
    FILE *fMaps;
    char *p;
    char *line;
    size_t lineSize;

    line = (char  *) malloc(1024);

    pid = pidof("rmm");
    sprintf(sMaps, "/proc/%d/maps", pid);
    fMaps = fopen(sMaps, "r");
    sprintf(sInAddr, "%08x", inAddr);
    while (getline(&line, &lineSize, fMaps) != -1) {
        if (strncmp(line, sInAddr, 8) == 0)
            break;
    }

    p = line;
    p = strchr(p, ' ');
    p++;
    p = strchr(p, ' ');
    p++;
    p[8] = '\0';
    sscanf(p, "%x", &outAddr);
    free(line);
    fclose(fMaps);

    return outAddr;
}

void print_usage(char *progname)
{
    fprintf(stderr, "\nUsage: %s [-r RES] [-d]\n\n", progname);
    fprintf(stderr, "\t-r RES, --resolution RES\n");
    fprintf(stderr, "\t\tset resolution: LOW or HIGH (default HIGH)\n");
    fprintf(stderr, "\t-d, --debug\n");
    fprintf(stderr, "\t\tenable debug\n");
    fprintf(stderr, "\t-h, --help\n");
    fprintf(stderr, "\t\tprint this help\n");
}

int main(int argc, char **argv)
{
    int c, debug = 0;
    const char memDevice[] = "/dev/mem";
    int resolution = RESOLUTION_HIGH;
    FILE *fPtr, *fLen, *fTime;
    int fMem;
    unsigned int ivAddr, ipAddr;
    unsigned int size;
    unsigned char *addr;
    char filLenFile[1024];
    char timeStampFile[1024];
    //unsigned char buffer[262144];
    unsigned char *buffer = malloc(sizeof(unsigned char)*262144);
    int len;
    unsigned int time, oldTime = 0;
    int stream_started = 0;
    

    resolution = RESOLUTION_LOW;

    if (argc > 1 && strcmp(argv[1], "HIGH") == 0) 
    {
        resolution == RESOLUTION_HIGH;
    }

    if (argc > 2 && strcmp(argv[2], "--debug") == 0) 
    {
        debug=1;
    }
    

    if (debug) fprintf (stderr, "WELCOME\n");
    if (debug) fprintf(stderr, "Resolution: %d\n", resolution);
    if (resolution == RESOLUTION_LOW) {
        fPtr = fopen("/proc/mstar/OMX/VMFE1/ENCODER_INFO/OBUF_pBuffer", "r");
        fLen = fopen("/proc/mstar/OMX/VMFE1/ENCODER_INFO/OBUF_nAllocLen", "r");
    } else {
        fPtr = fopen("/proc/mstar/OMX/VMFE0/ENCODER_INFO/OBUF_pBuffer", "r");
        fLen = fopen("/proc/mstar/OMX/VMFE0/ENCODER_INFO/OBUF_nAllocLen", "r");
    }
    fscanf(fPtr, "%x", &ivAddr);
    fclose(fPtr);
    fscanf(fLen, "%d", &size);
    fclose(fLen);
    ipAddr = rmm_virt2phys(ivAddr);

    if (debug) fprintf(stderr, "vaddr: 0x%08x - paddr: 0x%08x - size: %u\n", ivAddr, ipAddr, size);

    fMem = open(memDevice, O_RDONLY); // | O_SYNC);
    if (fMem < 0) {
        fprintf(stderr, "Failed to open the /dev/mem\n");
        return -1;
    }

    addr = (unsigned char *) (mmap(NULL, size, PROT_READ, MAP_SHARED, fMem, ipAddr));
    if (addr == MAP_FAILED) {
        fprintf(stderr, "Failed to map memory\n");
        return -1;
    }

    close(fMem);

    if (resolution == RESOLUTION_LOW) {
        sprintf(filLenFile, "/proc/mstar/OMX/VMFE1/ENCODER_INFO/OBUF_nFilledLen");
        sprintf(timeStampFile, "/proc/mstar/OMX/VMFE1/ENCODER_INFO/OBUF_nTimeStamp");
    } else {
        sprintf(filLenFile, "/proc/mstar/OMX/VMFE0/ENCODER_INFO/OBUF_nFilledLen");
        sprintf(timeStampFile, "/proc/mstar/OMX/VMFE0/ENCODER_INFO/OBUF_nTimeStamp");
    }

    if (debug) fprintf (stderr, "Read memory OK\n");

    while(!stream_started) {
        if (debug) fprintf (stderr, "Stream not started\n");
        fTime = fopen(timeStampFile, "r");
        fscanf(fTime, "%u", &time);
        fclose(fTime);

        if (time == oldTime) {
            usleep(200);
            continue;
        }

        fLen = fopen(filLenFile, "r");
        fscanf(fLen, "%d", &len);
        fclose(fLen);
        
        //unsigned char buffer[262144] = {};


        memcpy(buffer, addr, len); //segmentation fault

        //printf("The size of buffer is %lu\n", (unsigned long)sizeof(buffer));
        //printf("The size of addr is %lu\n", (unsigned long)sizeof(addr));
        //printf("The size of SPS is %lu\n", (unsigned long)sizeof(SPS));
        //printf("The len is %d\n", len);

        /*
        printf("hashedChars: ");
        int i = 0;
        for (i = 0; i < 32; i++){
            printf("%x", buffer[i]);
        }
        printf("\n");
        */



        int res = memcmp(SPS, buffer, sizeof(SPS));
        if (res == 0) {
            oldTime = time;
            if (!debug) {
                fwrite(buffer, 1, len, stdout);
            }
            stream_started = 1;
        }
    }
    while(1) {
        fTime = fopen(timeStampFile, "r");
        fscanf(fTime, "%u", &time);
        fclose(fTime);
        if (debug) fprintf(stderr, "time: %u\n", time);

        if (time == oldTime) {
            usleep(8000); //200
            continue;
        }

        usleep(100);

        fLen = fopen(filLenFile, "r");
        fscanf(fLen, "%d", &len);
        fclose(fLen);
        if (debug) fprintf(stderr, "time: %u - len: %d\n", time, len);
        
        memcpy(buffer, addr, len);
        oldTime = time;
        
        if (!debug) {
                fwrite(buffer, 1, len, stdout);
        }
        
       
    }
     munmap(addr, size);
 
}
