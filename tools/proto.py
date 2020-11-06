m = [0] * 128

subclipstart = 0x10
clipstart = 0x30
segmentstart = 0x50
trackstart = 0x70

I_POS_LO = 0
I_POS_HI = 1
I_ORG_LO = 2
I_ORG_HI = 3
I_TOT_REP = 4
I_CUR_REP = 5
I_INSTR = 6
I_REF_EN = 7

SUBCLIP_OFFSET = 0x20
END_STREAM = 0xff
END_SEGMENT = 0xfe
REF_COMMAND = 0xf0
INSTR_TYPE = 0xfc

TYPE_SQU = 2
TYPE_TRI = 3
TYPE_BD = 4

trackdata = [
    'filler', 0, 0,
    'cybass11',
    0xfc, 0x03, 0x7f, 0xbf, 0x83, 0x7f, 0xdf, 0x81, 0x7f, 0xbf, 0x83, 0x7f, 0xbf, 0x83, 0x7f, 0xbf, 0x83, 0x7f, 0xdf, 0x81, 0x7f, 0xbf, 0x83, 0x7f, 0xbf, 0x83, 0x7f, 0xdf, 0x81, 0x7f, 0xbf, 0x83, 0x7f, 0xdf, 0x81, 0x7f, 0xbf, 0x83, 0x7f, 0xdf, 0x81, 0x7f, 0xdf, 0x81, 0x7f, 0xbf, 0x83, 0x7f, 0xef, 0x80, 0xff,
    'cybass12',
    0xfc, 0x03, 0x7f, 0xbf, 0x83, 0x7f, 0xdf, 0x81, 0x7f, 0xbf, 0x83, 0x7f, 0xbf, 0x83, 0x7f, 0xbf, 0x83, 0x7f, 0xdf, 0x81, 0x7f, 0xbf, 0x83, 0x7f, 0xbf, 0x83, 0x7f, 0x1a, 0x82, 0x7f, 0xbf, 0x83, 0x7f, 0x1a, 0x82, 0x7f, 0xbf, 0x83, 0x7f, 0x93, 0x81, 0x7f, 0x93, 0x81, 0x7f, 0xbf, 0x83, 0x7f, 0xef, 0x80, 0xff,
    'cybass1',
    0xfc, 0x03, 0xf0, 'lo_cybass11', 'hi_cybass11', 0x03, 0xf0, 'lo_cybass12', 'hi_cybass12', 0x01, 0xff,
    'cylead1',
    0xfc, 0x02, 0x9f, 0x00, 0xdf, 0x81, 0x00, 0x00, 0x00, 0x00, 0x9f, 0x00, 0x0c, 0x81, 0x94, 0x00, 0xdf, 0x81, 0x9f, 0x00, 0x3f, 0x81, 0x94, 0x00, 0x0c, 0x81, 0x9f, 0x00, 0xc9, 0x80, 0x9f, 0x00, 0xd5, 0x80, 0x00, 0x00, 0x00, 0x00, 0x9f, 0x00, 0x0c, 0x81, 0x9f, 0x00, 0xef, 0x80, 0x00, 0x00, 0x00, 0x00, 0x94, 0x00, 0x0c, 0x81, 0x94, 0x00, 0xef, 0x80, 0x9f, 0x00, 0x3f, 0x81, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x94, 0x00, 0x3f, 0x81, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff,
    'cybd1',
    0xfc, 0x04, 0x86, 0x00, 0x00, 0x00, 0x86, 0x00, 0x00, 0x00, 0x86, 0x00, 0x00, 0x00, 0x86, 0x00, 0x00, 0x00, 0xff,
    'cybd2',
    0xfc, 0x04, 0xf0, 'lo_cybd1', 'hi_cybd1', 0x03, 0x86, 0x00, 0x00, 0x00, 0x86, 0x00, 0x00, 0x00, 0x86, 0x00, 0x00, 0x00, 0x86, 0x86, 0x86, 0x00, 0xff,
    'cyclap',
    0xfc, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x1a, 0x05, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x14, 0x05, 0x00, 0xff,
    'cyintro',
    0xf0, 'lo_cybass1', 'hi_cybass1', 0x01, 0xf0, 'lo_cybd2', 'hi_cybd2', 0x01, 0xf0, 'lo_cyclap', 'hi_cyclap', 0x08, 0xf0, 'lo_cylead1', 'hi_cylead1', 0x02, 0xfe, 0xff,
    'track',
    0xf0, 'lo_cyintro', 'hi_cyintro', 0x01, 0xff
]


