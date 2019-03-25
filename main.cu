#include <iostream>
#include <chrono>
#include <memory>

constexpr std::size_t N = 1 << 28;
constexpr std::size_t mem_N = N * 4;
constexpr std::size_t num_threads = 1 << 8;
constexpr std::size_t test_count = 1 << 10;

__global__ void read_global(float* const dst, const float* const src){
	const auto tid = blockIdx.x * blockDim.x + threadIdx.x;

	const auto tmp0 = src[tid * 4 + 0];
	const auto tmp1 = src[tid * 4 + 1];
	const auto tmp2 = src[tid * 4 + 2];
	const auto tmp3 = src[tid * 4 + 3];

	dst[tid] = tmp0 * tmp1 * tmp2* tmp3;
}

__global__ void read_global_128(float* const dst, const float* const src){
	const auto tid = blockIdx.x * blockDim.x + threadIdx.x;

	const auto tmp = reinterpret_cast<const float4*>(src);

	dst[tid] = tmp->x * tmp->y * tmp->z * tmp->z;
}

template <class Func>
double get_elapsed_time(Func func){
	const auto start = std::chrono::system_clock::now();
	func();
	cudaDeviceSynchronize();
	const auto end = std::chrono::system_clock::now();
	return std::chrono::duration_cast<std::chrono::milliseconds>(end - start).count() / 1000.0;
}

template <class T>
auto get_device_uptr(const std::size_t N){
	struct deleter{
		void operator()(T* const ptr){cudaFree(ptr);};
	};
	T* ptr;
	cudaMalloc((void**)&ptr, sizeof(T) * N);
	return std::unique_ptr<T, deleter>{ptr};
}

int main(){
	{
		auto srt_uptr = get_device_uptr<float>(mem_N);
		auto dst_uptr = get_device_uptr<float>(N);
		const auto elapsed_time = get_elapsed_time(
					[&srt_uptr, &dst_uptr](){
						for(std::size_t c = 0; c < test_count; c++) read_global_128<<<(N / num_threads), num_threads>>>(srt_uptr.get(), dst_uptr.get());
					});
		std::cout<<"    128bit read : "<<elapsed_time<<" [s]"<<std::endl;
	}
	{
		auto srt_uptr = get_device_uptr<float>(mem_N);
		auto dst_uptr = get_device_uptr<float>(N);
		const auto elapsed_time = get_elapsed_time(
					[&srt_uptr, &dst_uptr](){
						for(std::size_t c = 0; c < test_count; c++) read_global<<<(N / num_threads), num_threads>>>(srt_uptr.get(), dst_uptr.get());
					});
		std::cout<<" 32bit x 4 read : "<<elapsed_time<<" [s]"<<std::endl;
	}
}
