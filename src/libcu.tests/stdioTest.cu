#include <cuda_runtime.h>
#include <stdiocu.h>
#include <assert.h>

#ifndef MAKEAFILE
#define MAKEAFILE
static __device__ void makeAFile(char *file)
{
	FILE *fp = fopen(file, "w");
	fprintf_(fp, "test");
	fclose(fp);
}
#endif

extern __constant__ FILE __iob_streams[CORE_MAXFILESTREAM+3];
static __global__ void g_stdio_test1()
{
	printf("stdio_test1\n");

	//// STDIN/STDOUT/STDERR ////
	//#define stdin  (&__iob_streams[0]) /* Standard input stream.  */
	//#define stdout (&__iob_streams[1]) /* Standard output stream.  */
	//#define stderr (&__iob_streams[2]) /* Standard error output stream.  */
	bool a0 = (stdin == &__iob_streams[0] && stdout == &__iob_streams[1] && stderr == &__iob_streams[2]); assert(a0);

	//// REMOVE FILE ////
	//__forceinline __device__ int remove_(const char *filename); #sentinel-branch
	/* Host Absolute */
	int a0a = remove(HostDir"missing.txt"); assert(a0a < 0);
	makeAFile(HostDir"test.txt");
	int a1a = remove(HostDir"test.txt"); assert(!a1a);

	/* Device Absolute */
	int b0a = remove(DeviceDir"missing.txt"); assert(b0a < 0);
	makeAFile(DeviceDir"test.txt");
	int b1a = remove(DeviceDir"test.txt"); assert(!b1a);

	/* Host Relative */
	chdir(HostDir);
	int c0a = remove("missing.txt"); assert(c0a < 0);
	makeAFile("test.txt");
	int c1a = remove("test.txt"); assert(!c1a);

	/* Device Relative */
	chdir(DeviceDir);
	int d0a = remove("missing.txt"); assert(d0a < 0);
	makeAFile("test.txt");
	int d1a = remove("test.txt"); assert(!d1a);

	//// RENAME FILE ////
	//__forceinline __device__ int rename_(const char *old, const char *new_); #sentinel-branch
	/* Host Absolute */
	int e0a = rename(HostDir"missing.txt", "missing.txt"); assert(e0a < 0);
	makeAFile(HostDir"test.txt");
	int e1a = rename(HostDir"test.txt", "test.txt"); assert(e1a);

	/* Device Absolute */
	int f0a = rename(DeviceDir"missing.txt", "missing.txt"); assert(f0a < 0);
	makeAFile(DeviceDir"test.txt");
	int f1a = rename(DeviceDir"test.txt", "test.txt"); assert(f1a);

	/* Host Relative */
	chdir(HostDir);
	int g0a = rename("missing.txt", "missing.txt"); assert(g0a < 0);
	makeAFile("test.txt");
	int g1a = rename("test.txt", "test.txt"); assert(g1a);

	/* Device Relative */
	chdir(DeviceDir);
	int h0a = rename("missing.txt", "missing.txt"); assert(h0a < 0);
	makeAFile("test.txt");
	int h1a = rename("test.txt", "test.txt"); assert(h1a);

	//// TMPFILE ////
	//extern __device__ FILE *tmpfile_(void);
	FILE *i0a = tmpfile();

	//// FCLOSE, FFLUSH, FREOPEN, FOPEN, FPRINTF ////
	//__forceinline __device__ int fclose_(FILE *stream, bool wait = true); #sentinel-branch
	//__forceinline __device__ int fflush_(FILE *stream); #sentinel-branch
	//__forceinline __device__ FILE *freopen_(const char *__restrict filename, const char *__restrict modes, FILE *__restrict stream) #sentinel-branch
	//__forceinline __device__ FILE *fopen_(const char *__restrict filename, const char *__restrict modes); #sentinel-branch
	//moved: extern __device__ int fprintf(FILE *__restrict stream, const char *__restrict format, ...); //extern __device__ int vfprintf_(FILE *__restrict s, const char *__restrict format, va_list va, bool wait = true);
	char buf[100];
	/* Host Absolute */
	FILE *j0a = fopen(HostDir"missing.txt", "r"); assert(j0a < 0);
	makeAFile(HostDir"test.txt");
	FILE *j1a = fopen(HostDir"test.txt", "r"); int j1b = fread(buf, 4, 1, j1a); FILE *j1c = freopen(HostDir"test.txt", "r", j1a); int j1d = fread(buf, 4, 1, j1c); int j1e = fclose(j1c); assert(j1a);
	FILE *j2a = fopen(HostDir"test.txt", "w"); int j2b = fprintf_(j2a, "test"); FILE *j2c = freopen(HostDir"test.txt", "w", j2a); int j2d = fprintf_(j2c, "test"); int j2e = fflush(j1c); int j2f = fclose(j2c); assert(j2a);

	/* Device Absolute */
	FILE *k0a = fopen(DeviceDir"missing.txt", "r"); assert(k0a < 0);
	makeAFile(DeviceDir"test.txt");
	FILE *k1a = fopen(DeviceDir"test.txt", "r"); int k1b = fread(buf, 4, 1, k1a); FILE *k1c = freopen(DeviceDir"test.txt", "r", k1a); int k1d = fread(buf, 4, 1, k1c); int k1e = fclose(k1c); assert(k1a);
	FILE *k2a = fopen(DeviceDir"test.txt", "w"); int k2b = fprintf_(k2a, "test"); FILE *k2c = freopen(DeviceDir"test.txt", "w", k2a); int k2d = fprintf_(k2c, "test"); int k2e = fflush(k1c); int k2f = fclose(k2c); assert(k2a);

	/* Host Relative */
	chdir(HostDir);
	FILE *l0a = fopen("missing.txt", "r"); assert(l0a < 0);
	makeAFile("test.txt");
	FILE *l1a = fopen("test.txt", "r"); int l1b = fread(buf, 4, 1, l1a); FILE *l1c = freopen("test.txt", "r", l1a); int l1d = fread(buf, 4, 1, l1c); int l1e = fclose(l1c); assert(l1a);
	FILE *l2a = fopen("test.txt", "w"); int l2b = fprintf_(l2a, "test"); FILE *l2c = freopen("test.txt", "w", l2a); int l2d = fprintf_(l2c, "test"); int l2e = fflush(l1c); int l2f = fclose(l2c); assert(l2a);

	/* Device Relative */
	chdir(DeviceDir);
	FILE *m0a = fopen("missing.txt", "r"); assert(m0a < 0);
	makeAFile("test.txt");
	FILE *m1a = fopen("test.txt", "r"); int m1b = fread(buf, 4, 1, m1a); FILE *m1c = freopen("test.txt", "r", m1a); int m1d = fread(buf, 4, 1, m1c); int m1e = fclose(m1c); assert(m1a);
	FILE *m2a = fopen("test.txt", "w"); int m2b = fprintf_(m2a, "test"); FILE *m2c = freopen("test.txt", "w", m2a); int m2d = fprintf_(m2c, "test"); int m2e = fflush(m1c); int m2f = fclose(m2c); assert(m2a);

	//// SETVBUF, SETBUF ////
	//__forceinline __device__ int setvbuf_(FILE *__restrict stream, char *__restrict buf, int modes, size_t n); #sentinel-branch
	//__forceinline __device__ void setbuf_(FILE *__restrict stream, char *__restrict buf); #sentinel-branch
	FILE *n0a = fopen(HostDir"test.txt", "w"); int n0b = setvbuf(n0a, nullptr, 0, 10); int n0c = fclose(n0a); assert(n0a && n0b && n0c);
	FILE *n1a = fopen(HostDir"test.txt", "w"); setbuf(n1a, nullptr); int n1b = fclose(n0a); assert(n1a && n1b);
	FILE *n2a = fopen(DeviceDir"test.txt", "w"); int n2b = setvbuf(n2a, nullptr, 0, 10); int n2c = fclose(n2a); assert(n2a && n2b && n2c);
	FILE *n3a = fopen(DeviceDir"test.txt", "w"); setbuf(n3a, nullptr); int n3b = fclose(n3a); assert(n3a && n3b);

	//// SNPRINTF, PRINTF, SPRINTF ////
	//#define sprintf(s, format, ...) snprintf_(s, 0xffffffff, format, __VA_ARGS__)
	//moved: extern __device__ int snprintf(char *__restrict s, size_t maxlen, const char *__restrict format, ...); //extern __device__ int vsnprintf_(char *__restrict s, size_t maxlen, const char *__restrict format, va_list va);
	////moved: extern __device__ int printf(const char *__restrict format, ...);
	////moved: extern __device__ int sprintf(char *__restrict s, const char *__restrict format, ...); //__forceinline __device__ int vsprintf_(char *__restrict s, const char *__restrict format, va_list va);
	int o0a = snprintf(buf, sizeof(buf), "%d", 1); bool o0b = !strcmp(buf, "1"); assert(o0a && o0b);
	//skipped: printf("%d", 1);
	int o1a = sprintf(buf, "%d", 1); bool o1b = !strcmp(buf, "1"); assert(o1a && o1b);

	//// FSCANF, SCANF, SSCANF ////
	//moved: extern __device__ int fscanf(FILE *__restrict stream, const char *__restrict format, ...); //extern __device__ int vfscanf_(FILE *__restrict s, const char *__restrict format, va_list va, bool wait = true);
	//moved: extern __device__ int scanf(const char *__restrict format, ...); //__forceinline __device__ int vscanf_(const char *__restrict format, va_list va);
	//moved: extern __device__ int sscanf(const char *__restrict s, const char *__restrict format, ...); //extern __device__ int vsscanf_(const char *__restrict s, const char *__restrict format, va_list va);
	FILE *p0a = fopen(HostDir"test.txt", "r"); int p0b = fscanf(p0a, "%s", buf); int p0c = fclose(p0a); bool p0d = !strcmp(buf, "1"); assert(p0a && p0b && p0c && p0d);
	FILE *p1a = fopen(DeviceDir"test.txt", "r"); int p1b = fscanf(p1a, "%s", buf); int p1c = fclose(p1a); bool p1d = !strcmp(buf, "1"); assert(p1a && p1b && p1c && p1d);
	//skipped: scanf("%s", buf);
	int p2a = sscanf("test", "%s", buf); bool p2b = !strcmp(buf, "1"); assert(p2a && p2b);

	//// FGETC, GETCHAR, GETC, FPUTC, PUTCHAR, PUTC, UNGETC ////
	//__forceinline __device__ int fgetc_(FILE *stream); #sentinel-branch
	//__forceinline __device__ int getchar_(void);
	////sky: #define getc(fp) __GETC(fp)
	//__forceinline __device__ int fputc_(int c, FILE *stream, bool wait = true); #sentinel-branch
	//__forceinline __device__ int putchar_(int c);
	////sky: #define putc(ch, fp) __PUTC(ch, fp)
	//__forceinline __device__ int ungetc_(int c, FILE *stream, bool wait = true); #sentinel-branch

	//// FGETS, FPUTS, PUTS ////
	//__forceinline __device__ char *fgets_(char *__restrict s, int n, FILE *__restrict stream); #sentinel-branch
	//__forceinline __device__ int fputs_(const char *__restrict s, FILE *__restrict stream, bool wait = true); #sentinel-branch
	//__forceinline __device__ int puts_(const char *s);

	//__forceinline __device__ size_t fread_(void *__restrict ptr, size_t size, size_t n, FILE *__restrict stream, bool wait = true); #sentinel-branch
	//__forceinline __device__ size_t fwrite_(const void *__restrict ptr, size_t size, size_t n, FILE *__restrict stream, bool wait = true); #sentinel-branch

	//// FSEEK, FTELL, REWING, FSEEKO, FGETPOS, FSETPOS ///
	//__forceinline __device__ int fseek_(FILE *stream, long int off, int whence); #sentinel-branch
	//__forceinline __device__ long int ftell_(FILE *stream); #sentinel-branch
	//__forceinline __device__ void rewind_(FILE *stream); #sentinel-branch
	//extern __device__ int fseeko_(FILE *stream, __off_t off, int whence);
	//__forceinline __device__ int fgetpos_(FILE *__restrict stream, fpos_t *__restrict pos); #sentinel-branch
	//__forceinline __device__ int fsetpos_(FILE *stream, const fpos_t *pos); #sentinel-branch

	//// CLEARERR, FERROR, PERROR ////
	//__forceinline __device__ void clearerr_(FILE *stream); #sentinel-branch
	//__forceinline __device__ int ferror_(FILE *stream); #sentinel-branch
	//extern __device__ void perror_(const char *s);

	//// FEOF ////
	//__forceinline __device__ int feof_(FILE *stream); #sentinel-branch

	//// FILENO ////
	//__forceinline __device__ int fileno_(FILE *stream); #sentinel-branch

	//// EXT: MTAGPRINTF, MPRINTF, MNPRINTF ////
	//__device__ char *vmtagprintf_(void *tag, const char *format, va_list va);
	//__device__ char *vmprintf_(const char *format, va_list va);
	//__device__ char *vmsnprintf_(char *__restrict s, size_t maxlen, const char *format, va_list va);

}
cudaError_t stdio_test1() { g_stdio_test1<<<1, 1>>>(); return cudaDeviceSynchronize(); }



