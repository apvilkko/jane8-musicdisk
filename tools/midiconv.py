import sys
from struct import unpack

EVENT_META = 0xff
V_NOTE_OFF = 0x80
V_NOTE_ON = 0x90
V_PROGRAM_CHANGE = 0xc0


def get_vlq(data):
    s = 0
    p = 0
    while True:
        s = (s << 7) | (data[p] & 0x7f)
        if data[p] & 0x80 == 0:
            break
        p += 1
    return (s, p+1)


events = {
    0x02: 'COPYRIGHT',
    0x03: 'SEQNAME',
    0x2f: 'ENDOFTRACK',
    0x51: 'TEMPO'
}


def get_voice_message(evt):
    status = evt & 0xf0
    if status in [V_NOTE_OFF, V_NOTE_ON, 0xa0, 0xb0, 0xe0]:
        return (status, 2)
    elif status in [V_PROGRAM_CHANGE, 0xd0]:
        return (status, 1)
    return (None, 0)


infile = sys.argv[1]
with open(infile, 'rb') as f:
    data = f.read()
    pos = 0
    while pos+4 < len(data):
        chunkType = data[pos:pos+4].decode('ascii')
        pos += 4
        chunkLen = unpack('>i', data[pos:pos+4])[0]
        pos += 4
        chunkData = data[pos:pos+chunkLen]
        pos += chunkLen
        if chunkType == 'MThd':
            (fmt, tracks, division) = unpack('>hhh', chunkData[:6])
            print(f'division {division}')
        elif chunkType == 'MTrk':
            p = 0
            print('***MTrk***')
            while p < len(chunkData):
                (deltaTime, length) = get_vlq(chunkData[p:])
                p += length
                try:
                    evt = chunkData[p]
                except IndexError:
                    break
                p += 1
                # print(f'evt {evt:02x}', )
                (message, length) = get_voice_message(evt)
                if message:
                    channel = evt & 0xf
                    (kk, vv) = (chunkData[p], chunkData[p+1])
                    if message in [V_NOTE_ON, V_NOTE_OFF, V_PROGRAM_CHANGE]:
                        if length == 2:
                            print(
                                f'{deltaTime} {message:02x} {channel} {kk:x} {vv:x}')
                        else:
                            print(f'{deltaTime} {message:02x} {channel} {kk:x}')
                        if message == V_PROGRAM_CHANGE and kk > 0:
                            print(
                                f'instrument for channel {channel+1} is {kk}')
                    p += length
                elif evt == EVENT_META:
                    metatype = chunkData[p]
                    p += 1
                    (evtLength, length) = get_vlq(chunkData[p:])
                    p += length
                    evtData = chunkData[p:p+evtLength]
                    p += evtLength
                    name = events.get(metatype, None)
                    if not name:
                        exit(
                            f'no event {metatype:x} {(pos-chunkLen+p):x} {evtData}')
                    if name == 'TEMPO':
                        tempo = round(60 / (unpack('>i', bytearray(
                            [0]) + evtData)[0] / 1000000))
                        print(f'tempo is {tempo}')
