#include <string.h>
#include <RuntimeEx.h>
#include "Jim.h"

// Provides the [pack] and [unpack] commands to pack and unpack a binary string to/from arbitrary width integers and strings.
// This may be used to implement the [binary] command.

// Big endian bit test.
// Considers 'bitvect' as a big endian bit stream and returns bit 'b' as zero or non-zero.
static __device__ int JimTestBitBigEndian(const unsigned char *bitvec, int b)
{
	div_t pos = _div(b, 8);
	return bitvec[pos.quot] & (1 << (7 - pos.rem));
}

// Little endian bit test.
// Considers 'bitvect' as a little endian bit stream and returns bit 'b' as zero or non-zero.
static __device__ int JimTestBitLittleEndian(const unsigned char *bitvec, int b)
{
	div_t pos = _div(b, 8);
	return bitvec[pos.quot] & (1 << pos.rem);
}

// Sign extends the given value, 'n' of width 'width' bits.
// For example, sign extending 0x80 with a width of 8, produces -128
static __device__ jim_wide JimSignExtend(jim_wide n, int width)
{
	// Can't sign extend the maximum size integer
	if (width == sizeof(jim_wide) * 8)
		return n;
	// Need to extend
	if (n & ((jim_wide)1 << (width - 1)))
		n -= ((jim_wide)1 << width);
	return n;
}

// Big endian integer extraction.
// Considers 'bitvect' as a big endian bit stream. Returns an integer of the given width (in bits) starting at the given position (in bits).
// The pos/width must represent bits inside bitvec, and the width be no more than the width of jim_wide.
static __device__ jim_wide JimBitIntBigEndian(const unsigned char *bitvec, int pos, int width)
{
	jim_wide result = 0;
	int i;
	// Aligned, byte extraction
	if (pos % 8 == 0 && width % 8 == 0) {
		for (i = 0; i < width; i += 8)
			result = (result << 8) + bitvec[(pos + i) / 8];
		return result;
	}
	// Unaligned
	for (i = 0; i < width; i++)
		if (JimTestBitBigEndian(bitvec, pos + width - i - 1))
			result |= ((jim_wide)1 << i);
	return result;
}

// Little endian integer extraction.
// Like JimBitIntBigEndian() but considers 'bitvect' as a little endian bit stream.
static __device__ jim_wide JimBitIntLittleEndian(const unsigned char *bitvec, int pos, int width)
{
	jim_wide result = 0;
	int i;
	// Aligned, byte extraction
	if (pos % 8 == 0 && width % 8 == 0) {
		for (i = 0; i < width; i += 8)
			result += (jim_wide)bitvec[(pos + i) / 8] << i;
		return result;
	}
	// Unaligned
	for (i = 0; i < width; i++)
		if (JimTestBitLittleEndian(bitvec, pos + i))
			result |= ((jim_wide)1 << i);
	return result;
}

// Big endian bit set.
// Considers 'bitvect' as a big endian bit stream and sets bit 'b' to 'bit'
static __device__ void JimSetBitBigEndian(unsigned char *bitvec, int b, int bit)
{
	div_t pos = _div(b, 8);
	if (bit)
		bitvec[pos.quot] |= (1 << (7 - pos.rem));
	else
		bitvec[pos.quot] &= ~(1 << (7 - pos.rem));
}

// Little endian bit set.
// Considers 'bitvect' as a little endian bit stream and sets bit 'b' to 'bit'
static __device__ void JimSetBitLittleEndian(unsigned char *bitvec, int b, int bit)
{
	div_t pos = _div(b, 8);
	if (bit)
		bitvec[pos.quot] |= (1 << pos.rem);
	else
		bitvec[pos.quot] &= ~(1 << pos.rem);
}

// Big endian integer packing.
// Considers 'bitvect' as a big endian bit stream. Packs integer 'value' of the given width (in bits) starting at the given position (in bits).
// The pos/width must represent bits inside bitvec, and the width be no more than the width of jim_wide.
static __device__ void JimSetBitsIntBigEndian(unsigned char *bitvec, jim_wide value, int pos, int width)
{
	int i;
	// Common fast option
	if (pos % 8 == 0 && width == 8) {
		bitvec[pos / 8] = (unsigned char)value;
		return;
	}
	for (i = 0; i < width; i++) {
		int bit = !!(value & ((jim_wide)1 << i));
		JimSetBitBigEndian(bitvec, pos + width - i - 1, bit);
	}
}

// Little endian version of JimSetBitsIntBigEndian()
static __device__ void JimSetBitsIntLittleEndian(unsigned char *bitvec, jim_wide value, int pos, int width)
{
	int i;
	// Common fast option
	if (pos % 8 == 0 && width == 8) {
		bitvec[pos / 8] = (unsigned char)value;
		return;
	}
	for (i = 0; i < width; i++) {
		int bit = !!(value & ((jim_wide)1 << i));
		JimSetBitLittleEndian(bitvec, pos + i, bit);
	}
}

