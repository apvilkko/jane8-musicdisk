import sys
import pprint
import os.path
from struct import unpack

infilename = sys.argv[1]
outfilename = sys.argv[2] if len(sys.argv) > 2 else None

KICK = 1
BASS = 2
LONG_LEAD = 3
LEAD = 4
CLAP = 5
HHC = 6
HHO = 7

NOISE =    0b10000000
PULSE =    0b01000000
SAWTOOTH = 0b00100000
TRIANGLE = 0b00010000

INSTRUMENTS = [
    [KICK, {'osc': NOISE}],
    [BASS, {'osc': SAWTOOTH}],
    [LONG_LEAD, {'osc': PULSE}],
    [LEAD, {'osc': PULSE}],
    [CLAP, {'osc': NOISE}],
    [HHC, {'osc': TRIANGLE}],
    [HHO, {'osc': TRIANGLE}],
]

def ntstr(b):
    return b.decode('ascii').rstrip('\0')

def short(b, offset):
    return unpack('<h', b[offset:offset+2])[0]

def long(b, offset):
    return unpack('<l', b[offset:offset+4])[0]

def long_arr(b, offset, length):
    return list(unpack('<' + 'l'*length, b[offset:offset+length*4]))


def read_patterns(out, data):
    ret = []
    channel_data = {}
    for i in range(out['pat_num']):
        pos = out['pat_offsets'][i]
        pattern = {}
        pattern['length'] = short(data, pos)
        pattern['rows'] = short(data, pos + 2)
        pos = pos + 8
        notes = []
        row = 0

        #print(list(data[pos:pos+32]))

        while True:
            channelvariable = data[pos]
            if channelvariable == 0:
                # end of row
                row = row + 1
                if row == pattern['rows']:
                    break
            channel = (channelvariable-1) & 63
            if not channel in channel_data:
                channel_data[channel] = {'maskvariable':0}
            if channelvariable & 128:
                pos = pos + 1
                channel_data[channel]['maskvariable'] = data[pos]
            maskvariable = channel_data[channel]['maskvariable']
            note = {'channel': channel, 'row': row}
            if maskvariable & 1:
                # read note
                pos = pos + 1
                note['note'] = data[pos]
                channel_data[channel]['note'] = note['note']
            if maskvariable & 2:
                # read instrument
                pos = pos + 1
                note['ins'] = data[pos]
                channel_data[channel]['ins'] = note['ins']
            if maskvariable & 4:
                # read vol/pan
                pos = pos + 1
                note['vol_pan'] = data[pos]
                channel_data[channel]['vol_pan'] = note['vol_pan']
            if maskvariable & 8:
                # read command & commandvalue
                pos = pos + 1
                note['command'] = data[pos]
                pos = pos + 1
                note['command_value'] = data[pos]
            if note['channel'] < 63:
                if not 'note' in note:
                    note['note'] = channel_data[channel]['note']
                if not 'ins' in note:
                    note['ins'] = channel_data[channel]['ins']
                if not 'vol_pan' in note and 'vol_pan' in channel_data[channel]:
                    note['vol_pan'] = channel_data[channel]['vol_pan']
                # filter small volumes
                if not 'vol_pan' in note or note['vol_pan'] > 63:
                    notes.append(note)
            pos = pos + 1
        pattern['notes'] = notes
        #pprint.pprint(pattern)
        ret.append(pattern)
    return ret

CHANNELS = 3
REST = 0b10000000
SAME = 0b01000000

def to_pitch(note, ins):
    if ins == BASS:
        return note - 12*3
    elif ins == LEAD:
        return note - 12*2
    elif ins == LONG_LEAD:
        return note - 12
    return note

# Instrument priority
def sorter(item):
    if item['ins'] == CLAP:
        return 0
    if item['ins'] == LEAD:
        return 1
    if item['ins'] == LONG_LEAD:
        return 2
    if item['ins'] == KICK:
        return 3
    #if item['ins'] == BASS:
    #    return 4
    return 100


