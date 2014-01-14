# -*- coding: utf-8 -*-   
import jieba
import csv


def tokenize(rawtext):
    rawtext = unicode(rawtext, 'utf-8')
    seg_list = jieba.cut(rawtext)
    return " ".join(seg_list)


f = open('cy_text.csv', 'r')
cy_text = [tokenize(row['x']) for row in csv.DictReader(f)]
f.close()

f = open('tsang_text.csv', 'r')
tsang_text = [tokenize(row['x']) for row in csv.DictReader(f)]
f.close()

f = open("cy_tokenized.txt", "w")
for text in cy_text:
    f.write(text.encode('utf-8') + "\n")
f.close()


f = open("tsang_tokenized.txt", "w")
for text in tsang_text:
    f.write(text.encode('utf-8') + "\n")
f.close()
