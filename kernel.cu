#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdio.h>

// Monika Dudzinska
// Borys Pala
// Rodrigo Morales


const int cudaBlockSize = 2;
const int arraySize = 6;

const int arraySizeA = 17;

cudaError_t addWithCuda(int* c, int* a, int* b, unsigned int size, unsigned int aSize);
cudaError_t addWithCudaMatrices(int c[][arraySize], int a[][arraySize], int b[][arraySize]);

__global__ void addKernel(int* c, int* a, int* b)
{
    int i = blockDim.x * blockIdx.x + threadIdx.x;
    c[i] = a[i] + b[i];
}

__global__ void addKernelMatrices(int c[][arraySize], const int a[][arraySize], const int b[][arraySize], unsigned int arraySize)
{
    int i = threadIdx.x + blockIdx.x * blockDim.x;
    int y = threadIdx.y + blockIdx.y * blockDim.y;
    if ((i < arraySize) && (y < arraySize))
        c[i][y] = a[i][y] + b[i][y];
}

int main()
{
    int a[arraySizeA] = { 1,2,3,4,5,6, 7 ,8,9,10,11,12,13,14,15,16,17};
    int b[arraySizeA] = { 110,120,130,140,150,160,170, 180,190,200,210,220,230,240,250,260,270 };
    int c[arraySizeA] = { 0 };

    int a_two[arraySize][arraySize] = { 0 };
    int b_two[arraySize][arraySize] = { 0 };
    int c_two[arraySize][arraySize] = { 0 };

  

    for (size_t i = 0; i < arraySize; i++)
    {
        for (size_t y = 0; y < arraySize; y++)
        {
            a_two[i][y] = i + 1;
            b_two[i][y] = (i + 1) * 10;
            c_two[i][y] = 0;
        }
    }

    // Add vectors in parallel.
    cudaError_t cudaStatus = addWithCuda(c, a, b, arraySizeA, cudaBlockSize);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "addWithCuda failed!");
        return 1;
    }
    printf("{");
    for (size_t i = 0; i < arraySizeA; i++)
    {
        printf("%d, ", a[i]);
    }
    printf("} + {");
    for (size_t i = 0; i < arraySizeA; i++)
    {
        printf("%d, ", b[i]);
    }
    printf("} = {");
    for (size_t i = 0; i < arraySizeA; i++)
    {
        printf("%d, ", c[i]);
    }
    printf("}\n");

    // Add vectors in parallel.
    cudaError_t cudaStatus_two = addWithCudaMatrices(c_two, a_two, b_two);
    if (cudaStatus_two != cudaSuccess) {
        fprintf(stderr, "addWithCuda failed!");
        return 1;
    }

    printf("\n");

    for (size_t i = 0; i < arraySize; i++)
    {
        for (size_t y = 0; y < arraySize; y++)
        {
            printf("%d , ", a_two[i][y]);
        }
        printf("\n");
    }

    printf("\n");

    for (size_t i = 0; i < arraySize; i++)
    {
        for (size_t y = 0; y < arraySize; y++)
        {
            printf("%d , ", b_two[i][y]);
        }
        printf("\n");
    }

    printf("\n");

    for (size_t i = 0; i < arraySize; i++)
    {
        for (size_t y = 0; y < arraySize; y++)
        {
            printf("%d , ", c_two[i][y]);
        }
        printf("\n");
    }

    // cudaDeviceReset must be called before exiting in order for profiling and
    // tracing tools such as Nsight and Visual Profiler to show complete traces.
    cudaStatus = cudaDeviceReset();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaDeviceReset failed!");
        return 1;
    }


    return 0;
}

