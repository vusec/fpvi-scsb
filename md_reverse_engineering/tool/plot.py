import matplotlib.pyplot as plt
import sys

x = []
y1 = []
y2 = []
y3 = []

for line in sys.stdin:
    vals = line.split(";")
    i  = int(vals[0])
    x.append(i)
    c1  = int(vals[1])
    y1.append(c1)
    c2  = int(vals[2])
    y2.append(c2)
    c3  = int(vals[3])
    y3.append(c3)

x = x[1:]
y3 = y3[1:]
y1 = y1[1:]
y2 = y2[1:]

fig, axs = plt.subplots(3, 1, gridspec_kw={'height_ratios': [1, 1, 3]})
fig.suptitle('Memory disambiguation Analysis')

axs[0].plot(x, y1, label="Machine Clears")
axs[0].legend()
axs[1].plot(x, y2, label="Correct Prediction Outcome")
axs[1].legend()
axs[2].plot(x, y3, label="Time in cycles")
axs[2].legend()

plt.show()

