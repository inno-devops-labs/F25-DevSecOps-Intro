import sys
import json


SEVERITY = {'critical': 5, 'elevated': 4, 'high': 3, 'medium': 2, 'low': 1}
LIKELIHOOD = {'very-likely': 4, 'likely': 3, 'possible': 2, 'unlikely': 1}
IMPACT = {'high': 3, 'medium': 2, 'low': 1}


def mdtable(tab):
    widths = [max(len(row[i]) for row in tab) for i in range(len(tab[0]))]
    totalw = sum(widths) + 3 * (len(tab[0]) - 1) + 4
    sep = '-' * totalw
    print(sep)
    for row in tab:
        print('| ' + ' | '.join(row[i].ljust(widths[i]) for i in range(len(row))) + ' |')
        print(sep)


def compkey(row):
    return SEVERITY[row[0]] * 100 + LIKELIHOOD[row[3]] * 10 + IMPACT[row[4]]


with open(sys.argv[1]) as f:
    risks = json.loads(f.read())
cols = ['severity', 'category', 'most_relevant_technical_asset', 'exploitation_likelihood', 'exploitation_impact']
prettycols = ['**Severity**', '**Category**', '**Asset**', '**Likelihood**', '**Impact**']
table = [[r[i] for i in cols] for r in risks]
table.sort(key=compkey, reverse=True)
table = table[:5]
mdtable([prettycols] + table)
