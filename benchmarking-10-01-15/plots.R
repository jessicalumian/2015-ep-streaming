# 10-01-15 Benchmarking project

# Data from: literate resting eel pond protocol
# https://github.com/dib-lab/literate-resting/blob/master/kp/eel-pond.rst

# Gathered with sar in README, assimilated with extract.py from sartre
# https://github.com/ctb/sartre


# Install ggplot
install.packages("ggplot2")
library("ggplot2")

install.packages("gridExtra")
library("gridExtra")

## EEL POND WITHOUT STREAMING


# Load data
## Space-separated (no header assumed)
log.data <- read.table("~/benchmarking/nonstreaming/log.out") # with header

head(log.data)

# TEMP - looking at each graph separately working code V1 = time V2 = CPU
cpuplot <- ggplot(data=log.data, aes_string(x="V1", y="V2")) + 
  geom_line() + xlab("Time")
ramplot <- ggplot(data=log.data.gb, aes_string(x="V1", y="V2.1")) + geom_line()
diskplot <- ggplot(data=log.data, aes_string(x="V1", y="V4")) + geom_line()

cpuplot
ramplot
discplot

# Plot each graph (cpu, ram, disk) separately, 
# then use grid.arrange to stack

cpuplot <- ggplot(data=log.data, aes_string(x="V1", y="V2")) + 
  geom_line(color = "blue") + xlab("") + ylab("CPU load (100%)") +
  ggtitle("Eel Pond Without Streaming") + theme(axis.text.x = 
  element_blank(), axis.text.y = element_text(size = 17, color = "black", 
  face = "bold"), plot.title = element_text(face = "bold", size = 20))
  

ramplot <- ggplot(data=log.data, aes_string(x="V1", y="V3")) + 
  geom_line(color = "red") + xlab("") + ylab("RAM (GB)") +
  theme(axis.text.x = element_blank(), axis.text.y = element_text(
    angle = 45, size = 10, color = "black", face = "bold"))

diskplot <- ggplot(data=log.data, aes_string(x="V1", y="V4")) + 
  geom_line(color = "green") + xlab("Time (seconds)") + ylab("Disk (kTPS)") +
  theme(axis.text.x = element_text(size = 20, color = "black", 
        face = "bold"), axis.text.y = element_text(size = 13.5, 
        color = "black", face = "bold"))

grid.arrange(cpuplot,ramplot,diskplot)



## EEL POND WITH STREAMING

# Load data
## Space-separated (no header assumed)
log.data <- read.table("~/benchmarking/streaming/raw-ouput/10-10-15/log.out") # with header

head(log.data)

# Plot each graph (cpu, ram, disk) separately, 
# then use grid.arrange to stack

cpuplot <- ggplot(data=log.data, aes_string(x="V1", y="V2")) + 
  geom_line(color = "blue") + xlab("") + ylab("CPU load (100%)") +
  ggtitle("Eel Pond (1-2) With Streaming 10-10-15") + theme(axis.text.x = 
  element_blank(), axis.text.y = element_text(size = 18, color = "black", 
  face = "bold"), plot.title = element_text(face = "bold", size = 20))
  

ramplot <- ggplot(data=log.data, aes_string(x="V1", y="V3")) + 
  geom_line(color = "red") + xlab("") + ylab("RAM (GB)") +
  theme(axis.text.x = element_blank(), axis.text.y = element_text(
    angle = 45, size = 7, color = "black", face = "bold"))

diskplot <- ggplot(data=log.data, aes_string(x="V1", y="V4")) + 
  geom_line(color = "green") + xlab("Time (seconds)") + ylab("Disk (kTPS)") +
  theme(axis.text.x = element_text(size = 20, color = "black", 
    face = "bold"), axis.text.y = element_text(size = 13.5, 
    color = "black", face = "bold"))

grid.arrange(cpuplot,ramplot,diskplot)


#### Ram Corrected Version #### - work in progress

## EEL POND WITHOUT STREAMING - RAM CORRECTED


# Load data
## Space-separated (no header assumed)
log.data <- read.table("~/benchmarking/nonstreaming/log.out") # with header

head(log.data)

col3 <- log.data$V3/(10^9)

# Divide RAM (column V3) by e9 to get in GB -- this part doesn't work
log.data.gb <- data.frame(log.data[c(1,2,col3,4,5,6,7,8)])
log.data.gb <- data.frame(log.data[c(1,2,3,4,5,6,7,8)])

head(log.data.gb)

# try a for loop out of desperation (which also doesn't work)
for (i in log.data$V3) {
  log.data.gb[i] <- log.data$V3/(10^9)
}


# Plot each graph (cpu, ram, disk) separately, 
# then use grid.arrange to stack

cpuplot <- ggplot(data=log.data.gb, aes_string(x="V1", y="V2")) + 
  geom_line(color = "blue") + xlab("") + ylab("CPU load (100%)") +
  ggtitle("Eel Pond Without Streaming") + theme(axis.text.x = 
  element_blank(), axis.text.y = element_text(size = 12, color = "black", 
    face = "bold"), plot.title = element_text(face = "bold", size = 20))

ramplot <- ggplot(data=log.data.gb, aes_string(x="V1", y="V2.1")) + 
  geom_line(color = "red") + xlab("") + ylab("RAM (GB)") +
  theme(axis.text.x = element_blank(), axis.text.y = element_text(
     size = 12, color = "black", face = "bold"))

diskplot <- ggplot(data=log.data.gb, aes_string(x="V1", y="V4")) + 
  geom_line(color = "green") + xlab("Time (seconds)") + ylab("Disk (kTPS)") +
  theme(axis.text.x = element_text(size = 20, color = "black", 
    face = "bold"), axis.text.y = element_text(size = 11, 
    color = "black", face = "bold"))

grid.arrange(cpuplot,ramplot,diskplot)



## EEL POND WITH STREAMING

# Load data
## Space-separated (no header assumed)
log.data <- read.table("~/benchmarking/streaming/log.out") # with header

head(log.data)

# Divide RAM (column V3) by e9 to get in GB 
log.data.gb <- data.frame(log.data[c(1,2,3/10*9,4,5,6,7,8)])

head(log.data.gb)

# Plot each graph (cpu, ram, disk) separately, 
# then use grid.arrange to stack

cpuplot <- ggplot(data=log.data.gb, aes_string(x="V1", y="V2")) + 
  geom_line(color = "blue") + xlab("") + ylab("CPU load (100%)") +
  ggtitle("Eel Pond With Streaming") + theme(axis.text.x = 
  element_blank(), axis.text.y = element_text(size = 14, color = "black", 
    face = "bold"), plot.title = element_text(face = "bold", size = 20))

ramplot <- ggplot(data=log.data.gb, aes_string(x="V1", y="V2.1")) + 
  geom_line(color = "red") + xlab("") + ylab("RAM (GB)") +
  theme(axis.text.x = element_blank(), axis.text.y = element_text(
    size = 13, color = "black", face = "bold"))

diskplot <- ggplot(data=log.data.gb, aes_string(x="V1", y="V4")) + 
  geom_line(color = "green") + xlab("Time (seconds)") + ylab("Disk (kTPS)") +
  theme(axis.text.x = element_text(size = 20, color = "black", 
    face = "bold"), axis.text.y = element_text(size = 8, 
    color = "black", face = "bold"))

grid.arrange(cpuplot,ramplot,diskplot)




