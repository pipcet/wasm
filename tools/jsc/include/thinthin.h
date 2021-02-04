#define thinthin_tablesize_default 65536
#define thinthin_memsize_default (128 * 1024 * 1024LL)
#define thinthin_stacksize_default (1 * 1024 * 1024LL)
#define thinthin_stackbot_default (thinthin_memsize_default - thinthin_stacksize_default)

const struct {
  long long tablesize;
  long long memsize;
  long long stacksize;
  long long stackbottom;
} default_sizes = {
  thinthin_tablesize_default,
  thinthin_memsize_default,
  thinthin_stacksize_default,
  thinthin_stackbot_default,
};

typedef struct {
  long long fp;
  long long a0;
  long long a1;
  long long a2;
  long long a3;
} thinthin_eh_frame;
