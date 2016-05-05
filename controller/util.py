import re

p = re.compile(r'(?:export )?(.*?)=(.*)')
def parse_config(file):
    r = {}
    with open(file) as file:
        for line in file:
            m = p.match(line)
            if m: 
                r[m.group(1).strip()] = m.group(2).strip()
    return r

print parse_config('/root/keystonerc_a')