def write_bin(song, filename):
    out = []
    mem = {0: {}, 1:{},2:{},3:{}}
    count = 0
    for order in song['orders']:
        if order == 255:
            break
        pattern = song['patterns'][order]
        #if count < 8:
        #    continue
        #print("pattern", pattern)
        for i in range(0, pattern['rows']):
            items = sorted(list(filter(lambda x: x['row']==i, pattern['notes'])), key=sorter)
            #print("row", i, items)
            for i in range(0, CHANNELS):
                item = items[i] if len(items) > i else None
                if item is None:
                    out.append(REST)
                else:
                    memIns = mem[item['channel']]['ins'] if 'ins' in mem[item['channel']] else None
                    memNote = mem[item['channel']]['note'] if 'note' in mem[item['channel']] else None
                    ins = item['ins'] if 'ins' in item else memIns
                    note = item['note'] if 'note' in item else memNote
                    if ins == memIns and note == memNote:
                        out.append(SAME)
                    else:
                        mem[item['channel']]['ins'] = ins
                        mem[item['channel']]['note'] = note
                        byte1 = to_pitch(note, ins)
                        # TODO support effect
                        byte2 = ins
                        out.append(byte1)
                        out.append(byte2)
        count += 1
    (root, ext) = os.path.splitext(filename)
    outfile = outfilename if outfilename else os.path.split(root)[1] + '.bin'
    with open(outfile, 'wb') as f:
        #print(out)
        f.write(bytes(out))
    print("Wrote " + outfile)

def write_instruments(song, filename):
    (root, ext) = os.path.splitext(outfilename if outfilename else filename)
    outfile = root + '.inst.bin'
    out = []
    for ins in INSTRUMENTS:
        data = ins[1]
        byte1 = data['osc']
        byte2 = 0
        byte3 = 0
        byte4 = 0
        out.append(byte1)
        out.append(byte2)
        out.append(byte3)
        out.append(byte4)

    with open(outfile, 'wb') as f:
        f.write(bytes(out))
    print("Wrote " + outfile)

def main():
    with open(infilename, 'rb') as f:
        data = f.read()
        if data[0:4].decode('ascii') != 'IMPM':
            exit("Not an Impulse Tracker module!")
        out = {}
        out['song_name'] = ntstr(data[4:30])
        out['ord_num'] = short(data, 0x20)
        out['ins_num'] = short(data, 0x22)
        out['smp_num'] = short(data, 0x24)
        out['pat_num'] = short(data, 0x26)
        out['cwt_v'] = short(data, 0x28)
        out['cmwt'] = short(data, 0x2a)
        out['flags'] = short(data, 0x2c)
        out['special'] = short(data, 0x2e)
        out['gv'] = data[0x30]
        out['mv'] = data[0x31]
        out['is'] = data[0x32]
        out['it'] = data[0x33]
        out['sep'] = data[0x34]
        out['msg_lgth'] = short(data, 0x36)
        out['msg_offset'] = long(data, 0x38)
        ord_end = 0xc0+out['ord_num']
        out['orders'] = list(data[0xc0:ord_end])
        ins_offset = ord_end
        ins_end = ins_offset + out['ins_num']*4
        out['ins_offsets'] = long_arr(data, ins_offset, out['ins_num'])
        smp_offset = ins_end
        smp_end = smp_offset + out['smp_num']*4
        out['smp_offsets'] = long_arr(data, smp_offset, out['smp_num'])
        pat_offset = smp_end
        pat_end = pat_offset + out['pat_num']*4
        out['pat_offsets'] = long_arr(data, pat_offset, out['pat_num'])
        out['patterns'] = read_patterns(out, data)
        #print(out)

    write_bin(out, infilename)
    write_instruments(out, infilename)


if __name__ == "__main__":
    main()
