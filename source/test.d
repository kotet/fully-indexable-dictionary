module test;

import fullyindexabledictionary;
import std.stdio;

unittest
{
    ulong[] test = [0b1_0100_0111_0101];

    FullyIndexableDictionary fib;
    fib.init(test);

    assert(fib.rank(0) == 0);
    assert(fib.rank(2) == 1);
    assert(fib.rank(13) == 7);

    assert(fib.rank0(0) == 0);
    assert(fib.rank0(2) == 1);
    assert(fib.rank0(13) == 6);
}

unittest
{
    import std.algorithm : map;
    import std.random : uniform;
    import std.range : iota, array;
    import std.bitmanip : BitArray;
    import std.datetime.stopwatch : benchmark;

    auto N = 10 ^^ 6;
    ulong[] test = iota(N).map!(x => cast(ulong) uniform(0, ulong.max)).array;

    FullyIndexableDictionary fib;
    fib.init(test);
    auto reference = (ulong[] b, size_t i) => BitArray(b.dup, i).count();

    foreach (_; 0 .. 1000)
    {
        auto i = uniform(0, N * ulong.sizeof * 8 + 1);
        assert(fib.rank(i) == reference(test, i));
    }
}

unittest
{
    ulong[] test = [0b10000101 | (1UL << 63)];

    FullyIndexableDictionary fib;
    fib.init(test);

    assert(fib.select(0) == 0);
    assert(fib.select(1) == 1);
    assert(fib.select(2) == 3);
    assert(fib.select(3) == 8);
    assert(fib.select(4) == 64);

    assert(fib.select0(0) == 0);
    assert(fib.select0(1) == 2);
    assert(fib.select0(2) == 4);
}
