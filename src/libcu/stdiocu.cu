#include <stdiocu.h>
#include <stdlibcu.h>
#include <stddefcu.h>
#include <stdargcu.h>
#include <ctypecu.h>
#include <assert.h>
#include <sentinel-stdiomsg.h>

#include <ext\hash.h>
#include <ext\memfile.h>
#include <_dirent.h>
#include <unistdcu.h>
#include <errnocu.h>
#include <fcntl.h>

#define CORE_MAXLENGTH 1000000000

//__device__ int _close(int a) { io_close msg(a); return msg.RC; }

__BEGIN_DECLS;

//__constant__ FILE file0 = {};
//__constant__ FILE file1 = {};
//__constant__ FILE file2 = {};
//__constant__ FILE *__iob_file[3] = { &file0, &file1, &file2 };
__constant__ FILE __iob_file[CORE_MAXFILESTREAM];

__device__ hash_t __iob_dir = HASHINIT;

/* Remove file FILENAME.  */
__device__ int remove_(const char *filename)
{
	if (filename[0] != ':') {
		stdio_remove msg(filename); return msg.RC;
	}
	int saved_errno = errno;
	int rv = rmdir(filename);
	if ((rv < 0) && (errno == ENOTDIR)) {
		_set_errno(saved_errno); // Need to restore errno.
		rv = _unlink(filename);
	}
	return rv;
}

/* Rename file OLD to NEW.  */
__device__ int rename_(const char *old, const char *new_)
{
	if (old[0] != ':') {
		stdio_rename msg(old, new_); return msg.RC;
	}
	void *entry = hashFind(&__iob_dir, old);
	panic("Not Implemented");
	return 0;
}

/* Remove file FILENAME.  */
__device__ int _unlink_(const char *filename)
{
	if (filename[0] != ':') {
		stdio_unlink msg(filename); return msg.RC;
	}
	void *entry = hashFind(&__iob_dir, filename);
	panic("Not Implemented");
	return 0;
}

/* Create a temporary file and open it read/write. */
#ifndef __USE_FILE_OFFSET64
__device__ FILE *tmpfile_(void)
{
	panic("Not Implemented");
	return nullptr;
}
#endif

/* Close STREAM. */
__device__ int fclose_device(FILE *stream)
{
	return 0; 
}

/* Flush STREAM, or all streams if STREAM is NULL. */
__device__ int fflush_device(FILE *stream)
{ 
	return 0; 
}

__device__ FILE *fopen_device(const char *__restrict filename, const char *__restrict modes, FILE *__restrict stream)
{
	// Parse the specified mode.
	unsigned short openMode = O_RDONLY;
	if (*modes != 'r') { // Not read...
		openMode = (O_WRONLY | O_CREAT | O_TRUNC);
		if (*modes != 'w') { // Not write (create or truncate)...
			openMode = (O_WRONLY | O_CREAT | O_APPEND);
			if (*modes != 'a') {	// Not write (create or append)...
				_set_errno(EINVAL); // So illegal mode.
				if (stream)
					fclose_device(stream);
				return nullptr;
			}
		}
	}
	if (modes[1] == 'b') // Binary mode (NO-OP currently).
		++modes;
	if (modes[1] == '+') { // Read and Write.
		++modes;
		openMode |= (O_RDONLY | O_WRONLY);
		openMode += (O_RDWR - (O_RDONLY | O_WRONLY));
	}

	// Need to allocate a FILE (not freopen).
	if (!stream) {
		stream = &__iob_file[4];
		stream->_file = 4;
	}
	stream->_flag = openMode;
	stream->_base = nullptr;

	void *ent = hashFind(&__iob_dir, filename);
	if (!ent) {
		if ((openMode & O_RDONLY)) {
			_set_errno(EINVAL); // So illegal mode.
			if (stream)
				fclose_device(stream);
			return nullptr;
		}
		ent = malloc(_ROUND64(sizeof(dirent)) + __sizeofMemfile_t);
		if (hashInsert(&__iob_dir, filename, ent))
			panic("removed file");
		dirent *dirEnt = (dirent *)ent;
		dirEnt->d_type = 1;
		strcpy(dirEnt->d_name, filename);
		memfile_t *memFile = (memfile_t *)((char *)ent + __sizeofMemfile_t);
		memfileOpen(memFile);
		stream->_base = (char *)memFile;
	}
	return stream;
}

