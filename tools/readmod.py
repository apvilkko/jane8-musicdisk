import sys
import pprint
from struct import unpack

infilename = sys.argv[1]

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
    for i in range(out['pat_num']):
        pos = out['pat_offsets'][i]
        pattern = {}
        pattern['length'] = short(data, pos)
        pattern['rows'] = short(data, pos + 2)
        pos = pos + 8
        channel_data = {}
        notes = []
        row = 0

        print(list(data[pos:pos+32]))

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
            if maskvariable & 2:
                # read instrument
                pos = pos + 1
                note['ins'] = data[pos]
            if maskvariable & 4:
                # read vol/pan
                pos = pos + 1
                note['vol_pan'] = data[pos]
            if maskvariable & 8:
                # read command & commandvalue
                pos = pos + 1
                note['command'] = data[pos]
                pos = pos + 1
                note['command_value'] = data[pos]
            if note['channel'] < 63:
                notes.append(note)
            pos = pos + 1
        pattern['notes'] = notes
        pprint.pprint(pattern)
        ret.append(pattern)
    return ret

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


if __name__ == "__main__":
    main()
