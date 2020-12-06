import os.path
import sys
import math

infile = sys.argv[1]
platform = sys.argv[2]
outfile = sys.argv[3]
data = {}
trackKey = os.path.split(infile)[-1][:2]


def main():
    with open(infile, 'r') as f:
        lines = [x.strip() for x in f.readlines()]

    section = None
    for line in lines:
        line = line.strip()
        if not len(line) or line.startswith(';'):
            continue
        if ':' in line:
            section = line.replace(':', '').strip()
            continue
        isSection = section == 'sections'
        isDef = section != 'track'
        if line.startswith('_'):
            parts = [x for x in line.split(' ') if len(x)]
            if not data.get(section, None):
                data[section] = {} if isDef else []
            if isDef:
                payload = parts[1:]
                if isSection:
                    payload = ' '.join(parts[1:]).split(',')
                    payload = [x.split(' ') for x in payload]
                data[section][parts[0]] = payload
            else:
                data[section].append(parts)

    if platform == 'nes':
        output_nes(data)


NES_CPU_CLK = {
    'PAL': 1662607,
    'NTSC': 1789773
}

TUNING = 440


def midi_freq(midinote):
    return 2**((midinote - 69) / 12) * TUNING


def midi_to_tval(midinote, triangle=False, standard='NTSC'):
    coeff = 32 if triangle else 16
    return round(NES_CPU_CLK[standard]/(coeff*midi_freq(midinote))-1)


REF_CODE = 0xf0
END_CODE = 0xff
SECTION_SPLIT = 0xfe
TRACK_TYPE = 0xfc
TEMPO_COMMAND = 0xfb

NOISE = 0x1
SQUARE = 0x2
TRIANGLE = 0x3
PERC = 0x4
SQUARE_2 = 0x5

DATA_LENS = [0, 3, 4, 3, 1, 4]


def to_hex(x):
    return x if type(x) == str else f'${x:02x}'


def get_track_type(s):
    if 'bass' in s:
        return TRIANGLE
    elif 'bd' in s or 'dr' in s or 'clap' in s:
        return PERC
    elif 'string' in s:
        return SQUARE_2
    return SQUARE


delayMemory = {}


def get_delay_key(k, i):
    return f'{k}{i}'


def get_vd(volume, constVolFlag, haltFlag, dutyCycle):
    return volume | (constVolFlag << 4) | (haltFlag << 5) | (dutyCycle << 6)


def get_hi(tval, notelen):
    return ((tval >> 8) & 0xff) | notelen << 3

def get_divisor(k):
    divisor = 16
    if '/' in k:
        divParts = k.split('/')
        divisor = int(divParts[1],10)
        k = divParts[0]
    return (k,divisor)

volumeScale = 1.0
latest = {}

