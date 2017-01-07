/*
stdarg.h - defines ANSI-style macros for variable argument functions
The MIT License

Copyright (c) 2016 Sky Morey

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

#pragma once

#if !__CUDACC__
#include <stdarg.h>
#elif !defined(_INC_STDARG)
#define _INC_STDARG
#include <crtdefscu.h>

#define STDARGvoid(name, body, ...) \
	__forceinline __device__ void name(__VA_ARGS__) { _crt_va_list va; _crt_va_start(va); (body); _crt_va_end(va); } \
	template <typename T1> __forceinline __device__ void name(__VA_ARGS__, T1 arg1) { _crt_va_list1<T1> va; _crt_va_start(va, arg1); (body); _crt_va_end(va); } \
	template <typename T1, typename T2> __forceinline __device__ void name(__VA_ARGS__, T1 arg1, T2 arg2) { _crt_va_list2<T1,T2> va; _crt_va_start(va, arg1, arg2); (body); _crt_va_end(va); } \
	template <typename T1, typename T2, typename T3> __forceinline __device__ void name(__VA_ARGS__, T1 arg1, T2 arg2, T3 arg3) { _crt_va_list3<T1,T2,T3> va; _crt_va_start(va, arg1, arg2, arg3); (body); _crt_va_end(va); } \
	template <typename T1, typename T2, typename T3, typename T4> __forceinline __device__ void name(__VA_ARGS__, T1 arg1, T2 arg2, T3 arg3, T4 arg4) { _crt_va_list4<T1,T2,T3,T4> va; _crt_va_start(va, arg1, arg2, arg3, arg4); (body); _crt_va_end(va); } \
	template <typename T1, typename T2, typename T3, typename T4, typename T5> __forceinline __device__ void name(__VA_ARGS__, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5) { _crt_va_list5<T1,T2,T3,T4,T5> va; _crt_va_start(va, arg1, arg2, arg3, arg4, arg5); (body); _crt_va_end(va); } \
	template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6> __forceinline __device__ void name(__VA_ARGS__, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6) { _crt_va_list6<T1,T2,T3,T4,T5,T6> va; _crt_va_start(va, arg1, arg2, arg3, arg4, arg5, arg6); (body); _crt_va_end(va); } \
	template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7> __forceinline __device__ void name(__VA_ARGS__, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6, T7 arg7) { _crt_va_list7<T1,T2,T3,T4,T5,T6,T7> va; _crt_va_start(va, arg1, arg2, arg3, arg4, arg5, arg6, arg7); (body); _crt_va_end(va); } \
	template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8> __forceinline __device__ void name(__VA_ARGS__, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6, T7 arg7, T8 arg8) { _crt_va_list8<T1,T2,T3,T4,T5,T6,T7,T8> va; _crt_va_start(va, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8); (body); _crt_va_end(va); } \
	template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9> __forceinline __device__ void name(__VA_ARGS__, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6, T7 arg7, T8 arg8, T9 arg9) { _crt_va_list9<T1,T2,T3,T4,T5,T6,T7,T8,T9> va; _crt_va_start(va, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9); (body); _crt_va_end(va); } \
	template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9, typename TA> __forceinline __device__ void name(__VA_ARGS__, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6, T7 arg7, T8 arg8, T9 arg9, TA argA) { _crt_va_listA<T1,T2,T3,T4,T5,T6,T7,T8,T9,TA> va; _crt_va_start(va, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, argA); (body); _crt_va_end(va); }
// extended
#define STDARG2void(name, body, ...) \
	template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9, typename TA, typename TB> __forceinline __device__ void name(__VA_ARGS__, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6, T7 arg7, T8 arg8, T9 arg9, TA argA, TB argB) { _crt_va_listB<T1,T2,T3,T4,T5,T6,T7,T8,T9,TA,TB> va; _crt_va_start(va, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, argA, argB); (body); _crt_va_end(va); } \
	template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9, typename TA, typename TB, typename TC> __forceinline __device__ void name(__VA_ARGS__, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6, T7 arg7, T8 arg8, T9 arg9, TA argA, TB argB, TC argC) { _crt_va_listC<T1,T2,T3,T4,T5,T6,T7,T8,T9,TA,TB,TC> va; _crt_va_start(va, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, argA, argB, argC); (body); _crt_va_end(va); } \
	template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9, typename TA, typename TB, typename TC, typename TD> __forceinline __device__ void name(__VA_ARGS__, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6, T7 arg7, T8 arg8, T9 arg9, TA argA, TB argB, TC argC, TD argD) { _crt_va_listD<T1,T2,T3,T4,T5,T6,T7,T8,T9,TA,TB,TC,TD> va; _crt_va_start(va, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, argA, argB, argC, argD); (body); _crt_va_end(va); } \
	template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9, typename TA, typename TB, typename TC, typename TD, typename TE> __forceinline __device__ void name(__VA_ARGS__, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6, T7 arg7, T8 arg8, T9 arg9, TA argA, TB argB, TC argC, TD argD, TE argE) { _crt_va_listE<T1,T2,T3,T4,T5,T6,T7,T8,T9,TA,TB,TC,TD,TE> va; _crt_va_start(va, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, argA, argB, argC, argD, argE); (body); _crt_va_end(va); } \
	template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9, typename TA, typename TB, typename TC, typename TD, typename TE, typename TF> __forceinline __device__ void name(__VA_ARGS__, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6, T7 arg7, T8 arg8, T9 arg9, TA argA, TB argB, TC argC, TD argD, TE argE, TF argF) { _crt_va_listF<T1,T2,T3,T4,T5,T6,T7,T8,T9,TA,TB,TC,TD,TE,TF> va; _crt_va_start(va, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, argA, argB, argC, argD, argE, argF); (body); _crt_va_end(va); }
// extended-2
#define STDARG3void(name, body, ...) \
	template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9, typename TA, typename TB, typename TC, typename TD, typename TE, typename TF, typename T11> __forceinline __device__ void name(__VA_ARGS__, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6, T7 arg7, T8 arg8, T9 arg9, TA argA, TB argB, TC argC, TD argD, TE argE, TF argF, T11 arg11) { _crt_va_list11<T1,T2,T3,T4,T5,T6,T7,T8,T9,TA,TB,TC,TD,TE,TF,T11> va; _crt_va_start(va, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, argA, argB, argC, argD, argE, argF, arg11); (body); _crt_va_end(va); } \
	template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9, typename TA, typename TB, typename TC, typename TD, typename TE, typename TF, typename T11, typename T12> __forceinline __device__ void name(__VA_ARGS__, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6, T7 arg7, T8 arg8, T9 arg9, TA argA, TB argB, TC argC, TD argD, TE argE, TF argF, T11 arg11, T12 arg12) { _crt_va_list12<T1,T2,T3,T4,T5,T6,T7,T8,T9,TA,TB,TC,TD,TE,TF,T11,T12> va; _crt_va_start(va, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, argA, argB, argC, argD, argE, argF, arg11, arg12); (body); _crt_va_end(va); } \
	template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9, typename TA, typename TB, typename TC, typename TD, typename TE, typename TF, typename T11, typename T12, typename T13> __forceinline __device__ void name(__VA_ARGS__, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6, T7 arg7, T8 arg8, T9 arg9, TA argA, TB argB, TC argC, TD argD, TE argE, TF argF, T11 arg11, T12 arg12, T13 arg13) { _crt_va_list13<T1,T2,T3,T4,T5,T6,T7,T8,T9,TA,TB,TC,TD,TE,TF,T11,T12,T13> va; _crt_va_start(va, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, argA, argB, argC, argD, argE, argF, arg11, arg12, arg13); (body); _crt_va_end(va); } \
	template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9, typename TA, typename TB, typename TC, typename TD, typename TE, typename TF, typename T11, typename T12, typename T13, typename T14> __forceinline __device__ void name(__VA_ARGS__, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6, T7 arg7, T8 arg8, T9 arg9, TA argA, TB argB, TC argC, TD argD, TE argE, TF argF, T11 arg11, T12 arg12, T13 arg13, T14 arg14) { _crt_va_list14<T1,T2,T3,T4,T5,T6,T7,T8,T9,TA,TB,TC,TD,TE,TF,T11,T12,T13,T14> va; _crt_va_start(va, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, argA, argB, argC, argD, argE, argF, arg11, arg12, arg13, arg14); (body); _crt_va_end(va); } \
	template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9, typename TA, typename TB, typename TC, typename TD, typename TE, typename TF, typename T11, typename T12, typename T13, typename T14, typename T15> __forceinline __device__ void name(__VA_ARGS__, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6, T7 arg7, T8 arg8, T9 arg9, TA argA, TB argB, TC argC, TD argD, TE argE, TF argF, T11 arg11, T12 arg12, T13 arg13, T14 arg14, T15 arg15) { _crt_va_list15<T1,T2,T3,T4,T5,T6,T7,T8,T9,TA,TB,TC,TD,TE,TF,T11,T12,T13,T14,T15> va; _crt_va_start(va, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, argA, argB, argC, argD, argE, argF, arg11, arg12, arg13, arg14, arg15); (body); _crt_va_end(va); } \

#define STDARG(ret, name, body, ...) \
	__forceinline __device__ ret name(__VA_ARGS__) { _crt_va_list va; _crt_va_start(va); ret r = (body); _crt_va_end(va); return r; } \
	template <typename T1> __forceinline __device__ ret name(__VA_ARGS__, T1 arg1) { _crt_va_list1<T1> va; _crt_va_start(va, arg1); ret r = (body); _crt_va_end(va); return r; } \
	template <typename T1, typename T2> __forceinline __device__ ret name(__VA_ARGS__, T1 arg1, T2 arg2) { _crt_va_list2<T1,T2> va; _crt_va_start(va, arg1, arg2); ret r = (body); _crt_va_end(va); return r; } \
	template <typename T1, typename T2, typename T3> __forceinline __device__ ret name(__VA_ARGS__, T1 arg1, T2 arg2, T3 arg3) { _crt_va_list3<T1,T2,T3> va; _crt_va_start(va, arg1, arg2, arg3); ret r = (body); _crt_va_end(va); return r; } \
	template <typename T1, typename T2, typename T3, typename T4> __forceinline __device__ ret name(__VA_ARGS__, T1 arg1, T2 arg2, T3 arg3, T4 arg4) { _crt_va_list4<T1,T2,T3,T4> va; _crt_va_start(va, arg1, arg2, arg3, arg4); ret r = (body); _crt_va_end(va); return r; } \
	template <typename T1, typename T2, typename T3, typename T4, typename T5> __forceinline __device__ ret name(__VA_ARGS__, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5) { _crt_va_list5<T1,T2,T3,T4,T5> va; _crt_va_start(va, arg1, arg2, arg3, arg4, arg5); ret r = (body); _crt_va_end(va); return r; } \
	template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6> __forceinline __device__ ret name(__VA_ARGS__, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6) { _crt_va_list6<T1,T2,T3,T4,T5,T6> va; _crt_va_start(va, arg1, arg2, arg3, arg4, arg5, arg6); ret r = (body); _crt_va_end(va); return r; } \
	template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7> __forceinline __device__ ret name(__VA_ARGS__, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6, T7 arg7) { _crt_va_list7<T1,T2,T3,T4,T5,T6,T7> va; _crt_va_start(va, arg1, arg2, arg3, arg4, arg5, arg6, arg7); ret r = (body); _crt_va_end(va); return r; } \
	template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8> __forceinline __device__ ret name(__VA_ARGS__, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6, T7 arg7, T8 arg8) { _crt_va_list8<T1,T2,T3,T4,T5,T6,T7,T8> va; _crt_va_start(va, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8); ret r = (body); _crt_va_end(va); return r; } \
	template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9> __forceinline __device__ ret name(__VA_ARGS__, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6, T7 arg7, T8 arg8, T9 arg9) { _crt_va_list9<T1,T2,T3,T4,T5,T6,T7,T8,T9> va; _crt_va_start(va, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9); ret r = (body); _crt_va_end(va); return r; } \
	template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9, typename TA> __forceinline __device__ ret name(__VA_ARGS__, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6, T7 arg7, T8 arg8, T9 arg9, TA argA) { _crt_va_listA<T1,T2,T3,T4,T5,T6,T7,T8,T9,TA> va; _crt_va_start(va, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, argA); ret r = (body); _crt_va_end(va); return r; }
// extended
#define STDARG2(ret, name, body, ...) \
	template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9, typename TA, typename TB> __forceinline __device__ ret name(__VA_ARGS__, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6, T7 arg7, T8 arg8, T9 arg9, TA argA, TB argB) { _crt_va_listB<T1,T2,T3,T4,T5,T6,T7,T8,T9,TA,TB> va; _crt_va_start(va, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, argA, argB); ret r = (body); _crt_va_end(va); return r; } \
	template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9, typename TA, typename TB, typename TC> __forceinline __device__ ret name(__VA_ARGS__, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6, T7 arg7, T8 arg8, T9 arg9, TA argA, TB argB, TC argC) { _crt_va_listC<T1,T2,T3,T4,T5,T6,T7,T8,T9,TA,TB,TC> va; _crt_va_start(va, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, argA, argB, argC); ret r = (body); _crt_va_end(va); return r; } \
	template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9, typename TA, typename TB, typename TC, typename TD> __forceinline __device__ ret name(__VA_ARGS__, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6, T7 arg7, T8 arg8, T9 arg9, TA argA, TB argB, TC argC, TD argD) { _crt_va_listD<T1,T2,T3,T4,T5,T6,T7,T8,T9,TA,TB,TC,TD> va; _crt_va_start(va, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, argA, argB, argC, argD); ret r = (body); _crt_va_end(va); return r; } \
	template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9, typename TA, typename TB, typename TC, typename TD, typename TE> __forceinline __device__ ret name(__VA_ARGS__, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6, T7 arg7, T8 arg8, T9 arg9, TA argA, TB argB, TC argC, TD argD, TE argE) { _crt_va_listE<T1,T2,T3,T4,T5,T6,T7,T8,T9,TA,TB,TC,TD,TE> va; _crt_va_start(va, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, argA, argB, argC, argD, argE); ret r = (body); _crt_va_end(va); return r; } \
	template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9, typename TA, typename TB, typename TC, typename TD, typename TE, typename TF> __forceinline __device__ ret name(__VA_ARGS__, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6, T7 arg7, T8 arg8, T9 arg9, TA argA, TB argB, TC argC, TD argD, TE argE, TF argF) { _crt_va_listF<T1,T2,T3,T4,T5,T6,T7,T8,T9,TA,TB,TC,TD,TE,TF> va; _crt_va_start(va, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, argA, argB, argC, argD, argE, argF); ret r = (body); _crt_va_end(va); return r; }
// extended-2
#define STDARG3(ret, name, body, ...) \
	template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9, typename TA, typename TB, typename TC, typename TD, typename TE, typename TF, typename T11> __forceinline __device__ ret name(__VA_ARGS__, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6, T7 arg7, T8 arg8, T9 arg9, TA argA, TB argB, TC argC, TD argD, TE argE, TF argF, T11 arg11) { _crt_va_list11<T1,T2,T3,T4,T5,T6,T7,T8,T9,TA,TB,TC,TD,TE,TF,T11> va; _crt_va_start(va, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, argA, argB, argC, argD, argE, argF, arg11); ret r = (body); _crt_va_end(va); return r; } \
	template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9, typename TA, typename TB, typename TC, typename TD, typename TE, typename TF, typename T11, typename T12> __forceinline __device__ ret name(__VA_ARGS__, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6, T7 arg7, T8 arg8, T9 arg9, TA argA, TB argB, TC argC, TD argD, TE argE, TF argF, T11 arg11, T12 arg12) { _crt_va_list12<T1,T2,T3,T4,T5,T6,T7,T8,T9,TA,TB,TC,TD,TE,TF,T11,T12> va; _crt_va_start(va, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, argA, argB, argC, argD, argE, argF, arg11, arg12); ret r = (body); _crt_va_end(va); return r; } \
	template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9, typename TA, typename TB, typename TC, typename TD, typename TE, typename TF, typename T11, typename T12, typename T13> __forceinline __device__ ret name(__VA_ARGS__, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6, T7 arg7, T8 arg8, T9 arg9, TA argA, TB argB, TC argC, TD argD, TE argE, TF argF, T11 arg11, T12 arg12, T13 arg13) { _crt_va_list13<T1,T2,T3,T4,T5,T6,T7,T8,T9,TA,TB,TC,TD,TE,TF,T11,T12,T13> va; _crt_va_start(va, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, argA, argB, argC, argD, argE, argF, arg11, arg12, arg13); ret r = (body); _crt_va_end(va); return r; } \
	template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9, typename TA, typename TB, typename TC, typename TD, typename TE, typename TF, typename T11, typename T12, typename T13, typename T14> __forceinline __device__ ret name(__VA_ARGS__, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6, T7 arg7, T8 arg8, T9 arg9, TA argA, TB argB, TC argC, TD argD, TE argE, TF argF, T11 arg11, T12 arg12, T13 arg13, T14 arg14) { _crt_va_list14<T1,T2,T3,T4,T5,T6,T7,T8,T9,TA,TB,TC,TD,TE,TF,T11,T12,T13,T14> va; _crt_va_start(va, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, argA, argB, argC, argD, argE, argF, arg11, arg12, arg13, arg14); ret r = (body); _crt_va_end(va); return r; } \
	template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9, typename TA, typename TB, typename TC, typename TD, typename TE, typename TF, typename T11, typename T12, typename T13, typename T14, typename T15> __forceinline __device__ ret name(__VA_ARGS__, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6, T7 arg7, T8 arg8, T9 arg9, TA argA, TB argB, TC argC, TD argD, TE argE, TF argF, T11 arg11, T12 arg12, T13 arg13, T14 arg14, T15 arg15) { _crt_va_list15<T1,T2,T3,T4,T5,T6,T7,T8,T9,TA,TB,TC,TD,TE,TF,T11,T12,T13,T14,T15> va; _crt_va_start(va, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, argA, argB, argC, argD, argE, argF, arg11, arg12, arg13, arg14, arg15); ret r = (body); _crt_va_end(va); return r; } \

struct _crt_va_list0 { char *b; char *i; };
template <typename T1> struct _crt_va_list1 : _crt_va_list0 { T1 v1; };
template <typename T1, typename T2> struct _crt_va_list2 : _crt_va_list0 { T1 v1; T2 v2; };
template <typename T1, typename T2, typename T3> struct _crt_va_list3 : _crt_va_list0 { T1 v1; T2 v2; T3 v3; };
template <typename T1, typename T2, typename T3, typename T4> struct _crt_va_list4 : _crt_va_list0 { T1 v1; T2 v2; T3 v3; T4 v4; };
template <typename T1, typename T2, typename T3, typename T4, typename T5> struct _crt_va_list5 : _crt_va_list0 { T1 v1; T2 v2; T3 v3; T4 v4; T5 v5; };
template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6> struct _crt_va_list6 : _crt_va_list0 { T1 v1; T2 v2; T3 v3; T4 v4; T5 v5; T6 v6; };
template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7> struct _crt_va_list7 : _crt_va_list0 { T1 v1; T2 v2; T3 v3; T4 v4; T5 v5; T6 v6; T7 v7; };
template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8> struct _crt_va_list8 : _crt_va_list0 { T1 v1; T2 v2; T3 v3; T4 v4; T5 v5; T6 v6; T7 v7; T8 v8; };
template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9> struct _crt_va_list9 : _crt_va_list0 { T1 v1; T2 v2; T3 v3; T4 v4; T5 v5; T6 v6; T7 v7; T8 v8; T9 v9; };
template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9, typename TA> struct _crt_va_listA : _crt_va_list0 { T1 v1; T2 v2; T3 v3; T4 v4; T5 v5; T6 v6; T7 v7; T8 v8; T9 v9; TA vA; };
// extended
template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9, typename TA, typename TB> struct _crt_va_listB : _crt_va_list0 { T1 v1; T2 v2; T3 v3; T4 v4; T5 v5; T6 v6; T7 v7; T8 v8; T9 v9; TA vA; TB vB; };
template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9, typename TA, typename TB, typename TC> struct _crt_va_listC : _crt_va_list0 { T1 v1; T2 v2; T3 v3; T4 v4; T5 v5; T6 v6; T7 v7; T8 v8; T9 v9; TA vA; TB vB; TC vC; };
template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9, typename TA, typename TB, typename TC, typename TD> struct _crt_va_listD : _crt_va_list0 { T1 v1; T2 v2; T3 v3; T4 v4; T5 v5; T6 v6; T7 v7; T8 v8; T9 v9; TA vA; TB vB; TC vC; TD vD; };
template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9, typename TA, typename TB, typename TC, typename TD, typename TE> struct _crt_va_listE : _crt_va_list0 { T1 v1; T2 v2; T3 v3; T4 v4; T5 v5; T6 v6; T7 v7; T8 v8; T9 v9; TA vA; TB vB; TC vC; TD vD; TE vE; };
template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9, typename TA, typename TB, typename TC, typename TD, typename TE, typename TF> struct _crt_va_listF : _crt_va_list0 { T1 v1; T2 v2; T3 v3; T4 v4; T5 v5; T6 v6; T7 v7; T8 v8; T9 v9; TA vA; TB vB; TC vC; TD vD; TE vE; TF vF; };
// extended-2
template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9, typename TA, typename TB, typename TC, typename TD, typename TE, typename TF, typename T11> struct _crt_va_list11 : _crt_va_list0 { T1 v1; T2 v2; T3 v3; T4 v4; T5 v5; T6 v6; T7 v7; T8 v8; T9 v9; TA vA; TB vB; TC vC; TD vD; TE vE; TF vF; T11 v11; };
template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9, typename TA, typename TB, typename TC, typename TD, typename TE, typename TF, typename T11, typename T12> struct _crt_va_list12 : _crt_va_list0 { T1 v1; T2 v2; T3 v3; T4 v4; T5 v5; T6 v6; T7 v7; T8 v8; T9 v9; TA vA; TB vB; TC vC; TD vD; TE vE; TF vF; T11 v11; T12 v12; };
template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9, typename TA, typename TB, typename TC, typename TD, typename TE, typename TF, typename T11, typename T12, typename T13> struct _crt_va_list13 : _crt_va_list0 { T1 v1; T2 v2; T3 v3; T4 v4; T5 v5; T6 v6; T7 v7; T8 v8; T9 v9; TA vA; TB vB; TC vC; TD vD; TE vE; TF vF; T11 v11; T12 v12; T13 v13; };
template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9, typename TA, typename TB, typename TC, typename TD, typename TE, typename TF, typename T11, typename T12, typename T13, typename T14> struct _crt_va_list14 : _crt_va_list0 { T1 v1; T2 v2; T3 v3; T4 v4; T5 v5; T6 v6; T7 v7; T8 v8; T9 v9; TA vA; TB vB; TC vC; TD vD; TE vE; TF vF; T11 v11; T12 v12; T13 v13; T14 v14; };
template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9, typename TA, typename TB, typename TC, typename TD, typename TE, typename TF, typename T11, typename T12, typename T13, typename T14, typename T15> struct _crt_va_list15 : _crt_va_list0 { T1 v1; T2 v2; T3 v3; T4 v4; T5 v5; T6 v6; T7 v7; T8 v8; T9 v9; TA vA; TB vB; TC vC; TD vD; TE vE; TF vF; T11 v11; T12 v12; T13 v13; T14 v14; T15 v15; };

#undef _INTSIZEOF
#undef _crt_va_start
#undef _crt_va_arg
#undef _crt_va_end

#ifndef _INTSIZEOF
#define _INTSIZEOF(n) ((sizeof(n) + sizeof(int) - 1) & ~(sizeof(int) - 1))
#endif
#define _crt_va_list _crt_va_list0 
#define _crt_va_arg(ap, t) (*(t *)((ap.i = (char *)_ROUNDT(t, (unsigned long long)(ap.i + _INTSIZEOF(t)))) - _INTSIZEOF(t)))
#define _crt_va_end(ap) (ap.i = nullptr);

__forceinline __device__ void _crt_va_restart(_crt_va_list &args) {
	args.i = args.b;
}
static __forceinline __device__ void _crt_va_start(_crt_va_list &args) {
	args.b = args.i = nullptr;
}
template <typename T1> static __forceinline __device__ void _crt_va_start(_crt_va_list1<T1> &args, T1 arg1) {
	args.b = args.i = (char *)&args.v1; args.v1 = arg1;
}
template <typename T1, typename T2> static __forceinline __device__ void _crt_va_start(_crt_va_list2<T1,T2> &args, T1 arg1, T2 arg2) {
	args.b = args.i = (char *)&args.v1; args.v1 = arg1; args.v2 = arg2;
}
template <typename T1, typename T2, typename T3> static __forceinline __device__ void _crt_va_start(_crt_va_list3<T1,T2,T3> &args, T1 arg1, T2 arg2, T3 arg3) {
	args.b = args.i = (char *)&args.v1; args.v1 = arg1; args.v2 = arg2; args.v3 = arg3;
}
template <typename T1, typename T2, typename T3, typename T4> static __forceinline __device__ void _crt_va_start(_crt_va_list4<T1,T2,T3,T4> &args, T1 arg1, T2 arg2, T3 arg3, T4 arg4) {
	args.b = args.i = (char *)&args.v1; args.v1 = arg1; args.v2 = arg2; args.v3 = arg3; args.v4 = arg4;
}
template <typename T1, typename T2, typename T3, typename T4, typename T5> static __forceinline __device__ void _crt_va_start(_crt_va_list5<T1,T2,T3,T4,T5> &args, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5) {
	args.b = args.i = (char *)&args.v1; args.v1 = arg1; args.v2 = arg2; args.v3 = arg3; args.v4 = arg4; args.v5 = arg5;
}
template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6> static __forceinline __device__ void _crt_va_start(_crt_va_list6<T1,T2,T3,T4,T5,T6> &args, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6) {
	args.b = args.i = (char *)&args.v1; args.v1 = arg1; args.v2 = arg2; args.v3 = arg3; args.v4 = arg4; args.v5 = arg5; args.v6 = arg6;
}
template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7> static __forceinline __device__ void _crt_va_start(_crt_va_list7<T1,T2,T3,T4,T5,T6,T7> &args, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6, T7 arg7) {
	args.b = args.i = (char *)&args.v1; args.v1 = arg1; args.v2 = arg2; args.v3 = arg3; args.v4 = arg4; args.v5 = arg5; args.v6 = arg6; args.v7 = arg7;
}
template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8> static __forceinline __device__ void _crt_va_start(_crt_va_list8<T1,T2,T3,T4,T5,T6,T7,T8> &args, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6, T7 arg7, T8 arg8) {
	args.b = args.i = (char *)&args.v1; args.v1 = arg1; args.v2 = arg2; args.v3 = arg3; args.v4 = arg4; args.v5 = arg5; args.v6 = arg6; args.v7 = arg7; args.v8 = arg8;
}
template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9> static __forceinline __device__ void _crt_va_start(_crt_va_list9<T1,T2,T3,T4,T5,T6,T7,T8,T9> &args, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6, T7 arg7, T8 arg8, T9 arg9) {
	args.b = args.i = (char *)&args.v1; args.v1 = arg1; args.v2 = arg2; args.v3 = arg3; args.v4 = arg4; args.v5 = arg5; args.v6 = arg6; args.v7 = arg7; args.v8 = arg8; args.v9 = arg9;
}
template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9, typename TA> static __forceinline __device__ void _crt_va_start(_crt_va_listA<T1,T2,T3,T4,T5,T6,T7,T8,T9,TA> &args, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6, T7 arg7, T8 arg8, T9 arg9, TA argA) {
	args.b = args.i = (char *)&args.v1; args.v1 = arg1; args.v2 = arg2; args.v3 = arg3; args.v4 = arg4; args.v5 = arg5; args.v6 = arg6; args.v7 = arg7; args.v8 = arg8; args.v9 = arg9; args.vA = argA;
}
// extended
template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9, typename TA, typename TB> static __forceinline __device__ void _crt_va_start(_crt_va_listB<T1,T2,T3,T4,T5,T6,T7,T8,T9,TA,TB> &args, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6, T7 arg7, T8 arg8, T9 arg9, TA argA, TB argB) {
	args.b = args.i = (char *)&args.v1; args.v1 = arg1; args.v2 = arg2; args.v3 = arg3; args.v4 = arg4; args.v5 = arg5; args.v6 = arg6; args.v7 = arg7; args.v8 = arg8; args.v9 = arg9; args.vA = argA; args.vB = argB;
}
template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9, typename TA, typename TB, typename TC> static __forceinline __device__ void _crt_va_start(_crt_va_listC<T1,T2,T3,T4,T5,T6,T7,T8,T9,TA,TB,TC> &args, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6, T7 arg7, T8 arg8, T9 arg9, TA argA, TB argB, TC argC) {
	args.b = args.i = (char *)&args.v1; args.v1 = arg1; args.v2 = arg2; args.v3 = arg3; args.v4 = arg4; args.v5 = arg5; args.v6 = arg6; args.v7 = arg7; args.v8 = arg8; args.v9 = arg9; args.vA = argA; args.vB = argB; args.vC = argC;
}
template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9, typename TA, typename TB, typename TC, typename TD> static __forceinline __device__ void _crt_va_start(_crt_va_listD<T1,T2,T3,T4,T5,T6,T7,T8,T9,TA,TB,TC,TD> &args, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6, T7 arg7, T8 arg8, T9 arg9, TA argA, TB argB, TC argC, TD argD) {
	args.b = args.i = (char *)&args.v1; args.v1 = arg1; args.v2 = arg2; args.v3 = arg3; args.v4 = arg4; args.v5 = arg5; args.v6 = arg6; args.v7 = arg7; args.v8 = arg8; args.v9 = arg9; args.vA = argA; args.vB = argB; args.vC = argC; args.vD = argD;
}
template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9, typename TA, typename TB, typename TC, typename TD, typename TE> static __forceinline __device__ void _crt_va_start(_crt_va_listE<T1,T2,T3,T4,T5,T6,T7,T8,T9,TA,TB,TC,TD,TE> &args, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6, T7 arg7, T8 arg8, T9 arg9, TA argA, TB argB, TC argC, TD argD, TE argE) {
	args.b = args.i = (char *)&args.v1; args.v1 = arg1; args.v2 = arg2; args.v3 = arg3; args.v4 = arg4; args.v5 = arg5; args.v6 = arg6; args.v7 = arg7; args.v8 = arg8; args.v9 = arg9; args.vA = argA; args.vB = argB; args.vC = argC; args.vD = argD; args.vE = argE;
}
template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9, typename TA, typename TB, typename TC, typename TD, typename TE, typename TF> static __forceinline __device__ void _crt_va_start(_crt_va_listF<T1,T2,T3,T4,T5,T6,T7,T8,T9,TA,TB,TC,TD,TE,TF> &args, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6, T7 arg7, T8 arg8, T9 arg9, TA argA, TB argB, TC argC, TD argD, TE argE, TF argF) {
	args.b = args.i = (char *)&args.v1; args.v1 = arg1; args.v2 = arg2; args.v3 = arg3; args.v4 = arg4; args.v5 = arg5; args.v6 = arg6; args.v7 = arg7; args.v8 = arg8; args.v9 = arg9; args.vA = argA; args.vB = argB; args.vC = argC; args.vD = argD; args.vE = argE; args.vF = argF;
}
// extended-2
template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9, typename TA, typename TB, typename TC, typename TD, typename TE, typename TF, typename T11> static __forceinline __device__ void _crt_va_start(_crt_va_list11<T1,T2,T3,T4,T5,T6,T7,T8,T9,TA,TB,TC,TD,TE,TF,T11> &args, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6, T7 arg7, T8 arg8, T9 arg9, TA argA, TB argB, TC argC, TD argD, TE argE, TF argF, T11 arg11) {
	args.b = args.i = (char *)&args.v1; args.v1 = arg1; args.v2 = arg2; args.v3 = arg3; args.v4 = arg4; args.v5 = arg5; args.v6 = arg6; args.v7 = arg7; args.v8 = arg8; args.v9 = arg9; args.vA = argA; args.vB = argB; args.vC = argC; args.vD = argD; args.vE = argE; args.vF = argF; args.v11 = arg11;
}
template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9, typename TA, typename TB, typename TC, typename TD, typename TE, typename TF, typename T11, typename T12> static __forceinline __device__ void _crt_va_start(_crt_va_list12<T1,T2,T3,T4,T5,T6,T7,T8,T9,TA,TB,TC,TD,TE,TF,T11,T12> &args, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6, T7 arg7, T8 arg8, T9 arg9, TA argA, TB argB, TC argC, TD argD, TE argE, TF argF, T11 arg11, T12 arg12) {
	args.b = args.i = (char *)&args.v1; args.v1 = arg1; args.v2 = arg2; args.v3 = arg3; args.v4 = arg4; args.v5 = arg5; args.v6 = arg6; args.v7 = arg7; args.v8 = arg8; args.v9 = arg9; args.vA = argA; args.vB = argB; args.vC = argC; args.vD = argD; args.vE = argE; args.vF = argF; args.v11 = arg11; args.v12 = arg12;
}
template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9, typename TA, typename TB, typename TC, typename TD, typename TE, typename TF, typename T11, typename T12, typename T13> static __forceinline __device__ void _crt_va_start(_crt_va_list13<T1,T2,T3,T4,T5,T6,T7,T8,T9,TA,TB,TC,TD,TE,TF,T11,T12,T13> &args, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6, T7 arg7, T8 arg8, T9 arg9, TA argA, TB argB, TC argC, TD argD, TE argE, TF argF, T11 arg11, T12 arg12, T13 arg13) {
	args.b = args.i = (char *)&args.v1; args.v1 = arg1; args.v2 = arg2; args.v3 = arg3; args.v4 = arg4; args.v5 = arg5; args.v6 = arg6; args.v7 = arg7; args.v8 = arg8; args.v9 = arg9; args.vA = argA; args.vB = argB; args.vC = argC; args.vD = argD; args.vE = argE; args.vF = argF; args.v11 = arg11; args.v12 = arg12; args.v13 = arg13;
}
template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9, typename TA, typename TB, typename TC, typename TD, typename TE, typename TF, typename T11, typename T12, typename T13, typename T14> static __forceinline __device__ void _crt_va_start(_crt_va_list14<T1,T2,T3,T4,T5,T6,T7,T8,T9,TA,TB,TC,TD,TE,TF,T11,T12,T13,T14> &args, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6, T7 arg7, T8 arg8, T9 arg9, TA argA, TB argB, TC argC, TD argD, TE argE, TF argF, T11 arg11, T12 arg12, T13 arg13, T14 arg14) {
	args.b = args.i = (char *)&args.v1; args.v1 = arg1; args.v2 = arg2; args.v3 = arg3; args.v4 = arg4; args.v5 = arg5; args.v6 = arg6; args.v7 = arg7; args.v8 = arg8; args.v9 = arg9; args.vA = argA; args.vB = argB; args.vC = argC; args.vD = argD; args.vE = argE; args.vF = argF; args.v11 = arg11; args.v12 = arg12; args.v13 = arg13; args.v14 = arg14;
}
template <typename T1, typename T2, typename T3, typename T4, typename T5, typename T6, typename T7, typename T8, typename T9, typename TA, typename TB, typename TC, typename TD, typename TE, typename TF, typename T11, typename T12, typename T13, typename T14, typename T15> static __forceinline __device__ void _crt_va_start(_crt_va_list15<T1,T2,T3,T4,T5,T6,T7,T8,T9,TA,TB,TC,TD,TE,TF,T11,T12,T13,T14,T15> &args, T1 arg1, T2 arg2, T3 arg3, T4 arg4, T5 arg5, T6 arg6, T7 arg7, T8 arg8, T9 arg9, TA argA, TB argB, TC argC, TD argD, TE argE, TF argF, T11 arg11, T12 arg12, T13 arg13, T14 arg14, T15 arg15) {
	args.b = args.i = (char *)&args.v1; args.v1 = arg1; args.v2 = arg2; args.v3 = arg3; args.v4 = arg4; args.v5 = arg5; args.v6 = arg6; args.v7 = arg7; args.v8 = arg8; args.v9 = arg9; args.vA = argA; args.vB = argB; args.vC = argC; args.vD = argD; args.vE = argE; args.vF = argF; args.v11 = arg11; args.v12 = arg12; args.v13 = arg13; args.v14 = arg14; args.v15 = arg15;
}

//#define _VA_LIST_DEFINED
#define va_list _crt_va_list0
#define va_list1 _crt_va_list1
#define va_list2 _crt_va_list2
#define va_list3 _crt_va_list3
#define va_list4 _crt_va_list4
#define va_list5 _crt_va_list5
#define va_list6 _crt_va_list6
#define va_list7 _crt_va_list7
#define va_list8 _crt_va_list8
#define va_list9 _crt_va_list9
#define va_listA _crt_va_listA
// extended
#define va_listB _crt_va_listB
#define va_listC _crt_va_listC
#define va_listD _crt_va_listD
#define va_listE _crt_va_listE
#define va_listF _crt_va_listF

#define _INC_SWPRINTF_INL_

#endif  /* _INC_STDARG */