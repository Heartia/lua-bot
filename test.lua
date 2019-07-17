line = "randomaccount#0000 randomaccount#0000"
words = {}
words[1], words[2] = line:match("(%w+)(%w+)")
print(words[1], words[2])