def find_last(arr, value):
    return max(loc for loc, val in enumerate(arr) if val == value)


keys = [x for x in trackdata if type(x) == str and not '_' in x]
indexes = {}
for key in keys:
    loc = find_last(trackdata, key)
    indexes[key] = loc
    del trackdata[loc]

a = 0
offset = 0
buffer = []
resetFlag = 0


def print_mem():
    global m
    for i in range(0, len(m), 16):
        out = []
        for j in range(16):
            out.append(f'{m[i+j]:02x}')
        print(' '.join(out))
    print()


def get_addr(s):
    return indexes[s.split('_')[-1]]


GREEN = '\033[92m'
BLUE = '\033[94m'
YELLOW = '\033[93m'
CYAN = '\033[96m'


def advance():
    global a
    global m
    global offset
    global buffer
    global resetFlag

    resetFlag = 0
    isSegment = a == segmentstart
    isTrack = a == trackstart
    isSubclip = a == subclipstart
    clipRefOffset = 0

    storePos = True

    i = a + offset

    # Processing ref or addr zero => do nothing
    if m[i + I_REF_EN] or m[i + I_POS_LO] == 0:
        print(f'{a:02x}', offset, 'not enabled', m[i + I_REF_EN])
        return
    # Advance
    pos = m[i + I_POS_LO]
    while True:
        byte = trackdata[pos]
        pos += 1
        # print('byte is', f'{byte:02x}')
        done = False
        if byte == REF_COMMAND:

            if a == subclipstart:
                print('illegal ref at subclip', a, offset)

            # Activate ref
            m[i + I_REF_EN] = 1
            # Read and store ref
            subclipI = i - SUBCLIP_OFFSET + (clipRefOffset * 8)
            print(f'{a:02x}', offset, 'REF', clipRefOffset, f'{subclipI:02x}')
            if isSegment:
                clipRefOffset += 1
                if clipRefOffset == 4:
                    clipRefOffset = 0
            addr = get_addr(trackdata[pos])
            # skip hi
            pos += 2
            m[subclipI + I_POS_LO] = addr
            m[subclipI + I_ORG_LO] = addr
            repeats = trackdata[pos]
            pos += 1
            m[subclipI + I_TOT_REP] = repeats
            m[subclipI + I_CUR_REP] = 0
            m[subclipI + I_REF_EN] = 0

            # indicate that ref was activated
            resetFlag = 2

            done = not isSegment
        elif byte == INSTR_TYPE:
            # Read instrument type
            instr = trackdata[pos]
            print(f'{a:02x}', offset, 'INSTR_TYPE', instr)
            pos += 1
            m[i + I_INSTR] = instr
        elif byte == END_SEGMENT:
            print(f'{a:02x}', offset, 'END_SEGMENT')
            done = True
        elif byte == END_STREAM:
            print(f'{a:02x}', offset, 'END_STREAM')
            # Increase repeat count
            m[i + I_CUR_REP] += 1
            # Check repeat
            if m[i + I_CUR_REP] < m[i + I_TOT_REP] or isTrack:
                print(f'{a:02x}', offset, 'repeats', m[i + I_CUR_REP], m[i + I_TOT_REP])
                # Reset addr
                print(f'{a:02x}', offset, 'reset addr', m[i + I_POS_LO], m[i + I_ORG_LO])
                m[i + I_POS_LO] = m[i + I_ORG_LO]
                pos = m[i + I_POS_LO]
                # Read more
                done = False
            else:
                # Ended, zero this
                print(f'{a:02x}', offset, i, 'zeroing')
                m[i + I_POS_LO] = 0
                m[i + I_POS_HI] = 0
                # ...and disable ref of parent
                if isSubclip or isSegment:
                    parentIndex = i + I_REF_EN + SUBCLIP_OFFSET
                    if m[parentIndex] == 1:
                        m[parentIndex] = 0
                resetFlag = 1
                storePos = False
                done = True
        else:
            instrType = m[i + I_INSTR]
            print(f'{a:02x}', offset, 'NOTE', byte, 'instr', instrType)
            # Read note
            if byte == 0:
                # Rest
                if instrType == TYPE_SQU:
                    pos += 3
                elif instrType == TYPE_BD:
                    pass
                else:
                    pos += 2
            else:
                if instrType == TYPE_BD:
                    buffer.append(['bd'] + [byte])
                elif instrType == TYPE_SQU:
                    buffer.append(['sq'] + [byte] + trackdata[pos:pos+3])
                    pos += 3
                elif instrType == TYPE_TRI:
                    buffer.append(['tr'] + [byte] + trackdata[pos:pos+2])
                    pos += 2
                else:  # noise
                    buffer.append(['no'] + [byte] + trackdata[pos:pos+2])
                    pos += 2
                pass
            done = True

        if storePos:
            m[i + I_POS_LO] = pos

        if done:
            break


