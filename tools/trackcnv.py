import os.path
import sys

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

NOISE = 0x1
SQUARE = 0x2
TRIANGLE = 0x3
BD = 0x4

DATA_LENS = [0, 3, 4, 3, 1]


def to_hex(x):
    return x if type(x) == str else f'${x:02x}'


def get_track_type(s):
    if 'bass' in s:
        return TRIANGLE
    elif 'bd' in s:
        return BD
    elif 'clap' in s:
        return NOISE
    return SQUARE


delayMemory = {}


def get_delay_key(k, i):
    return f'{k}{i}'


def get_vd(volume, constVolFlag, haltFlag, dutyCycle):
    return volume | (constVolFlag << 4) | (haltFlag << 5) | (dutyCycle << 6)


def get_hi(tval, notelen):
    return ((tval >> 8) & 0xff) | notelen << 3


def handle_item(dout, k, value, arr, i):
    isTri = get_track_type(k) == TRIANGLE
    isSqu = get_track_type(k) == SQUARE
    isNoise = get_track_type(k) == NOISE
    isString = 'string' in k
    addDelay = (isString or 'lead' in k or 'clap' in k) and not isTri
    if value == '.':
        dn = delayMemory.get(get_delay_key(k, i), None)
        if addDelay and dn:
            if dn['type'] == SQUARE:
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
        tval = midi_to_tval(int(value, 10), isTri)
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
                constVolFlag = 0
            vd = get_vd(volume, constVolFlag, haltFlag, dutyCycle)
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
        else:
            dout += [hi]
        if addDelay:
            volumes = [0x6, 0x4, 0x3] if isString else [0x4, 0x2]
            delays = [4, 8, 12] if isString else [3, 4]
            for j, delayTicks in enumerate(delays):
                if isString:
                    dutyCycle += 1
                    if dutyCycle == 4:
                        dutyCycle = 0
                constVolFlag = 0x1
                vd = get_vd(volumes[j], constVolFlag, haltFlag, dutyCycle)
                lc = 0x14
                dIndex = get_delay_key(k, i+delayTicks)
                if not delayMemory.get(dIndex, None):
                    delayMemory[dIndex] = {
                        'type': get_track_type(k), 'vd': vd, 'lo': lo, 'hi': hi, 'lc': lc, 'swp': swp
                    }


def explode_repeats(v):
    out = []
    for x in v:
        if type(x) == str and x.startswith('.*'):
            out += (['.'] * int(x[2:], 10))
        else:
            out.append(x)
    return out


def output_section(out, k, v, isClip=False):
    out.append(f"{trackKey + k.replace('_','')}:")
    v = explode_repeats(v)
    dout = []
    for j, value in enumerate(v):
        if type(value) == list:
            for i, x in enumerate(value):
                handle_item(dout, k, x, value, i)
            dout += [SECTION_SPLIT]
        else:
            handle_item(dout, k, value, v, j)
    dout += [END_CODE]
    if isClip:
        dout = [TRACK_TYPE, get_track_type(k)] + dout
    out.append(f"\tdb {','.join([to_hex(x) for x in dout])}")


def output_nes(data):
    out = []
    out.append(
        f"{trackKey + 'tempo'}:\n\tdb ${int(data['meta']['_tempo'][0], 10):02x}")

    for k, v in data['clips'].items():
        output_section(out, k, v, True)

    for k, v in data['sections'].items():
        output_section(out, k, v)
    for v in data['track']:
        output_section(out, 'track', v)

    with open(outfile, 'w') as f:
        f.writelines([x + '\n' for x in out])


if __name__ == "__main__":
    main()