/* Open a file, replacing an existing stream with it. */
__device__ FILE *freopen_(const char *__restrict filename, const char *__restrict modes, FILE *__restrict stream)
{
	if (filename[0] != ':') {
		stdio_freopen msg(filename, modes, stream); return msg.RC;
	}
	if (stream)
		fclose_device(stream);
	FILE *fp = fopen_device(filename, modes, stream);
	return fp;
}

#ifdef __USE_LARGEFILE64
/* Open a file, replacing an existing stream with it. */
__device__ FILE *freopen64_(const char *__restrict filename, const char *__restrict modes, FILE *__restrict stream)
{
	if (filename[0] != ':') {
		stdio_freopen msg(filename, modes, stream); return msg.RC;
	}
	panic("Not Implemented");
	return nullptr;
}
#endif

/* Make STREAM use buffering mode MODE. If BUF is not NULL, use N bytes of it for buffering; else allocate an internal buffer N bytes long.  */
__device__ int setvbuf_device(FILE *__restrict stream, char *__restrict buf, int modes, size_t n)
{
	panic("Not Implemented");
	return 0;
}

/* Write formatted output to S from argument list ARG.  */
#ifdef __CUDA_ARCH__
__device__ int vsnprintf_(char *__restrict s, size_t maxlen, const char *__restrict format, va_list va)
{
	if (maxlen <= 0) return -1;
	strbld_t b;
	strbldInit(&b, (char *)s, (int)maxlen, 0); b.allocType = 0;
	strbldAppendFormat(&b, false, format, va);
	strbldToString(&b);
	return b.index;
}
#endif

/* Write formatted output to S from argument list ARG. */
#ifdef __CUDA_ARCH__
__device__ int vfprintf_(FILE *__restrict s, const char *__restrict format, va_list va, bool wait)
{
	char base[PRINT_BUF_SIZE];
	strbld_t b;
	strbldInit(&b, base, sizeof(base), CORE_MAXLENGTH);
	strbldAppendFormat(&b, false, format, va);
	const char *v = strbldToString(&b);
	stdio_fputs msg(wait, format, s);
	free((void *)v);
	return msg.RC; 
}
#endif

/* Read formatted input from S into argument list ARG.  */
//__device__ int vfscanf_(FILE *__restrict s, const char *__restrict format, va_list va)
//{
//	panic("Not Implemented");
//	return 0;
//}

/* Read formatted input from S into argument list ARG.  */
__device__ int vsscanf_(const char *__restrict s, const char *__restrict format, va_list va)
{
	panic("Not Implemented");
	return 0;
}

/* Read a character from STREAM.  */
__device__ int fgetc_device(FILE *stream)
{
	panic("Not Implemented");
	return 0;
}

/* Write a character to STREAM.  */
__device__ int fputc_device(int c, FILE *stream)
{
	if (stream == stdout || stream == stderr)
		printf("%c", c);
	return 0;
}

/* Get a newline-terminated string of finite length from STREAM.  */
__device__ char *fgets_device(char *__restrict s, int n, FILE *__restrict stream)
{
	panic("Not Implemented");
	return nullptr;
}

/* Write a string to STREAM.  */
__device__ int fputs_device(const char *__restrict s, FILE *__restrict stream)
{
	if (stream == stdout || stream == stderr)
		printf(s);
	return 0;
}

/* Push a character back onto the input buffer of STREAM.  */
__device__ int ungetc_device(int c, FILE *stream)
{
	panic("Not Implemented");
	return 0;
}

/* Read chunks of generic data from STREAM.  */
__device__ size_t fread_device(void *__restrict ptr, size_t size, size_t n, FILE *__restrict stream)
{
	memfile_t *f;
	if (!stream || !(f = (memfile_t *)stream->_base))
		panic("fwrite: !stream");
	size *= n;
	memfileRead(f, ptr, size*n, 0);
	return size;
}

