```
@FunctionalInterface
interface Merger {
    int merge(int a, int b);
}

class SegTree {
    int[] seg = new int[400000];
    int[] nums;
    int n;
    int netural;
    Merger merger;

    public SegTree(int[] nums, Merger merger, int netural) {
        seg = new int[400000];
        this.nums = nums;
        this.n = nums.length;
        this.merger = merger;
        this.netural = netural;
        build(0, 0, n - 1);
    }

    public int fun(int a, int b) {
        return merger.merge(a, b);
    }

    public void build(int i, int l, int r) {
        if (l == r) {
            seg[i] = nums[l];
            return;
        }
        int m = l + (r - l) / 2;
        build(2 * i + 1, l, m);
        build(2 * i + 2, m + 1, r);

        seg[i] = fun(seg[2 * i + 1], seg[2 * i + 2]);
    }

    public int query(int i, int l, int r, int ql, int qr) {
        //range query is completly inside
        if (ql <= l && r <= qr)
            return seg[i];
        //no overlap
        if (ql > r || qr < l)
            return netural;

        int m = l + (r - l) / 2;
        int left = query(2 * i + 1, l, m, ql, qr);
        int right = query(2 * i + 2, m + 1, r, ql, qr);

        return fun(left, right);
    }

    public void update(int i, int l, int r, int index, int val) {
        if (l == r && l == index) {
            seg[i] = val;
            return;
        }

        if (l == r)
            return;

        int m = l + (r - l) / 2;
        if (m >= index) {
            update(2 * i + 1, l, m, index, val);
        } else {
            update(2 * i + 2, m + 1, r, index, val);
        }

        seg[i] = fun(seg[2 * i + 1], seg[2 * i + 2]);
    }
}

class NumArray {
    SegTree seg;
    int n;

    public NumArray(int[] nums) {
        seg = new SegTree(
            nums,
            (a, b) -> a + b,
            0
        );
        n = nums.length;
    }

    public void update(int index, int val) {
        seg.update(0, 0, n - 1, index, val);
    }

    public int sumRange(int left, int right) {
        return seg.query(0, 0, n - 1, left, right);
    }
}

/**
 * Your NumArray object will be instantiated and called as such:
 * NumArray obj = new NumArray(nums);
 * obj.update(index,val);
 * int param_2 = obj.sumRange(left,right);
 */
```