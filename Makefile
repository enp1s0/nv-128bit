NVCC=nvcc
NVCCFLAGS=-std=c++14 -arch=sm_75
TARGET=nv-128bit

$(TARGET): main.cu
	$(NVCC) $(NVCCFLAGS) -o $@ $<

clean:
	rm -f $(TARGET)
