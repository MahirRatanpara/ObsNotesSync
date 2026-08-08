-> Exact logic behind:
Integer.MAX_VALUE + 1;            // -2147483648 — wraps SILENTLY
Math.abs(Integer.MIN_VALUE);      // -2147483648 — still negative

-> What if floor mod
Math.floorMod(-7, 2);   //  1  (always non-negative for positive divisor)