/* Write chunks of generic data to STREAM.  */
__device__ size_t fwrite_device(const void *__restrict ptr, size_t size, size_t n, FILE *__restrict stream)
{
	memfile_t *f;
	if (!stream || !(f = (memfile_t *)stream->_base))
		panic("fwrite: !stream");
	size *= n;
	memfileWrite(f, ptr, size, 0);
	return size;
}

/* Seek to a certain position on STREAM.  */
__device__ int fseek_device(FILE *stream, long int off, int whence)
{
	panic("Not Implemented");
	return 0;
}

/* Return the current position of STREAM.  */
__device__ long int ftell_device(FILE *stream)
{
	panic("Not Implemented");
	return 0;
}

/* Rewind to the beginning of STREAM.  */
__device__ void rewind_device(FILE *stream)
{
	panic("Not Implemented");
	return;
}

/* Get STREAM's position.  */
__device__ int fgetpos_device(FILE *__restrict stream, fpos_t *__restrict pos)
{
	panic("Not Implemented");
	return 0;
}

/* Set STREAM's position.  */
__device__ int fsetpos_device(FILE *stream, const fpos_t *pos)
{
	panic("Not Implemented");
	return 0;
}

/* Clear the error and EOF indicators for STREAM.  */
__device__ void clearerr_device(FILE *stream)
{
	panic("Not Implemented");
}

/* Return the EOF indicator for STREAM.  */
__device__ int feof_device(FILE *stream)
{
	panic("Not Implemented");
	return 0;
}

/* Return the error indicator for STREAM.  */
__device__ int ferror_device(FILE *stream)
{
	if (stream == stdout || stream == stderr)
		return 0; 
	return 0;
}

/* Return the system file descriptor for STREAM.  */
__device__ int fileno_device(FILE *stream)
{
	return (stream == stdin ? 0 : stream == stdout ? 1 : stream == stderr ? 2 : -1); 
}

// sscanf
#pragma region sscanf

#define	BUF		32 	// Maximum length of numeric string.

// Flags used during conversion.
#define	LONG		0x01	// l: long or double
#define	SHORT		0x04	// h: short
#define	SUPPRESS	0x08	// *: suppress assignment
#define	POINTER		0x10	// p: void * (as hex)
#define	NOSKIP		0x20	// [ or c: do not skip blanks
#define	LONGLONG	0x400	// ll: long long (+ deprecated q: quad)
#define	SHORTSHORT	0x4000	// hh: char
#define	UNSIGNED	0x8000	// %[oupxX] conversions

// The following are used in numeric conversions only:
// SIGNOK, NDIGITS, DPTOK, and EXPOK are for floating point;
// SIGNOK, NDIGITS, PFXOK, and NZDIGITS are for integral.
#define	SIGNOK		0x40	// +/- is (still) legal
#define	NDIGITS		0x80	// no digits detected
#define	DPTOK		0x100	// (float) decimal point is still legal
#define	EXPOK		0x200	// (float) exponent (e+3, etc) still legal
#define	PFXOK		0x100	// 0x prefix is (still) legal
#define	NZDIGITS	0x200	// no zero digits detected

// Conversion types.
#define	CT_CHAR		0	// %c conversion
#define	CT_CCL		1	// %[...] conversion
#define	CT_STRING	2	// %s conversion
#define	CT_INT		3	// %[dioupxX] conversion

static __device__ const char *__sccl(char *tab, const char *fmt)
{
	// first 'clear' the whole table
	int c, n, v;
	c = *fmt++; // first char hat => negated scanset
	if (c == '^') {
		v = 1; // default => accept
		c = *fmt++; // get new first char
	} else
		v = 0; // default => reject 
	memset(tab, v, 256); // XXX: Will not work if sizeof(tab*) > sizeof(char)
	if (c == 0)
		return (fmt - 1); // format ended before closing ]
	// Now set the entries corresponding to the actual scanset to the opposite of the above.
	// The first character may be ']' (or '-') without being special; the last character may be '-'.
	v = 1 - v;
	for (;;) {
		tab[c] = v; // take character c
doswitch:
		n = *fmt++; // and examine the next
		switch (n) {
		case 0: // format ended too soon
			return (fmt - 1);
		case '-':
			// A scanset of the form [01+-]
			// is defined as `the digit 0, the digit 1, the character +, the character -', but
			// the effect of a scanset such as [a-zA-Z0-9]
			// is implementation defined.  The V7 Unix scanf treats `a-z' as `the letters a through
			// z', but treats `a-a' as `the letter a, the character -, and the letter a'.
			//
			// For compatibility, the `-' is not considerd to define a range if the character following
			// it is either a close bracket (required by ANSI) or is not numerically greater than the character
			// we just stored in the table (c).
			n = *fmt;
			if (n == ']' || n < c) {
				c = '-';
				break; // resume the for(;;)
			}
			fmt++;
			// fill in the range
			do {
				tab[++c] = v;
			} while (c < n);
			c = n;
			// Alas, the V7 Unix scanf also treats formats such as [a-c-e] as `the letters a through e'. This too is permitted by the standard....
			goto doswitch;
			//break;
		case ']': // end of scanset
			return fmt;
		default:
			// just another character
			c = n;
			break;
		}
	}
}