// Binary conversion of jim_wide integer to float
// Considers the least significant bits of jim_wide 'value' as a IEEE float.
// Should work for both little- and big-endian platforms.
static __device__ float JimIntToFloat(jim_wide value)
{
	// Skip offs to get to least significant bytes
	int offs = (Jim_IsBigEndian() ? (sizeof(jim_wide) - sizeof(float)) : 0);
	float val;
	memcpy(&val, (unsigned char *)&value + offs, sizeof(float));
	return val;
}

// Binary conversion of jim_wide integer to double
// Double precision version of JimIntToFloat
static __device__ double JimIntToDouble(jim_wide value)
{
	// Skip offs to get to least significant bytes
	int offs = (Jim_IsBigEndian() ? (sizeof(jim_wide) - sizeof(double)) : 0);
	double val;
	memcpy(&val, (unsigned char *)&value + offs, sizeof(double));
	return val;
}

// Binary conversion of float to jim_wide integer
// Considers the bits of IEEE float 'value' as integer. The integer is zero-extended to jim_wide.
// Should work for both little- and big-endian platforms.
static __device__ jim_wide JimFloatToInt(float value)
{
	// Skip offs to get to least significant bytes
	int offs = (Jim_IsBigEndian() ? (sizeof(jim_wide) - sizeof(float)) : 0);
	jim_wide val = 0;
	memcpy((unsigned char *)&val + offs, &value, sizeof(float));
	return val;
}

// Binary conversion of double to jim_wide integer
// Double precision version of JimFloatToInt
static __device__ jim_wide JimDoubleToInt(double value)
{
	// Skip offs to get to least significant bytes
	int offs = (Jim_IsBigEndian() ? (sizeof(jim_wide) - sizeof(double)) : 0);
	jim_wide val = 0;
	memcpy((unsigned char *)&val + offs, &value, sizeof(double));
	return val;
}

// [unpack]
// Usage: unpack binvalue -intbe|-intle|-uintbe|-uintle|-floatbe|-floatle|-str bitpos bitwidth
// Unpacks bits from $binvalue at bit position $bitpos and with $bitwidth.
// Interprets the value according to the type and returns it.
__constant__ static const char *const _unpack_options[] = { "-intbe", "-intle", "-uintbe", "-uintle",
	"-floatbe", "-floatle", "-str", NULL };
static __device__ int Jim_UnpackCmd(ClientData dummy, Jim_Interp *interp, int argc, Jim_Obj *const *argv)
{
	enum { OPT_INTBE, OPT_INTLE, OPT_UINTBE, OPT_UINTLE, OPT_FLOATBE, OPT_FLOATLE, OPT_STR, };
	if (argc != 5) {
		Jim_WrongNumArgs(interp, 1, argv, "binvalue -intbe|-intle|-uintbe|-uintle|-floatbe|-floatle|-str bitpos bitwidth");
		return JIM_ERROR;
	}
	int option;
	if (Jim_GetEnum(interp, argv[2], _unpack_options, &option, NULL, JIM_ERRMSG) != JIM_OK)
		return JIM_ERROR;
	jim_wide pos;
	if (Jim_GetWide(interp, argv[3], &pos) != JIM_OK)
		return JIM_ERROR;
	jim_wide width;
	if (Jim_GetWide(interp, argv[4], &width) != JIM_OK)
		return JIM_ERROR;
	if (option == OPT_STR) {
		int len;
		const char *str = Jim_GetString(argv[1], &len);
		if (width % 8 || pos % 8) {
			Jim_SetResultString(interp, "string field is not on a byte boundary", -1);
			return JIM_ERROR;
		}
		if (pos >= 0 && width > 0 && pos < len * 8) {
			if (pos + width > len * 8)
				width = len * 8 - pos;
			Jim_SetResultString(interp, str + pos / 8, (int)(width / 8));
		}
		return JIM_OK;
	}
	else {
		int len;
		const unsigned char *str = (const unsigned char *)Jim_GetString(argv[1], &len);
		jim_wide result = 0;
		if (width > sizeof(jim_wide) * 8) {
			Jim_SetResultFormatted(interp, "int field is too wide: %#s", argv[4]);
			return JIM_ERROR;
		}
		if (pos >= 0 && width > 0 && pos < len * 8) {
			if (pos + width > len * 8)
				width = len * 8 - pos;
			result = (option == OPT_INTBE || option == OPT_UINTBE || option == OPT_FLOATBE ? JimBitIntBigEndian(str, (int)pos, (int)width) : JimBitIntLittleEndian(str, (int)pos, (int)width));
			if (option == OPT_INTBE || option == OPT_INTLE)
				result = JimSignExtend(result, (int)width);
		}
		if (option == OPT_FLOATBE || option == OPT_FLOATLE) {
			double fresult;
			if (width == 32)
				fresult = (double)JimIntToFloat(result);
			else if (width == 64)
				fresult = JimIntToDouble(result);
			else {
				Jim_SetResultFormatted(interp, "float field has bad bitwidth: %#s", argv[4]);
				return JIM_ERROR;
			}
			Jim_SetResult(interp, Jim_NewDoubleObj(interp, fresult));
		} else
			Jim_SetResultInt(interp, result);
		return JIM_OK;
	}
}