// Function to add 2 1D matrices with CUDA
cudaError_t addWithCuda(int* c, int* a, int* b, unsigned int size, unsigned int bSize)
{

    int* dev_a = 0;
    int* dev_b = 0;
    int* dev_c = 0;
    unsigned int bCount;
    cudaError_t cudaStatus;

    if (size % bSize) {
        bCount = size / bSize + 1;
    }
    else {
        bCount = size / bSize;
    }
    // Choose which GPU to run on, change this on a multi-GPU system.
    cudaStatus = cudaSetDevice(0);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
        goto Error;
    }

    // Allocate GPU buffers for three vectors (two input, one output)    .
    cudaStatus = cudaMalloc((void**)&dev_c, size * sizeof(int));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

    cudaStatus = cudaMalloc((void**)&dev_a, size * sizeof(int));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

    cudaStatus = cudaMalloc((void**)&dev_b, size * sizeof(int));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

    // Copy input vectors from host memory to GPU buffers.
    cudaStatus = cudaMemcpy(dev_a, a, size * sizeof(int), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

    cudaStatus = cudaMemcpy(dev_b, b, size * sizeof(int), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

    // Launch a kernel on the GPU with one thread for each element.
    addKernel <<<bCount, size >>> (dev_c, dev_a, dev_b);

    // Check for any errors launching the kernel
    cudaStatus = cudaGetLastError();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "addKernel launch failed: %s\n", cudaGetErrorString(cudaStatus));
        goto Error;
    }

    // cudaDeviceSynchronize waits for the kernel to finish, and returns
    // any errors encountered during the launch.
    cudaStatus = cudaDeviceSynchronize();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching addKernel!\n", cudaStatus);
        goto Error;
    }

    // Copy output vector from GPU buffer to host memory.
    cudaStatus = cudaMemcpy(c, dev_c, size * sizeof(int), cudaMemcpyDeviceToHost);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

Error:
    cudaFree(dev_c);
    cudaFree(dev_a);
    cudaFree(dev_b);

    return cudaStatus;
}

// Function to add 2D matrices with CUDA
cudaError_t addWithCudaMatrices(int c[][arraySize], int a[][arraySize], int b[][arraySize])
{
    int(*dev_a)[arraySize] = 0;
    int(*dev_b)[arraySize] = 0;
    int(*dev_c)[arraySize] = 0;
    cudaError_t cudaStatus;

    unsigned int bCount;
    if (arraySize % cudaBlockSize) {
        bCount = arraySize / cudaBlockSize + 1;
    }
    else {
        bCount = arraySize / cudaBlockSize;
    }

    dim3 blocks(cudaBlockSize, cudaBlockSize);
    dim3 threads(bCount, bCount);


    // Choose which GPU to run on, change this on a multi-GPU system.
    cudaStatus = cudaSetDevice(0);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
        goto Error;
    }

    // Allocate GPU buffers for three vectors (two input, one output)    .
    cudaStatus = cudaMalloc((void**)&dev_c, arraySize * arraySize * sizeof(int));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

    cudaStatus = cudaMalloc((void**)&dev_a, arraySize * arraySize * sizeof(int));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

    cudaStatus = cudaMalloc((void**)&dev_b, arraySize * arraySize * sizeof(int));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

    // Copy input vectors from host memory to GPU buffers.
    cudaStatus = cudaMemcpy(dev_a, a, arraySize * arraySize * sizeof(int), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

    cudaStatus = cudaMemcpy(dev_b, b, arraySize * arraySize * sizeof(int), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

    // Launch a kernel on the GPU with one thread for each element.
    addKernelMatrices <<<blocks, threads>>> (dev_c, dev_a, dev_b, arraySize);

    // Check for any errors launching the kernel
    cudaStatus = cudaGetLastError();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "addKernel launch failed: %s\n", cudaGetErrorString(cudaStatus));
        goto Error;
    }

    // cudaDeviceSynchronize waits for the kernel to finish, and returns
    // any errors encountered during the launch.
    cudaStatus = cudaDeviceSynchronize();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching addKernel!\n", cudaStatus);
        goto Error;
    }

    // Copy output vector from GPU buffer to host memory.
    cudaStatus = cudaMemcpy(c, dev_c, arraySize * arraySize * sizeof(int), cudaMemcpyDeviceToHost);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

Error:
    cudaFree(dev_c);
    cudaFree(dev_a);
    cudaFree(dev_b);

    return cudaStatus;
}