__constant__ static short _basefix[17] = { 10, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16 }; // 'basefix' is used to avoid 'if' tests in the integer scanner
__device__ int _sscanf_(const char *str, const char *fmt, va_list va)
{
	int c; // character from format, or conversion
	size_t width; // field width, or 0
	char *p; // points into all kinds of strings
	int n; // handy integer
	int flags; // flags as defined above
	char *p0; // saves original value of p when necessary
	char ccltab[256]; // character class table for %[...]
	char buf[BUF]; // buffer for numeric conversions

	int nassigned = 0; // number of fields assigned
	int nconversions = 0; // number of conversions
	int nread = 0; // number of characters consumed from fp
	int base = 0; // base argument to conversion function

	int inr = strlen(str);
	for (;;) {
		c = *fmt++;
		if (c == 0)
			return nassigned;
		if (isspace(c)) {
			while (inr > 0 && isspace(*str)) nread++, inr--, str++;
			continue;
		}
		if (c != '%')
			goto literal_;
		width = 0;
		flags = 0;
		// switch on the format.  continue if done; break once format type is derived.
again:	c = *fmt++;
		switch (c) {
		case '%':
literal_:
			if (inr <= 0)
				goto input_failure;
			if (*str != c)
				goto match_failure;
			inr--, str++;
			nread++;
			continue;
		case '*':
			flags |= SUPPRESS;
			goto again;
		case 'l':
			if (flags & LONG) {
				flags &= ~LONG;
				flags |= LONGLONG;
			} else
				flags |= LONG;
			goto again;
		case 'q':
			flags |= LONGLONG; // not quite
			goto again;
		case 'h':
			if (flags & SHORT) {
				flags &= ~SHORT;
				flags |= SHORTSHORT;
			} else
				flags |= SHORT;
			goto again;

		case '0': case '1': case '2': case '3': case '4':
		case '5': case '6': case '7': case '8': case '9':
			width = width * 10 + c - '0';
			goto again;

			// Conversions.
		case 'd':
			c = CT_INT;
			base = 10;
			break;
		case 'i':
			c = CT_INT;
			base = 0;
			break;
		case 'o':
			c = CT_INT;
			flags |= UNSIGNED;
			base = 8;
			break;
		case 'u':
			c = CT_INT;
			flags |= UNSIGNED;
			base = 10;
			break;
		case 'X':
		case 'x':
			flags |= PFXOK;	// enable 0x prefixing
			c = CT_INT;
			flags |= UNSIGNED;
			base = 16;
			break;
		case 's':
			c = CT_STRING;
			break;
		case '[':
			fmt = __sccl(ccltab, fmt);
			flags |= NOSKIP;
			c = CT_CCL;
			break;
		case 'c':
			flags |= NOSKIP;
			c = CT_CHAR;
			break;
		case 'p': // pointer format is like hex
			flags |= POINTER | PFXOK;
			c = CT_INT;
			flags |= UNSIGNED;
			base = 16;
			break;
		case 'n':
			nconversions++;
			if (flags & SUPPRESS) continue; // ??? 
			if (flags & SHORTSHORT) *va_arg(va, char *) = nread;
			else if (flags & SHORT) *va_arg(va, short *) = nread;
			else if (flags & LONG) *va_arg(va, long *) = nread;
			else if (flags & LONGLONG) *va_arg(va, long long *) = nread;
			else *va_arg(va, int *) = nread;
			continue;
		}

		// We have a conversion that requires input.
		if (inr <= 0)
			goto input_failure;

		// Consume leading white space, except for formats that suppress this.
		if ((flags & NOSKIP) == 0) {
			while (isspace(*str)) {
				nread++;
				if (--inr > 0) str++;
				else goto input_failure;
			}
			// Note that there is at least one character in the buffer, so conversions that do not set NOSKIP
			// can no longer result in an input failure.
		}

		// Do the conversion.
		switch (c) {
		case CT_CHAR: // scan arbitrary characters (sets NOSKIP)
			if (width == 0)
				width = 1;
			if (flags & SUPPRESS) {
				size_t sum = 0;
				for (;;) {
					if ((n = inr) < (int)width) {
						sum += n;
						width -= n;
						str += n;
						if (sum == 0)
							goto input_failure;
						break;
					}
					else {
						sum += width;
						inr -= width;
						str += width;
						break;
					}
				}
				nread += sum;
			}
			else {
				memcpy(va_arg(va, char *), str, width);
				inr -= width;
				str += width;
				nread += width;
				nassigned++;
			}
			nconversions++;
			break;
		case CT_CCL: // scan a (nonempty) character class (sets NOSKIP)
			if (width == 0)
				width = (size_t)~0;	// 'infinity'
			// take only those things in the class
			if (flags & SUPPRESS) {
				n = 0;
				while (ccltab[(unsigned char)*str]) {
					n++, inr--, str++;
					if (--width == 0) break;
					if (inr <= 0) {
						if (n == 0)
							goto input_failure;
						break;
					}
				}
				if (n == 0)
					goto match_failure;
			}
			else {
				p0 = p = va_arg(va, char *);
				while (ccltab[(unsigned char)*str]) {
					inr--;
					*p++ = *str++;
					if (--width == 0) break;
					if (inr <= 0) {
						if (p == p0)
							goto input_failure;
						break;
					}
				}
				n = p - p0;
				if (n == 0)
					goto match_failure;
				*p = 0;
				nassigned++;
			}
			nread += n;
			nconversions++;
			break;
		case CT_STRING: // like CCL, but zero-length string OK, & no NOSKIP
			if (width == 0)
				width = (size_t)~0;
			if (flags & SUPPRESS) {
				n = 0;
				while (!isspace(*str)) {
					n++, inr--, str++;
					if (--width == 0) break;
					if (inr <= 0) break;
				}
				nread += n;
			}
			else {
				p0 = p = va_arg(va, char *);
				while (!isspace(*str)) {
					inr--;
					*p++ = *str++;
					if (--width == 0) break;
					if (inr <= 0) break;
				}
				*p = 0;
				nread += p - p0;
				nassigned++;
			}
			nconversions++;
			continue;
		case CT_INT: // scan an integer as if by the conversion function
#ifdef hardway
			if (width == 0 || width > sizeof(buf) - 1)
				width = sizeof(buf) - 1;
#else
			// size_t is unsigned, hence this optimisation
			if (--width > sizeof(buf) - 2)
				width = sizeof(buf) - 2;
			width++;
#endif
			flags |= SIGNOK | NDIGITS | NZDIGITS;
			for (p = buf; width; width--) {
				c = *str;
				// Switch on the character; `goto ok' if we accept it as a part of number.
				switch (c) {
				case '0':
					// The digit 0 is always legal, but is special.  For %i conversions, if no digits (zero or nonzero) have been
					// scanned (only signs), we will have base==0.  In that case, we should set it to 8 and enable 0x prefixing.
					// Also, if we have not scanned zero digits before this, do not turn off prefixing (someone else will turn it off if we
					// have scanned any nonzero digits).
					if (base == 0) {
						base = 8;
						flags |= PFXOK;
					}
					if (flags & NZDIGITS) flags &= ~(SIGNOK|NZDIGITS|NDIGITS);
					else flags &= ~(SIGNOK|PFXOK|NDIGITS);
					goto ok;
				case '1': case '2': case '3': // 1 through 7 always legal
				case '4': case '5': case '6': case '7':
					base = _basefix[base];
					flags &= ~(SIGNOK | PFXOK | NDIGITS);
					goto ok;
				case '8': case '9': // digits 8 and 9 ok iff decimal or hex
					base = _basefix[base];
					if (base <= 8) break; // not legal here
					flags &= ~(SIGNOK | PFXOK | NDIGITS);
					goto ok;
				case 'A': case 'B': case 'C': // letters ok iff hex
				case 'D': case 'E': case 'F':
				case 'a': case 'b': case 'c':
				case 'd': case 'e': case 'f':
					// no need to fix base here
					if (base <= 10) break; // not legal here
					flags &= ~(SIGNOK | PFXOK | NDIGITS);
					goto ok;
				case '+': case '-': // sign ok only as first character
					if (flags & SIGNOK) {
						flags &= ~SIGNOK;
						goto ok;
					}
					break;
				case 'x': case 'X': // x ok iff flag still set & 2nd char
					if (flags & PFXOK && p == buf + 1) {
						base = 16; // if %i
						flags &= ~PFXOK;
						goto ok;
					}
					break;
				}
				// If we got here, c is not a legal character for a number.  Stop accumulating digits.
				break;
ok:
				// c is legal: store it and look at the next.
				*p++ = c;
				if (--inr > 0)
					str++;
				else 
					break; // end of input
			}
			// If we had only a sign, it is no good; push back the sign.  If the number ends in `x',
			// it was [sign] '0' 'x', so push back the x and treat it as [sign] '0'.
			if (flags & NDIGITS) {
				if (p > buf) {
					str--;
					inr++;
				}
				goto match_failure;
			}
			c = ((char *)p)[-1];
			if (c == 'x' || c == 'X') {
				--p;
				str--;
				inr++;
			}
			if (!(flags & SUPPRESS)) {
				quad_t res;
				*p = 0;
				if ((flags & UNSIGNED) == 0) res = strtoq(buf, (char **)NULL, base);
				else res = strtouq(buf, (char **)NULL, base);
				if (flags & POINTER) *va_arg(va, void **) = (void *)(intptr_t)res;
				else if (flags & SHORTSHORT) *va_arg(va, char *) = res;
				else if (flags & SHORT) *va_arg(va, short *) = res;
				else if (flags & LONG) *va_arg(va, long *) = res;
				else if (flags & LONGLONG) *va_arg(va, long long *) = res;
				else *va_arg(va, int *) = res;
				nassigned++;
			}
			nread += p - buf;
			nconversions++;
			break;
		}
	}
input_failure:
	return (nconversions != 0 ? nassigned : -1);
match_failure:
	return nassigned;
}

