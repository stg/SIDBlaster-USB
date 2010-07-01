// SIDblaster Driver
// senseitg@hotmail.com
//
// Intended as replacement for hardsid.dll
// Verified with SidPlay2/W and GoatTracker
// Compiles under MinGW

#include <stdio.h>
#include <string.h>
#include <windows.h>

#define DLLEXPORT						WINAPI DECLSPEC_EXPORT
#define HARDSID_VERSION			0x0200

#define SB_RESET						( WM_USER + 0x00 )
#define SB_WRITE    				( WM_USER + 0x01 )
#define SB_READ							( WM_USER + 0x02 )
#define SB_SYNC							( WM_USER + 0x03 )
#define SB_FLUSH						( WM_USER + 0x04 )
#define SB_MUTE							( WM_USER + 0x05 )
#define SB_MUTEALL					( WM_USER + 0x06 )
#define SB_SOFTFLUSH				( WM_USER + 0x07 )
#define SB_LOCK							( WM_USER + 0x08 )
#define SB_MUTELINE					( WM_USER + 0x09 )
#define SB_FILTER						( WM_USER + 0x09 )

typedef unsigned char Uint8;
typedef unsigned short Uint16;
typedef unsigned char boolean;

LRESULT SB_Call( Uint16 CallCode, Uint8 b1, Uint8 b2, int l1 ) {
	HWND Server;
	Server = FindWindowA( NULL, "HardSID_Host" );
	if( Server ) {
		return( SendMessageA( Server, CallCode, l1,  b1 << 8 | b2 ) );
	}
}

Uint16 DLLEXPORT HardSID_Version( void ) {
  return( HARDSID_VERSION );
}

Uint8 DLLEXPORT HardSID_Devices(void) {
	return( 1 );
}

void DLLEXPORT HardSID_Delay(Uint8 DeviceID, Uint16 Cycles) {
  SB_Call( SB_WRITE, 0x80, 0, Cycles );
}

void DLLEXPORT HardSID_Write(Uint8 DeviceID, int Cycles, Uint8 SID_reg, Uint8 Data) {
  SB_Call( SB_WRITE, SID_reg, Data, Cycles );
}

Uint8 DLLEXPORT HardSID_Read(Uint8 DeviceID, int Cycles, Uint8 SID_reg ) {
  return( SB_Call( SB_READ, SID_reg, 0, Cycles ) );
}

void DLLEXPORT HardSID_Flush(Uint8 DeviceID) {
  SB_Call( SB_FLUSH, 0, 0, 0 );
}

void DLLEXPORT HardSID_SoftFlush(Uint8 DeviceID) {
  SB_Call( SB_SOFTFLUSH, 0, 0, 0 );
}

boolean DLLEXPORT HardSID_Lock(Uint8 DeviceID) {
  SB_Call( SB_LOCK, 0, 0, 0 );
}

void DLLEXPORT HardSID_Filter( Uint8 DeviceID, boolean Filter ) {
  SB_Call( SB_FILTER, 0, 1, 0 );
}

void DLLEXPORT HardSID_Reset( Uint8 DeviceID ) {
  SB_Call( SB_RESET, 0, 1, 0 );
}

void DLLEXPORT HardSID_Sync( Uint8 DeviceID ) {
  SB_Call( SB_SYNC, 0, 0, 0 );
}

void DLLEXPORT HardSID_Mute( Uint8 DeviceID, Uint8 Channel, boolean Mute ) {
  SB_Call( SB_MUTE, Channel, Mute, 0 );
}

void DLLEXPORT HardSID_MuteAll( Uint8 DeviceID, boolean Mute ) {
  SB_Call( SB_MUTEALL, 0, Mute, 0 );
}

void DLLEXPORT InitHardSID_Mapper(void) {
  SB_Call( SB_RESET, 0, 0, 0 );
}

Uint8 DLLEXPORT GetHardSIDCount(void) {
	return( HardSID_Devices() );
}

void DLLEXPORT WriteToHardSID(Uint8 DeviceID, Uint8 SID_reg, Uint8 Data) {
	HardSID_Write( DeviceID, 1, SID_reg, Data );
}

Uint8 DLLEXPORT ReadFromHardSID(Uint8 DeviceID, Uint8 SID_reg) {
	return( HardSID_Read( DeviceID, 1, SID_reg ) );
}

void DLLEXPORT MuteHardSID_Line(int Mute) {
}