// [pack]
// Usage: pack varname value -intbe|-intle|-floatle|-floatbe|-str width ?bitoffset?
// Packs the binary representation of 'value' into the variable of the given name.
// The value is packed according to the given type, width and bitoffset.
// The variable is created if necessary (like [append])
// The variable is expanded if necessary
__constant__ static const char *const _pack_options[] = { "-intle", "-intbe", "-floatle", "-floatbe",
	"-str", NULL };
static __device__ int Jim_PackCmd(ClientData dummy, Jim_Interp *interp, int argc, Jim_Obj *const *argv)
{
	enum { OPT_LE, OPT_BE, OPT_FLOATLE, OPT_FLOATBE, OPT_STR };
	if (argc != 5 && argc != 6) {
		Jim_WrongNumArgs(interp, 1, argv, "varName value -intle|-intbe|-floatle|-floatbe|-str bitwidth ?bitoffset?");
		return JIM_ERROR;
	}
	int option;
	if (Jim_GetEnum(interp, argv[3], _pack_options, &option, NULL, JIM_ERRMSG) != JIM_OK)
		return JIM_ERROR;
	jim_wide width;
	jim_wide value;
	double fvalue;
	if ((option == OPT_LE || option == OPT_BE) && Jim_GetWide(interp, argv[2], &value) != JIM_OK)
		return JIM_ERROR;
	if ((option == OPT_FLOATLE || option == OPT_FLOATBE) && Jim_GetDouble(interp, argv[2], &fvalue) != JIM_OK)
		return JIM_ERROR;
	if (Jim_GetWide(interp, argv[4], &width) != JIM_OK)
		return JIM_ERROR;
	if (width <= 0 || (option == OPT_STR && width % 8) || (option != OPT_STR && width > sizeof(jim_wide) * 8) || ((option == OPT_FLOATLE || option == OPT_FLOATBE) && width != 32 && width != 64)) {
		Jim_SetResultFormatted(interp, "bad bitwidth: %#s", argv[4]);
		return JIM_ERROR;
	}
	jim_wide pos = 0;
	if (argc == 6) {
		if (Jim_GetWide(interp, argv[5], &pos) != JIM_OK)
			return JIM_ERROR;
		if (pos < 0 || (option == OPT_STR && pos % 8)) {
			Jim_SetResultFormatted(interp, "bad bitoffset: %#s", argv[5]);
			return JIM_ERROR;
		}
	}
	Jim_Obj *stringObjPtr = Jim_GetVariable(interp, argv[1], JIM_UNSHARED);
	int freeobj = 0;
	if (!stringObjPtr) {
		// Create the string if it doesn't exist
		stringObjPtr = Jim_NewEmptyStringObj(interp);
		freeobj = 1;
	}
	else if (Jim_IsShared(stringObjPtr)) {
		freeobj = 1;
		stringObjPtr = Jim_DuplicateObj(interp, stringObjPtr);
	}
	int len = Jim_Length(stringObjPtr) * 8;
	// Extend the string as necessary first
	while (len < pos + width) {
		Jim_AppendString(interp, stringObjPtr, "", 1);
		len += 8;
	}
	Jim_SetResultInt(interp, pos + width);
	// Now set the bits. Note that the the string *must* have no non-string rep since we are writing the bytes directly.
	Jim_AppendString(interp, stringObjPtr, "", 0);
	// Convert floating point to integer if necessary
	// Note that the following is slightly incompatible with Tcl behaviour. In Tcl floating overflow gives FLT_MAX (cf. test binary-13.13). In Jim Tcl it gives Infinity. This behavior may change.
	if (option == OPT_FLOATLE || option == OPT_FLOATBE)
		value = (width == 32 ? JimFloatToInt((float)fvalue) : JimDoubleToInt(fvalue));
	if (option == OPT_BE || option == OPT_FLOATBE)
		JimSetBitsIntBigEndian((unsigned char *)stringObjPtr->bytes, value, (int)pos, (int)width);
	else if (option == OPT_LE || option == OPT_FLOATLE)
		JimSetBitsIntLittleEndian((unsigned char *)stringObjPtr->bytes, value, (int)pos, (int)width);
	else {
		pos /= 8;
		width /= 8;
		if (width > Jim_Length(argv[2]))
			width = Jim_Length(argv[2]);
		memcpy(stringObjPtr->bytes + pos, Jim_String(argv[2]), width);
		// No padding is needed since the string is already extended
	}
	if (Jim_SetVariable(interp, argv[1], stringObjPtr) != JIM_OK) {
		if (freeobj) {
			Jim_FreeNewObj(interp, stringObjPtr);
			return JIM_ERROR;
		}
	}
	return JIM_OK;
}

__device__ int Jim_packInit(Jim_Interp *interp)
{
	if (Jim_PackageProvide(interp, "pack", "1.0", JIM_ERRMSG))
		return JIM_ERROR;
	Jim_CreateCommand(interp, "unpack", Jim_UnpackCmd, NULL, NULL);
	Jim_CreateCommand(interp, "pack", Jim_PackCmd, NULL, NULL);
	return JIM_OK;
}