#pragma endregion

#ifdef __CUDA_ARCH__
__device__ char *vmtagprintf_(void *tag, const char *format, va_list va)
{
	assert(tag != nullptr);
	char base[PRINT_BUF_SIZE];
	strbld_t b;
	strbldInit(&b, base, sizeof(base), CORE_MAXLENGTH);
	b.tag = tag;
	strbldAppendFormat(&b, true, format, va);
	char *str = strbldToString(&b);
	// if (b.allocFailed) tagallocfailed(tag);
	return str;
}
#endif

#ifdef __CUDA_ARCH__
__device__ char *vmprintf_(const char *format, va_list va)
{
	char base[PRINT_BUF_SIZE];
	strbld_t b;
	strbldInit(&b, base, sizeof(base), CORE_MAXLENGTH);
	b.allocType = 2;
	strbldAppendFormat(&b, false, format, va);
	return strbldToString(&b);
}
#endif

#ifdef __CUDA_ARCH__
__device__ char *vmnprintf_(char *__restrict s, size_t maxlen, const char *format, va_list va)
{
	if (maxlen <= 0) return (char *)s;
	strbld_t b;
	strbldInit(&b, (char *)s, (int)maxlen, 0); b.allocType = 0;
	strbldAppendFormat(&b, false, format, va);
	return strbldToString(&b);
}
#endif

__END_DECLS;

///* Read formatted input from stdin into argument list ARG. */
//__device__ int vscanf_(const char *__restrict format, va_list va) { return -1; }
///* Read formatted input from S into argument list ARG.  */
//__device__ int vsscanf_(const char *__restrict s, const char *__restrict format, va_list va) { return -1; }