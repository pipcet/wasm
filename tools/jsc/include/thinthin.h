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
