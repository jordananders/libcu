#include <crtdefscu.h>

__BEGIN_DECLS;

// HOSTPTRS
#pragma region HOSTPTRS

typedef struct __align__(8) {
	hostptr_t *ptr;			// reference
	unsigned short id;		// ID of author
	unsigned short threadid;// thread ID of author
} hostRef;

__device__ hostRef __iob_hostRefs[CORE_MAXHOSTPTR]; // Start of circular buffer (set up by host)
volatile __device__ hostRef *__iob_freeDevicePtr = __iob_hostRefs; // Current atomically-incremented non-wrapped offset
volatile __device__ hostRef *__iob_retnDevicePtr = __iob_hostRefs; // Current atomically-incremented non-wrapped offset
__constant__ hostptr_t __iob_hostptrs[CORE_MAXHOSTPTR];

static __device__ __forceinline void writeHostRef(hostRef *ref, hostptr_t *p)
{
	ref->ptr = p;
	ref->id = gridDim.x*blockIdx.y + blockIdx.x;
	ref->threadid = blockDim.x*blockDim.y*threadIdx.z + blockDim.x*threadIdx.y + threadIdx.x;
}

__device__ hostptr_t *__hostptrGet(void *host)
{
	// advance circular buffer
	size_t offset = (atomicAdd((uintptr_t *)&__iob_freeDevicePtr, sizeof(hostRef)) - (size_t)&__iob_hostRefs);
	offset %= (sizeof(hostRef)*CORE_MAXHOSTPTR);
	int offsetId = offset / sizeof(hostRef);
	hostRef *ref = (hostRef *)((char *)&__iob_hostRefs + offset);
	hostptr_t *p = ref->ptr;
	if (!p) {
		p = &__iob_hostptrs[offsetId];
		writeHostRef(ref, p);
	}
	p->host = host;
	return p;
}

__device__ void __hostptrFree(hostptr_t *p)
{
	if (!p) return;
	// advance circular buffer
	size_t offset = atomicAdd((uintptr_t *)&__iob_retnDevicePtr, sizeof(hostRef)) - (size_t)&__iob_hostRefs;
	offset %= (sizeof(hostRef)*CORE_MAXHOSTPTR);
	hostRef *ref = (hostRef *)((char *)&__iob_hostRefs + offset);
	writeHostRef(ref, p);
}

#pragma endregion

// EXT-METHODS
#pragma region EXT-METHODS

__device__ ext_methods __extsystem = { nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, nullptr };

#pragma endregion

__END_DECLS;