def advance_from_segment():
    global a
    global m
    global offset
    global buffer

    a = segmentstart
    offset = 0
    advance()

    if resetFlag == 1:
        a = trackstart
        advance()
        a = segmentstart
        advance()


def do_zero_check():
    global a
    global m
    global offset
    global buffer

    # check if all clips are zero => disable segment ref bit
    zeros = 0
    for i in range(4):
        a = clipstart
        if m[a + i*8 + I_POS_LO] == 0:
            zeros += 1
    print('zeros', zeros)
    if zeros == 4:
        a = segmentstart
        m[a + I_REF_EN] = 0
        advance_from_segment()
        advance_clips()


def advance_clips():
    global a
    global m
    global offset
    global buffer

    for i in range(4):
        a = clipstart
        offset = i * 8
        advance()
    do_zero_check()


def main():
    global a
    global m
    global offset
    global buffer

    output = []

    print(indexes)

    frames = 131

    while True:
        buffer = []
        offset = 0
        a = trackstart
        # Store track start
        m[a + I_POS_LO] = indexes['track']
        m[a + I_ORG_LO] = indexes['track']

        a = trackstart
        offset = 0
        advance()

        advance_from_segment()

        advance_clips()

        print('after clips', frames)
        print_mem()

        for i in range(4):
            a = subclipstart
            offset = i * 8
            advance()
            if resetFlag == 1:
                # advance the corresponding clip
                a = clipstart
                print('mem before advance', frames)
                print_mem()
                advance()
                print('advanced clip because of resetFlag at index',
                      i, 'resetFlag is now', resetFlag)
                print_mem()
                do_zero_check()
                if resetFlag == 2:
                    # clip activated ref
                    a = subclipstart
                    advance()
                    print('advanced subclip because of clip activated ref at index', i)

        print('after subclips', frames)
        print_mem()

        output.append(buffer)

        frames -= 1
        if frames == 0:
            break

    print_mem()
    for i, line in enumerate(output):
        print(YELLOW, end='')
        print(str(i+1) + ' ', end='')
        for item in line:
            if 'bd' in item:
                print(GREEN, end='')
            elif 'no' in item:
                print(CYAN, end='')
            elif 'sq' in item:
                print(BLUE, end='')
            else:
                print(YELLOW, end='')
            print([(f'{x:02x}' if type(x) != str else x) for x in item], end='')
            print(' ', end='')
        print()
        if i % 4 == 3:
            print()


if __name__ == "__main__":
    main()