#pragma region _64bit

static __global__ void g_stdio_64bit()
{
	printf("stdio_64bit\n");
	/*
	unsigned long long val = -1;
	void *ptr = (void *)-1;
	printf("%p\n", ptr);

	sscanf("123456789", "%Lx", &val);
	printf("val = %Lx\n", val);
	*/
}
cudaError_t stdio_64bit() { g_stdio_64bit<<<1, 1>>>(); return cudaDeviceSynchronize(); }

#pragma endregion

#pragma region Ganging

static __global__ void g_stdio_ganging()
{
	printf("stdio_ganging\n");
}
cudaError_t stdio_ganging() { g_stdio_ganging<<<1, 1>>>(); return cudaDeviceSynchronize(); }

#pragma endregion

#pragma region scanf

static __global__ void g_stdio_scanf()
{
	printf("stdio_scanf\n");
	/*
	const char *buf = "hello world";
	char *ps = NULL, *pc = NULL;
	char s[6], c;

	/ Check that %[...]/%c work. /
	sscanf(buf, "%[a-z] %c", s, &c);
	/ Check that %m[...]/%mc work. /
	sscanf(buf, "%m[a-z] %mc", &ps, &pc);

	if (strcmp(ps, "hello") != 0 || *pc != 'w' || strcmp(s, "hello") != 0 || c != 'w')
	return 1;

	free(ps);
	free(pc);

	return 0;
	*/
}
cudaError_t stdio_scanf() { g_stdio_scanf<<<1, 1>>>(); return cudaDeviceSynchronize(); }

#pragma endregion
