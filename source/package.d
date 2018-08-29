module fullyindexabledictionary;

struct FullyIndexableDictionary
{
private:
	alias BT = ulong;
	alias ST = ubyte;
	alias LT = ulong;
	enum s = BT.sizeof * 8; // 64
	enum sb = BT.sizeof; // 8
	enum l = 256;
	enum lb = l / 8; // 32
	ST[] S;
	LT[] L;
	ubyte[] B;
public:
	void init(void[] b)
	{
		import core.bitop : popcnt;
		import std.algorithm : map, sum;

		S = new ST[](b.length / sb + 1);
		L = new LT[](b.length / lb + 1);
		B = cast(ubyte[]) b;

		foreach (i; 0 .. b.length / lb)
		{
			auto tmp = cast(ubyte[]) b[i * lb .. (i + 1) * lb];
			if (i + 1 < L.length)
			{
				L[i + 1] = tmp.map!(popcnt).sum() + L[i];
			}
		}
		foreach (i; 0 .. b.length / sb)
		{
			auto tmp = cast(ubyte[]) b[i * sb .. (i + 1) * sb];
			if (i + 1 < S.length && (i + 1) % (l / s) != 0)
			{
				S[i + 1] = cast(ST)(tmp.map!(popcnt).sum() + ((i % (l / s) != 0) ? S[i] : 0));
			}
		}
	}

	size_t rank1(size_t i)
	{
		assert(i <= B.length * ubyte.sizeof * 8, "Range violation");

		import std.algorithm : min;
		import core.bitop : popcnt;

		auto ib = i / 8;
		ubyte[] tmp = cast(ubyte[]) B[ib - (ib % sb) .. min($, ib - (ib % sb) + sb)];
		tmp ~= new ubyte[](sb - tmp.length);
		BT mask = (1UL << (i % s)) - 1;

		auto a = L[ib / lb];
		auto b = S[ib / sb];
		auto c = popcnt((cast(BT[]) tmp)[0] & mask);

		return a + b + c;
	}

	alias rank = rank1;

	size_t rank0(size_t i)
	{
		return i - rank1(i);
	}

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
}
