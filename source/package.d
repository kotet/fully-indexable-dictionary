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
		assert(i <= B.length * BT.sizeof * 8, "Range violation");

		import std.algorithm : min;
		import core.bitop : popcnt;

		auto ib = i / 8;
		ubyte[] tmp = cast(ubyte[]) B[min(ib - (ib % sb), $ - 1) .. min($, ib - (ib % sb) + sb)];
		tmp ~= new ubyte[](sb - tmp.length);
		BT mask = (1UL << (i % s)) - 1;

		auto a = L[ib / lb];
		auto b = S[min(ib / sb, $ - 1)];
		auto c = popcnt((cast(BT[]) tmp)[0] & mask);

		return a + b + c;
	}

	alias rank = rank1;

	size_t rank0(size_t i)
	{
		return i - rank1(i);
	}

	size_t select1(size_t i)
	{
		long l = -1;
		size_t r = B.length * BT.sizeof * 8;

		while (1 < r - l)
		{
			size_t m = l + (r - l) / 2;
			if (this.rank1(m) < i)
			{
				l = m;
			}
			else
			{
				r = m;
			}
		}
		return r;
	}

	alias select = select1;

	size_t select0(size_t i)
	{
		long l = -1;
		size_t r = B.length * BT.sizeof * 8;

		while (1 < r - l)
		{
			size_t m = l + (r - l) / 2;
			if (this.rank0(m) < i)
			{
				l = m;
			}
			else
			{
				r = m;
			}
		}
		return r;
	}

}
