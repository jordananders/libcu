#include <cuda_runtimecu.h>
#include <crtdefscu.h>
#include <stddefcu.h>
#include <stdlibcu.h>
#include <sentinel.h>

__BEGIN_DECLS;

#if HAS_DEVICESENTINEL

__device__ volatile unsigned int _sentinelMapId;
__constant__ sentinelMap *_sentinelDeviceMap[SENTINEL_DEVICEMAPS];
__device__ void sentinelDeviceSend(sentinelMessage *msg, int msgLength)
{
	sentinelMap *map = _sentinelDeviceMap[_sentinelMapId++ % SENTINEL_DEVICEMAPS];
	if (!map)
		panic("sentinel: device map not defined. did you start sentinel?\n");
	long id = atomicAdd((int *)&map->SetId, SENTINEL_MSGSIZE);
	sentinelCommand *cmd = (sentinelCommand *)&map->Data[id%sizeof(map->Data)];
	volatile long *status = (volatile long *)&cmd->Status;
	//cmd->Data = (char *)cmd + _ROUND8(sizeof(sentinelCommand));
	cmd->Magic = SENTINEL_MAGIC;
	cmd->Length = msgLength;
	if (msg->Prepare && !msg->Prepare(msg, cmd->Data, cmd->Data + msgLength + msg->Size, map->Offset))
		panic("msg too long");
	memcpy(cmd->Data, msg, msgLength);
	//printf("Msg: %d[%d]'", msg->OP, msgLength); for (int i = 0; i < msgLength; i++) printf("%02x", ((char *)msg)[i] & 0xff); printf("'\n");

	*status = 2;
	if (msg->Wait) {
		unsigned int s_; do { s_ = *status; /*printf("%d ", s_);*/ __syncthreads(); } while (s_ != 4); __syncthreads();
		memcpy(msg, cmd->Data, msgLength);
		*status = 0;
	}
}

#endif

__END_DECLS;