def handle_item(dout, k, value, arr, i):
    global volumeScale
    isTri = get_track_type(k) == TRIANGLE
    isSqu = get_track_type(k) == SQUARE or get_track_type(k) == SQUARE_2
    isNoise = get_track_type(k) == NOISE
    isString = 'string' in k
    addDelay = (isString or 'lead' in k) and not isTri
    if value.startswith('v'):
        volumeScale = float(value.split('v')[-1])
        return
    if value == '.':
        dn = delayMemory.get(get_delay_key(k, i), None)
        if addDelay and dn and ((isString and dn['note'] == latest[k]) or (not isString)):
            if dn['type'] == SQUARE or dn['type'] == SQUARE_2:
                dout += [dn['vd'], dn['swp'], dn['lo'], dn['hi']]
            else:
                dout += [dn['lc'], dn['lo'], dn['hi']]
        else:
            dout += ([0] * DATA_LENS[get_track_type(k)])
    elif '_' in value:
        parts = value.split('*')
        ref = trackKey + parts[0][1:]
        times = 1 if len(parts) == 1 else int(parts[1], 10)
        dout += [REF_CODE, f'<{ref}', f'>{ref}', times]
    else:
        tval = 0
        intValue = 0
        try:
            intValue = int(value, 10)
            tval = midi_to_tval(intValue, isTri)
            latest[k] = intValue
        except ValueError:
            print('skipping ' + value)
        lo = tval & 0xff
        notelen = 0b10000  # TODO calc proper length
        hi = get_hi(tval, notelen)
        lc = 0
        swp = 0
        dutyCycle = 0x2
        haltFlag = 0
        constVolFlag = 0x1
        volume = 0xf
        if isSqu:
            if isString:
                dutyCycle = 0x1
                constVolFlag = 1 if volumeScale < 1.0 else 0
            vd = get_vd(round(volume * volumeScale), constVolFlag, haltFlag, dutyCycle)
            if isString:
                hi = get_hi(tval, 0b00001)
            dout += [vd, swp, lo, hi]
        elif isTri:
            lc = 0x7f
            dout += [lc, lo, hi]
        elif isNoise:
            lc = 0x1a
            lo = 0x5
            hi = 0
            dout += [lc, lo, hi]
        else:  # PERC
            hi = 0
            if 's' in value:
                hi = 0b10000000
                value = value[:-1]
            hi = hi | int(value, 10)
            dout += [hi]
        if addDelay:
            volumes = [0x6, 0x4, 0x3] if isString else [0x4, 0x2]
            delays = [4, 8, 12] if isString else [3, 4]
            (_,divisor) = get_divisor(k)
            delays = [int(x * (divisor / 16)) for x in delays]
            for j, delayTicks in enumerate(delays):
                # if isString:
                #    dutyCycle += 1
                #    if dutyCycle == 4:
                #        dutyCycle = 0
                constVolFlag = 0x1
                vd = get_vd(math.ceil(volumes[j]), constVolFlag, haltFlag, dutyCycle)
                lc = 0x14
                dIndex = get_delay_key(k, i+delayTicks)
                if not delayMemory.get(dIndex, None):
                    delayMemory[dIndex] = {
                        'type': get_track_type(k),
                        'vd': vd,
                        'lo': lo,
                        'hi': hi,
                        'lc': lc,
                        'swp': swp,
                        'note': intValue
                    }


def explode_repeats(v):
    out = []
    for x in v:
        if type(x) == str and x.startswith('.*'):
            out += (['.'] * int(x[2:], 10))
        else:
            out.append(x)
    return out


def output_section(out, k, v, isClip=False, prefixData=None):
    global volumeScale
    (cleanKey, _) = get_divisor(k)
    out.append(f"{trackKey + cleanKey.replace('_','')}:")
    v = explode_repeats(v)
    dout = []
    if prefixData:
        dout += prefixData
    volumeScale = 1.0
    for j, value in enumerate(v):
        if type(value) == list:
            volumeScale = 1.0
            for i, x in enumerate(value):
                handle_item(dout, k, x, value, i)
            dout += [SECTION_SPLIT]
        else:
            handle_item(dout, k, value, v, j)
    dout += [END_CODE]
    if isClip:
        (_,divisor) = get_divisor(k)
        dout = [TRACK_TYPE, (divisor << 3) | get_track_type(k)] + dout
    out.append(f"\tdb {','.join([to_hex(x) for x in dout])}")


TEMPO_COEFF_NTSC = 0.28

def output_nes(data):
    out = []

    for k, v in data['clips'].items():
        output_section(out, k, v, True)

    for k, v in data['sections'].items():
        output_section(out, k, v)
    for v in data['track']:
        output_section(out, 'track', v, False,
        [f"${TEMPO_COMMAND:02x}", f"${round(int(data['meta']['_tempo'][0], 10)*TEMPO_COEFF_NTSC):02x}"])

    with open(outfile, 'w') as f:
        f.writelines([x + '\n' for x in out])


if __name__ == "__main__":
    main()
