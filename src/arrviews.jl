### View types

# use ContiguousView when contiguousness can be determined statically
immutable ContiguousView{T,N,Arr<:Array} <: ArrayView{T,N,N}
    arr::Arr
    offset::Int
    len::Int
    shp::NTuple{N,Int}
    mutable::Bool
end

ContiguousView{T,N}(arr::Array{T}, offset::Int, shp::NTuple{N,Int}; mutable::Bool=true) =
    ContiguousView{T,N,typeof(arr)}(arr, offset, prod(shp), shp, mutable)

ContiguousView(arr::Array, shp::Dims; mutable::Bool=true) = ContiguousView(arr, 0, shp; mutable=mutable)


immutable UnsafeContiguousView{T,N} <: UnsafeArrayView{T,N,N}
    ptr::Ptr{T}
    len::Int
    shp::NTuple{N,Int}
    mutable::Bool
end

UnsafeContiguousView{T,N}(ptr::Ptr{T}, shp::NTuple{N,Int}; mutable::Bool=true) =
    UnsafeContiguousView{T,N}(ptr, prod(shp), shp, mutable)

UnsafeContiguousView{T,N}(ptr::Ptr{T}, offset::Int, shp::NTuple{N,Int}; mutable::Bool=true) =
    UnsafeContiguousView(ptr+offset*sizeof(T), shp; mutable=mutable)

UnsafeContiguousView(arr::Array, shp::Dims; mutable::Bool=true) = UnsafeContiguousView(pointer(arr), shp; mutable=mutable)

UnsafeContiguousView{T,N}(arr::Array{T}, offset::Int, shp::NTuple{N,Int}; mutable::Bool=true) =
    UnsafeContiguousView(pointer(arr, offset+1), shp; mutable=mutable)



# use StridedView when contiguousness can not be determined statically
# condition: M < N
immutable StridedView{T,N,M,Arr<:Array} <: ArrayView{T,N,M}
    arr::Arr
    offset::Int
    len::Int
    shp::NTuple{N,Int}
    strides::NTuple{N,Int}
    mutable::Bool
end

function StridedView{T,N,M}(arr::Array{T}, offset::Int, shp::NTuple{N,Int},
                             ::Type{ContRank{M}}, strides::NTuple{N,Int}; mutable::Bool=true)
    @assert M < N
    StridedView{T,N,M,typeof(arr)}(arr, offset, prod(shp), shp, strides, mutable)
end

function StridedView{T,N,M}(arr::Array{T}, shp::NTuple{N,Int},
                             ::Type{ContRank{M}}, strides::NTuple{N,Int}; mutable::Bool=true)
    @assert M < N
    StridedView{T,N,M,typeof(arr)}(arr, 0, prod(shp), shp, strides; mutable=mutable)
end

immutable UnsafeStridedView{T,N,M} <: UnsafeArrayView{T,N,M}
    ptr::Ptr{T}
    len::Int
    shp::NTuple{N,Int}
    strides::NTuple{N,Int}
    mutable::Bool
end

function UnsafeStridedView{T,N,M}(ptr::Ptr{T}, shp::NTuple{N,Int},
                                  ::Type{ContRank{M}}, strides::NTuple{N,Int}; mutable::Bool=true)
    @assert M < N
    UnsafeStridedView{T,N,M}(ptr, prod(shp), shp, strides, mutable)
end

function UnsafeStridedView{T,N,M}(ptr::Ptr{T}, offset::Int, shp::NTuple{N,Int},
                                  ::Type{ContRank{M}}, strides::NTuple{N,Int}; mutable::Bool=true)
    @assert M < N
    UnsafeStridedView(ptr+offset*sizeof(T), shp, ContRank{M}, strides; mutable=mutable)
end

function UnsafeStridedView{T,N,M}(arr::Array{T}, offset::Int, shp::NTuple{N,Int},
                                  ::Type{ContRank{M}}, strides::NTuple{N,Int}; mutable::Bool=true)
    @assert M < N
    UnsafeStridedView(pointer(arr, offset+1), shp, ContRank{M}, strides; mutable=mutable)
end

function UnsafeStridedView{T,N,M}(arr::Array{T}, shp::NTuple{N,Int},
                                  ::Type{ContRank{M}}, strides::NTuple{N,Int}; mutable=true)
    @assert M < N
    UnsafeStridedView(pointer(arr), shp, ContRank{M}, strides; mutable=mutable)
end



### basic methods

parent(a::ArrayView) = a.arr
parent(a::UnsafeArrayView) = error("Getting parent of an unsafe view is not allowed.")
parent_or_ptr(a) = parent(a)
parent_or_ptr(a::UnsafeArrayView) = a.ptr

uget(a::ArrayView, i::Int) = getindex(a.arr, a.offset + i)
function uset!{T}(a::ArrayView{T}, v::T, i::Int)
    if a.mutable
        setindex!(a.arr, v, a.offset + i)
    else
        error("Setting elements of an immutable ArrayView is not allowed.")
    end
end

uget(a::UnsafeArrayView, i::Int) = unsafe_load(a.ptr, i)
function uset!{T}(a::UnsafeArrayView{T}, v::T, i::Int)
    if a.mutable
        unsafe_store!(a.ptr, v, i)
    else
        error("Setting elements of an immutable ArrayView is not allowed.")
    end
end

offset(a::ArrayView) = a.offset
pointer(a::ArrayView) = pointer(parent(a), a.offset+1)
pointer(a::UnsafeArrayView) = a.ptr
