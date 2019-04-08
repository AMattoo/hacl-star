module Hacl.Spec.P256.Core

open Lib.IntTypes
open FStar.Math.Lemmas
open FStar.Math.Lib
open Hacl.Spec.Curve25519.Field64.Definition
open Hacl.Spec.P256.Definitions
open Hacl.Spec.Curve25519.Field64.Core
open Hacl.Spec.P256.Lemmas
open FStar.Mul


inline_for_extraction noextract
val lt_u64:a:uint64 -> b:uint64 -> Tot bool

let lt_u64 a b =
  let open Lib.RawIntTypes in
  FStar.UInt64.(u64_to_UInt64 a <^ u64_to_UInt64 b)


inline_for_extraction noextract
val gt: a: uint64 -> b: uint64 -> Tot uint64

let gt a b = 
  if lt_u64 b a then u64 1 else u64 0


let eq_u64 a b =
  let open Lib.RawIntTypes in
  FStar.UInt64.(u64_to_UInt64 a =^ u64_to_UInt64 b)

let eq_0_u64 a = 
  let b = u64 0 in 
  eq_u64 a b

val eq_pow64_u64: a: uint64 -> Tot (r: bool {uint_v a == pow2 64 -1 ==> r == true /\ uint_v a <> pow2 64 - 1 ==> r == false})

let eq_pow64_u64 a = 
  let b = u64 (normalize_term(pow2 64 - 1)) in 
  eq_u64 a b 


val cmovznz: cin : uint64{uint_v cin <=1} ->  x: uint64 -> y: uint64   -> 
  Pure uint64
  (requires True)
  (ensures fun r -> if uint_v cin = 0 then uint_v r == uint_v x else uint_v r == uint_v y)

let cmovznz cin  x y  = 
    let x2 = if eq_0_u64 cin then (u64 0)  else (u64 (normalize_term (pow2 64 - 1)))  in 
    let x3 = logor (logand y x2) (logand x (lognot (x2))) in
    let ln = lognot x2 in 
    log_and y x2; 
    log_not_lemma x2;
    log_and x ln;
    log_or (logand y x2) (logand x (lognot (x2)));
    x3

val cmovznz4: cin: uint64{uint_v cin <=1} -> x: felem4 -> y: felem4 -> Pure (r: felem4)
(requires True)
(ensures fun r -> if uint_v cin = 0 then as_nat4 r == as_nat4 x else as_nat4 r == as_nat4 y)

let cmovznz4 cin x y = 
  let x0, x1, x2, x3 = x in 
  let y0, y1, y2, y3 = y in 
  let r0 = cmovznz cin x0 y0 in 
  let r1 = cmovznz cin x1 y1 in 
  let r2 = cmovznz cin x2 y2 in 
  let r3 = cmovznz cin x3 y3 in 
  (r0, r1, r2, r3)

#set-options "--z3rlimit 100"

let felem_add arg1 arg2 = 
  let (x8, c) = add4 arg1 arg2 in 
  let (x1, x3, x5, x7) = c in 
   lemma_nat_4 c;
  let p256 =  (u64 0xffffffffffffffff, u64 0xffffffff, u64 0, u64 0xffffffff00000001) in 
  assert_norm (as_nat4 p256 == prime);
  let (x16, r) = sub4 c p256 in 
  lemma_for_multiplication_1 arg1 arg2;
  let (x9, x11, x13, x15) = r in   
    lemma_nat_4 r; 
  let (x17, x18) = subborrow x8 (u64 0) x16  in 
    prime_lemma (as_nat4 arg1 + as_nat4 arg2);
    small_modulo_lemma_extended (as_nat4 c) prime; 
  let result = cmovznz4 x18 r c in 
  assert(as_nat4 result = (as_nat4 arg1 + as_nat4 arg2) % prime);
  result

#reset-options "--z3rlimit 400"

let felem_sub arg1 arg2 = 
  let (c, r) = sub4 arg1 arg2 in 
    lemma_adding_prime arg1 arg2;
    
  let x9 = cmovznz c (u64 0) (u64 0xffffffffffffffff) in 
  
  let prime_temp_0 = logand (u64 0xffffffffffffffff) x9 in 
  let prime_temp_1 = logand (u64 0xffffffff) x9 in 
  let prime_temp_2 = u64 0 in 
  let prime_temp_3 = logand (u64 0xffffffff00000001) x9 in 
  let prime_temp = (prime_temp_0, prime_temp_1, prime_temp_2, prime_temp_3) in 

  log_and (u64 0xffffffffffffffff) x9;
  log_and (u64 0xffffffff) x9;
  log_and (u64 0xffffffff00000001) x9;

  assert_norm (as_nat4 (u64 0xffffffffffffffff, u64 0xffffffff, u64 0, u64 0xffffffff00000001) == prime);
  
  let (c1, r1) = add4 prime_temp r in 
    lemma_add4_zero prime_temp r;
    lemma_sub_add arg1 arg2 prime_temp r;
  r1

let get_high_part a = 
  to_u32(shift_right a (size 32))

val lemma_small_get_high_part: a: uint64 {uint_v a < pow2 32} -> Lemma (let r = get_high_part a in uint_v r == 0)

let lemma_small_get_high_part a = ()

let get_low_part a = to_u32 a

val store_high_u: src: uint32 -> element: uint64  -> Tot uint64

let store_high_u src element = 
  let as_uint64 = to_u64 src in 
  let src =  Lib.IntTypes.shift_left as_uint64 (size 32) in 
  logxor element src

val store_low_u: src: uint32 -> element: uint64 -> Tot uint64

let store_low_u src element = 
  let as_uint64 = to_u64 src in 
  logxor element as_uint64

val lemma_xor_zero: low: uint64{uint_v (get_high_part low) ==  0} -> high: uint64{uint_v (get_low_part high) == 0} ->  Lemma (uint_v (logxor low high) = uint_v high * pow2 32 + uint_v low)

let lemma_xor_zero low high = 
  assert(uint_v low = uint_v (get_low_part low));
  assert(uint_v high = uint_v (get_high_part high) * pow2 32);
  admit()


let store_high_low_u high low = 
  let as_uint64_high = to_u64 high in 
  let as_uint64_high = Lib.IntTypes.shift_left as_uint64_high (size 32) in 
  let as_uint64_low = to_u64 low in
  lemma_xor_zero as_uint64_low as_uint64_high;
  logxor as_uint64_low as_uint64_high


let reduction_prime_2prime a = 
  let p256 =  (u64 0xffffffffffffffff, u64 0xffffffff, u64 0, u64 0xffffffff00000001) in 
  assert_norm (as_nat4 p256 == prime);
  let (x16, reduced_result) = sub4 a p256 in 
  cmovznz4 x16 reduced_result a

val reduction_prime_2prime_with_carry: carry: uint64{uint_v carry <= 1} -> a: felem4{as_nat4 a + uint_v carry * pow2 256 < 2 * prime} -> Tot (r: felem4 {as_nat4 r == (as_nat4 a + uint_v carry * pow2 256) % prime})

let reduction_prime_2prime_with_carry carry a = 
  lemma_nat_4 a;
  let p256 =  (u64 0xffffffffffffffff, u64 0xffffffff, u64 0, u64 0xffffffff00000001) in 
  assert_norm (as_nat4 p256 == prime);
  let (x16, r) = sub4 a p256 in 
  let (result, c) = subborrow carry (u64 0) x16  in  
    assert(if as_nat4 a < prime then uint_v x16 = 1 else uint_v x16 = 0);
    lemma_nat_4 a;

    assert(if uint_v x16 = 0 then as_nat4 a - prime = as_nat4 r else True);
    assert(as_nat4 a < pow2 256);
    assert_norm (prime < pow2 256);
    assert(as_nat4 a + pow2 256 > prime);
    assert(if uint_v c = 0 then uint_v carry = uint_v x16 else uint_v carry < uint_v x16);
    assert(if uint_v c = 0 then uint_v carry = 0 && uint_v x16 = 0 \/ uint_v carry = 1 && uint_v x16 = 1 else uint_v carry = 0 && uint_v x16 = 1);

  let result = cmovznz4 c r a in 
    assert(if uint_v carry = 1 && uint_v x16 = 1 then as_nat4 result = (as_nat4 a + uint_v carry * pow2 256) % prime else True);
    assert(if uint_v carry = 1 && uint_v x16 = 0 then as_nat4 result = (as_nat4 a + uint_v carry * pow2 256) % prime else True);
  assert(if uint_v carry = 0 && uint_v x16 = 1 then as_nat4 result = (as_nat4 a + uint_v carry * pow2 256) % prime else True);
  result


val shift_carry: x: uint64 -> cin: uint64{uint_v cin <=1} -> Tot (r: uint64 {uint_v r = (uint_v x * 2) % pow2 64 + uint_v cin})

let shift_carry x cin = 
  add (Lib.IntTypes.shift_left x (size 1)) cin


val lemma_get_number: a: nat {a < pow2 64} -> Lemma (
	let mask = 0x7fffffffffffffff in 
	let carry= if a> mask then 1 else 0 in 
	(a * 2) = (a * 2) % pow2 64 + carry * pow2 64)	

let lemma_get_number a = ()

val shift_left_lemma: a0: nat {a0 < pow2 64} -> a1: nat {a1 < pow2 64} -> a2: nat {a2 < pow2 64} -> a3: nat {a3 < pow2 64 /\
a0 + a1 * pow2 64 + a2 * pow2 128 + a3 * pow2 192 < prime} -> Lemma (let input = a0 + a1 * pow2 64 + a2 * pow2 128 + a3 * pow2 192 in 
  let mask = 0x7fffffffffffffff in 
  let carry0 = if a0 > mask then 1 else 0 in 
  let carry1 = if a1 > mask then 1 else 0 in 
  let carry2 = if a2 > mask then 1 else 0 in 
  let carry3 = if a3 > mask then 1 else 0 in 

  let a0_u = (a0 * 2) % pow2 64 + 0 in 
  let a1_u = (a1 * 2) % pow2 64 + carry0 in    
  let a2_u = (a2 * 2) % pow2 64 + carry1 in 
  let a3_u = (a3 * 2) % pow2 64 + carry2 in

  input * 2 = a0_u + a1_u * pow2 64 + a2_u * pow2 128 + a3_u * pow2 192 + carry3 * pow2 256 /\
  a0_u + a1_u * pow2 64 + a2_u * pow2 128 + a3_u * pow2 192 + carry3 * pow2 256 < 2 * prime)


let shift_left_lemma a0 a1 a2 a3 = 
  let input: nat = a0+ a1 * pow2 64 + a2 * pow2 128 + a3 * pow2 192 in 

  let mask = 0x7fffffffffffffff in 
  let carry0 = if a0 > mask then 1 else 0 in 
  let carry1 = if a1 > mask then 1 else 0 in 
  let carry2 = if a2 > mask then 1 else 0 in 
  let carry3 = if a3 > mask then 1 else 0 in 


  let a0_u = (a0 * 2) % pow2 64  in 
   lemma_get_number a0;
  let a1_u = (a1 * 2) % pow2 64 + carry0 in   
    lemma_get_number a1;
  let a2_u = (a2 * 2) % pow2 64 + carry1 in 
    lemma_get_number a2;
  let a3_u = (a3 * 2) % pow2 64 + carry2 in 
    lemma_get_number a3;

  assert_norm (pow2 64 * pow2 64 = pow2 128);
  assert_norm (pow2 64 * pow2 128 = pow2 192);
  assert_norm (pow2 64 * pow2 192 = pow2 256)

#reset-options "--z3rlimit 500"

let shift_left_felem input =  
  let (a0, a1, a2, a3) = input in 
  let mask = u64 0x7fffffffffffffff in   
  let carry0 = gt a0 mask in 
  let carry1 = gt a1 mask in 
  let carry2 = gt a2 mask in 
  let carry3 = gt a3 mask in 

  let a0_updated = shift_carry a0 (u64 0) in 
  let a1_updated = shift_carry a1 carry0 in 
  let a2_updated = shift_carry a2 carry1 in 
  let a3_updated = shift_carry a3 carry2 in 

  assert_norm(pow2 64 * pow2 64 = pow2 128);
  assert_norm(pow2 64 * pow2 64 * pow2 64 = pow2 192);

  shift_left_lemma (uint_v a0) (uint_v a1) (uint_v a2) (uint_v a3); 
  assert(as_nat4 input * 2 = uint_v a0_updated + uint_v a1_updated * pow2 64 + uint_v a2_updated * pow2 128 + uint_v  a3_updated * pow2 192 + uint_v carry3 * pow2 256);
  assert_norm(uint_v a2_updated * pow2 64 * pow2 64 == uint_v a2_updated * pow2 128);
  assert_norm(uint_v a3_updated * pow2 64 * pow2 64 * pow2 64 == uint_v a3_updated * pow2 192);
  reduction_prime_2prime_with_carry carry3 (a0_updated, a1_updated, a2_updated, a3_updated)

let upload_prime () = 
  let p256 = (u64 (0xffffffffffffffff), u64 (0x00000000ffffffff), u64 (0), u64 (0xffffffff00000001)) in
  assert_norm (as_nat4 p256 == prime);
  p256


let shift_256 c = 
    let (c0, c1, c2, c3) = c in 
    assert_norm(pow2 64 * pow2 64 = pow2 128);
    assert_norm(pow2 64 * pow2 64 * pow2 64 = pow2 192);
    assert_norm(pow2 64 * pow2 64 * pow2 64 * pow2 64 = pow2 256);
    assert_norm(pow2 64 * pow2 64 * pow2 64  * pow2 64 * pow2 64= pow2 (5 * 64));
    assert_norm(pow2 64 * pow2 64 * pow2 64  * pow2 64 * pow2 64 * pow2 64 = pow2 (6 * 64));
    assert_norm(pow2 64 * pow2 64 * pow2 64  * pow2 64 * pow2 64* pow2 64 * pow2 64 = pow2 (7 * 64));
    assert_norm(pow2 64 * pow2 64 * pow2 64  * pow2 64 * pow2 64* pow2 64 * pow2 64 * pow2 64 = pow2 (8 * 64));
    let r = (u64(0), u64(0), u64 (0), u64 (0), c0, c1, c2, c3) in 
    r




val lemma_wide: o: felem8 -> Lemma (wide_as_nat4 o =
  (let (o0, o1, o2, o3, o4, o5, o6, o7) = o in 
   v o0 + v o1 * pow2 64 +  v o2 * pow2 (64 * 2) + v o3 * pow2 (3 * 64) + 
   v o4 * pow2 (4 * 64) + v o5 * pow2 (5 * 64) +  v o6 * pow2 (6 * 64) + v o7 * pow2 (7 * 64)))

let lemma_wide o = 
    assert_norm(pow2 64 * pow2 64 = pow2 128);
    assert_norm(pow2 64 * pow2 64 * pow2 64 = pow2 192);
    assert_norm(pow2 64 * pow2 64 * pow2 64 * pow2 64 = pow2 256);
    assert_norm(pow2 64 * pow2 64 * pow2 64  * pow2 64 * pow2 64= pow2 (5 * 64));
    assert_norm(pow2 64 * pow2 64 * pow2 64  * pow2 64 * pow2 64 * pow2 64 = pow2 (6 * 64));
    assert_norm(pow2 64 * pow2 64 * pow2 64  * pow2 64 * pow2 64* pow2 64 * pow2 64 = pow2 (7 * 64));
    ()



val add8: a: felem8 -> b: felem8 -> Pure (uint64 & felem8)
  (requires True) 
  (ensures fun (c, r) -> uint_v c <= 1 /\  wide_as_nat4 a + wide_as_nat4 b = wide_as_nat4 r + uint_v c * pow2 512)


let add8 a b = 
    assert_norm(pow2 64 * pow2 64 = pow2 128);
    assert_norm(pow2 64 * pow2 64 * pow2 64 = pow2 192);
    assert_norm(pow2 64 * pow2 64 * pow2 64 * pow2 64 = pow2 256);
    assert_norm(pow2 64 * pow2 64 * pow2 64  * pow2 64 * pow2 64= pow2 (5 * 64));
    assert_norm(pow2 64 * pow2 64 * pow2 64  * pow2 64 * pow2 64 * pow2 64 = pow2 (6 * 64));
    assert_norm(pow2 64 * pow2 64 * pow2 64  * pow2 64 * pow2 64* pow2 64 * pow2 64 = pow2 (7 * 64));
    assert_norm(pow2 64 * pow2 64 * pow2 64  * pow2 64 * pow2 64* pow2 64 * pow2 64 * pow2 64 = pow2 512);
  let (a0, a1, a2, a3, a4, a5, a6, a7) = a in 
  let (b0, b1, b2, b3, b4, b5, b6, b7) = b in 
  let c3, r = add4 (a0, a1, a2, a3) (b0, b1, b2, b3) in 
  let o4, c4 = addcarry c3 a4 b4 in
  let o5, c5 = addcarry c4 a5 b5 in 
  let o6, c6 = addcarry c5 a6 b6 in 
  let o7, c7 = addcarry c6 a7 b7 in 
  let (o0, o1, o2, o3) = r in 

  assert(wide_as_nat4 a + wide_as_nat4 b = 
   v o0 + v o1 * pow2 64 +  v o2 * pow2 (2 * 64) + v o3 * pow2 (3 * 64) + 
   v o4 * pow2 (4 * 64) + v o5 * pow2 (5 * 64) +  v o6 * pow2 (6 * 64) + v o7 * pow2 (7 * 64) + v c7 * pow2 512);

  let out = o0, o1, o2, o3, o4, o5, o6, o7 in 
  lemma_wide out;
  c7, out

val add9: a: felem8 -> b: felem8 -> Pure (felem9)
  (requires True)
  (ensures fun r -> wide_as_nat4 a + wide_as_nat4 b = as_nat9 r)

let add9 a b = 
    assert_norm(pow2 64 * pow2 64 = pow2 128);
    assert_norm(pow2 64 * pow2 64 * pow2 64 = pow2 192);
    assert_norm(pow2 64 * pow2 64 * pow2 64 * pow2 64 = pow2 256);
    assert_norm(pow2 64 * pow2 64 * pow2 64  * pow2 64 * pow2 64= pow2 (5 * 64));
    assert_norm(pow2 64 * pow2 64 * pow2 64  * pow2 64 * pow2 64 * pow2 64 = pow2 (6 * 64));
    assert_norm(pow2 64 * pow2 64 * pow2 64  * pow2 64 * pow2 64* pow2 64 * pow2 64 = pow2 (7 * 64));
    assert_norm(pow2 64 * pow2 64 * pow2 64  * pow2 64 * pow2 64* pow2 64 * pow2 64 * pow2 64 = pow2 512);
  let (a0, a1, a2, a3, a4, a5, a6, a7) = a in 
  let (b0, b1, b2, b3, b4, b5, b6, b7) = b in 
  let c3, r = add4 (a0, a1, a2, a3) (b0, b1, b2, b3) in 
  let o4, c4 = addcarry c3 a4 b4 in
  let o5, c5 = addcarry c4 a5 b5 in 
  let o6, c6 = addcarry c5 a6 b6 in 
  let o7, c7 = addcarry c6 a7 b7 in 
  let (o0, o1, o2, o3) = r in 

  assert(wide_as_nat4 a + wide_as_nat4 b = 
   v o0 + v o1 * pow2 64 +  v o2 * pow2 (2 * 64) + v o3 * pow2 (3 * 64) + 
   v o4 * pow2 (4 * 64) + v o5 * pow2 (5 * 64) +  v o6 * pow2 (6 * 64) + v o7 * pow2 (7 * 64) + v c7 * pow2 512);

  let out = o0, o1, o2, o3, o4, o5, o6, o7 in 
  lemma_wide out;
  o0, o1, o2, o3, o4, o5, o6, o7,  c7

val add8_without_carry: a: felem8{wide_as_nat4 a < pow2 449} -> b: felem8 {wide_as_nat4 b < pow2 320} -> Tot (r: felem8 {wide_as_nat4 r = wide_as_nat4 a + wide_as_nat4 b})

let add8_without_carry a b = 
  let (carry, r)  = add8 a b in 
  assert_norm(pow2 320 + pow2 449 < pow2 512);   
  assert(uint_v carry = 0);
  r


val shortened_mul: a: felem4 -> b: uint64 -> Tot (r: felem8 {as_nat4 a * uint_v b = wide_as_nat4 r /\ wide_as_nat4 r < pow2 320})

let shortened_mul a b = 
  let (c, f) = mul1 a b in 
  let (f0, f1, f2, f3) = f in 
   assert_norm(pow2 64 * pow2 64 = pow2 128);
   assert_norm(pow2 64 * pow2 64 * pow2 64 = pow2 192);
   assert_norm(pow2 64 * pow2 64 * pow2 64 * pow2 64 = pow2 256);
   assert_norm(pow2 64 * pow2 64 * pow2 64  * pow2 64 * pow2 64= pow2 320);
   assert_norm(pow2 64 * pow2 64 * pow2 64  * pow2 64 * pow2 64 * pow2 64 = pow2 (6 * 64));
   assert_norm(pow2 64 * pow2 64 * pow2 64  * pow2 64 * pow2 64* pow2 64 * pow2 64 = pow2 (7 * 64));
  f0, f1, f2, f3, c, (u64 0), (u64 0), u64(0)  


val mod_64: a: felem8 -> Tot (r: uint64 {wide_as_nat4 a % pow2 64 = uint_v r})

let mod_64 a = 
  let (a0, a1, a2, a3, a4, a5, a6, a7) = a in 
  a0

val shift_9: a: felem9 -> Tot (r: felem8 {as_nat9 a / pow2 64 = wide_as_nat4 r})

let shift_9 a = 
  let (a0, a1, a2, a3, a4, a5, a6, a7, a8) = a in 
  (a1, a2, a3, a4, a5, a6, a7, a8)

val shift_8: a: felem8 -> Tot (r: felem8 {wide_as_nat4 a / pow2 64 = wide_as_nat4 r})

let shift_8 a = 
  let (a0, a1, a2, a3, a4, a5, a6, a7) = a in 
  (a1, a2, a3, a4, a5, a6, a7, (u64 0))

#reset-options "--z3rlimit 1000"  

val lemma_less_than_primes : a: nat {a < prime} -> b: nat {b < prime} -> Lemma (ensures (
  let s = 64 in 
  let t = a * b in 

  let t1 = t % pow2 s in 
  let t2 = t1 * prime in 
  let t3 = t + t2 in 
  let tU = t3 / pow2 s in 
 
  let t = tU in 
  let t1 = t % pow2 s in 
  let t2 = t1 * prime in 
  let t3 = t + t2 in 
  let tU = t3 / pow2 s in 

  let t = tU in 
  let t1 = t % pow2 s in 
  let t2 = t1 * prime in 
  let t3 = t + t2 in 
  let tU = t3 / pow2 s in 

  let t = tU in 
  let t1 = t % pow2 s in  
  let t2 = t1 * prime in 
  let t3 = t + t2 in 
  let tU = t3 / pow2 s in 
  tU < 2 * prime))

let lemma_less_than_primes a b = 
  let s = 64 in 
  let t = a * b in 
  assert(t < prime * prime);

  let t1 = t % pow2 s in 
  let t2 = t1 * prime in 
  let t3 = t + t2 in 
  let tU = t3 / pow2 s in 
 
  let t = tU in 
  let t1 = t % pow2 s in 
  let t2 = t1 * prime in 
  let t3 = t + t2 in 
  let tU = t3 / pow2 s in 

  let t = tU in 
  let t1 = t % pow2 s in 
  let t2 = t1 * prime in 
  let t3 = t + t2 in 
  let tU = t3 / pow2 s in 

  let t = tU in 
  let t1 = t % pow2 s in  
  let t2 = t1 * prime in 
  let t3 = t + t2 in 
  let tU = t3 / pow2 s in 
  assert(tU < 2 * prime)

val montgomery_multiplication_one_round_proof: t: felem8 {wide_as_nat4 t < pow2 449} -> 
  result: felem8 {wide_as_nat4 result = (wide_as_nat4 t + (wide_as_nat4 t % pow2 64) * prime) / pow2 64} ->
  co: nat{ co % prime == wide_as_nat4 t % prime} -> Lemma (
    wide_as_nat4 result % prime == co * modp_inv2 (pow2 64) % prime /\
    wide_as_nat4 result = (wide_as_nat4 t + (wide_as_nat4 t % pow2 64) * prime) / pow2 64 /\
    wide_as_nat4 result < pow2 449)

let montgomery_multiplication_one_round_proof t result co = 
  let primeU = upload_prime () in 
  let t1 = mod_64 t in 
  let t2 = shortened_mul primeU t1 in 
    assert_norm(pow2 256 * pow2 64 = pow2 320);
    assert(wide_as_nat4 t2 = uint_v t1 * prime);
  let t3 = add8_without_carry t t2 in 
    assert_norm (pow2 320 + pow2 449 < pow2 513);
  let result = shift_8 t3 in 
    lemma_div_lt (wide_as_nat4 t3) 513 64;
    mult_one_round (wide_as_nat4 t) co


val montgomery_multiplication_one_round: t: felem8{wide_as_nat4 t < pow2 449} -> 
Tot (result: felem8 { wide_as_nat4 result = (wide_as_nat4 t + (wide_as_nat4 t % pow2 64) * prime) / pow2 64 /\wide_as_nat4 result < pow2 449})

let montgomery_multiplication_one_round t = 
 let primeU = upload_prime () in 
  let t1 = mod_64 t in 
  let t2 = shortened_mul primeU t1 in 
    assert_norm(pow2 256 * pow2 64 = pow2 320);
    assert(wide_as_nat4 t2 = uint_v t1 * prime);
  let t3 = add8_without_carry t t2 in 
    assert_norm (pow2 320 + pow2 449 < pow2 513); 
  let result = shift_8 t3 in 
    lemma_div_lt (wide_as_nat4 t3) 513 64;
  result

#reset-options "--z3refresh" 

let montgomery_multiplication a b = 
  let (a0, a1, a2, a3) = a in 
  let (b0, b1, b2, b3) = b in 

  let primeU = upload_prime () in 
  assert_norm(prime < pow2 256);
  assert_norm (pow2 256 * pow2 256 = pow2 512);
  assert_norm (pow2 320 + pow2 512 < pow2 513);
 
  border_felem4 a;
  border_felem4 b;
  lemma_mult_lt_sqr (as_nat4 a) (as_nat4 b) (pow2 256);
  
  let t = mul4 a b in 
  let t1 = mod_64 t in 
  let t2 = shortened_mul primeU t1 in 
  let t3 = add9 t t2 in 
  let t_state0 = shift_9 t3 in  
    lemma_div_lt (as_nat9 t3) 513 64;
    
    mult_one_round (wide_as_nat4 t) (as_nat4 a * as_nat4 b);
    lemma_mul_nat (as_nat4 a) (as_nat4 b) (modp_inv2 (pow2 64));

  let t_state1 = montgomery_multiplication_one_round t_state0 in
    montgomery_multiplication_one_round_proof t_state0 t_state1 (as_nat4 a * as_nat4 b * modp_inv2 (pow2 64));
    lemma_mul_nat4 (as_nat4 a) (as_nat4 b) (modp_inv2 (pow2 64)) (modp_inv2(pow2 64));
  let t_state2 = montgomery_multiplication_one_round t_state1 in 
    montgomery_multiplication_one_round_proof t_state1 t_state2 (as_nat4 a * as_nat4 b * modp_inv2 (pow2 64) * modp_inv2 (pow2 64));
    lemma_mul_nat5 (as_nat4 a) (as_nat4 b) (modp_inv2 (pow2 64)) (modp_inv2 (pow2 64)) (modp_inv2 (pow2 64));
  let t_state3 = montgomery_multiplication_one_round t_state2 in 
    montgomery_multiplication_one_round_proof t_state2 t_state3 (as_nat4 a * as_nat4 b * modp_inv2 (pow2 64) * modp_inv2 (pow2 64) * modp_inv2(pow2 64));
    lemma_decrease_pow (as_nat4 a * as_nat4 b);
    lemma_less_than_primes (as_nat4 a) (as_nat4 b);
    assert(wide_as_nat4 t_state3 < 2 * prime);
  let (t0, t1, t2, t3, t4, t5, t6, t7) = t_state3 in 
    lemma_prime_as_wild_nat t_state3;
  let r = reduction_prime_2prime_with_carry t4 (t0, t1, t2, t3) in 
  r


let cube_tuple a = 
  let squared = montgomery_multiplication a a in 
  let cube = montgomery_multiplication squared a in 
    lemma_mul_nat (as_nat4 a) (as_nat4 a) (modp_inv2 (pow2 256));
    lemma_mul_nat2   (as_nat4 a) (modp_inv2 (pow2 256));
    lemma_brackets ((as_nat4 a * as_nat4 a * modp_inv2(pow2 256)) % prime) (as_nat4 a) (modp_inv2 (pow2 256));
    lemma_mod_mul_distr_l (as_nat4 a * as_nat4 a * modp_inv2(pow2 256)) (as_nat4 a * modp_inv2 (pow2 256)) prime;
    lemma_brackets5 (as_nat4 a) (as_nat4 a) (modp_inv2 (pow2 256)) (as_nat4 a) (modp_inv2 (pow2 256));
    lemma_distr_mult (as_nat4 a) (as_nat4 a) (modp_inv2 (pow2 256)) (as_nat4 a) (modp_inv2 (pow2 256));
    cube 


let quatre_tuple a = 
  let squared = montgomery_multiplication a a in 
  let power4 = montgomery_multiplication squared squared in 
    lemma_brackets ((as_nat4 a * as_nat4 a * modp_inv2 (pow2 256)) % prime) ((as_nat4 a * as_nat4 a * modp_inv2 (pow2 256)) % prime) (modp_inv2 (pow2 256));
    lemma_mod_mul_distr_l (as_nat4 a * as_nat4 a * modp_inv2 (pow2 256)) (((as_nat4 a * as_nat4 a * modp_inv2 (pow2 256)) % prime) * modp_inv2 (pow2 256)) prime;
    lemma_brackets (as_nat4 a * as_nat4 a * modp_inv2 (pow2 256)) ((as_nat4 a * as_nat4 a * modp_inv2 (pow2 256)) % prime) (modp_inv2 (pow2 256));
    lemma_distr_mult3 (as_nat4 a * as_nat4 a * modp_inv2 (pow2 256)) ((as_nat4 a * as_nat4 a * modp_inv2 (pow2 256)) % prime) (modp_inv2 (pow2 256));
    lemma_brackets_l (as_nat4 a * as_nat4 a * modp_inv2 (pow2 256)) (modp_inv2 (pow2 256)) ((as_nat4 a * as_nat4 a * modp_inv2 (pow2 256)) % prime);
    lemma_mod_mul_distr_r ((as_nat4 a * as_nat4 a * modp_inv2 (pow2 256)) * modp_inv2 (pow2 256)) (as_nat4 a * as_nat4 a * modp_inv2 (pow2 256)) prime;
    lemma_brackets_l (as_nat4 a * as_nat4 a * modp_inv2 (pow2 256))(modp_inv2 (pow2 256)) (as_nat4 a * as_nat4 a * modp_inv2 (pow2 256));
    lemma_distr_mult3 (as_nat4 a * as_nat4 a * modp_inv2 (pow2 256)) (modp_inv2 (pow2 256)) (as_nat4 a * as_nat4 a * modp_inv2 (pow2 256));
    lemma_twice_brackets (as_nat4 a) (as_nat4 a) (modp_inv2 (pow2 256)) (as_nat4 a) (as_nat4 a) (modp_inv2 (pow2 256)) (modp_inv2 (pow2 256));
    lemma_distr_mult7  (as_nat4 a) (as_nat4 a) (modp_inv2 (pow2 256)) (as_nat4 a) (as_nat4 a) (modp_inv2 (pow2 256)) (modp_inv2 (pow2 256));
  power4

val lemma_three: a: nat -> Lemma (a * 2 + a == 3 * a)
let lemma_three a = ()

val lemma_four: a: nat -> Lemma ((a * 2) * 2 == 4 * a)
let lemma_four a = ()

val lemma_eight: a: nat -> Lemma  ((a * 4) * 2 == 8 * a)
let lemma_eight a = ()

val lemma_minus_three: a: nat -> Lemma (0 - 3 * a == (-3) * a)
let lemma_minus_three a = ()


let multByThree_tuple a = 
  let open FStar.Tactics in 
  let open FStar.Tactics.Canon in 
    let multByTwo = shift_left_felem a in 
    let byThree = felem_add multByTwo a in 
    lemma_mod_plus_distr_l (as_nat4 a * 2) (as_nat4 a) prime;
    lemma_three (as_nat4 a);
    byThree


let multByFour_tuple a = 
  let multByTwo = shift_left_felem a in 
  let multByFour = shift_left_felem multByTwo in 
    lemma_mod_mul_distr_l (as_nat4 a * 2) 2 prime;
    lemma_four (as_nat4 a);
  multByFour

let multByEight_tuple a = 
  let multByFour = multByFour_tuple a in 
  let multByEight = shift_left_felem multByFour in 
    lemma_mod_mul_distr_l (as_nat4 a * 4) 2 prime;
    lemma_eight (as_nat4 a);
  multByEight

let multByMinusThree_tuple a = 
  let byThree = multByThree_tuple a in 
  let zero = (u64 (0), u64(0), u64(0), u64(0)) in 
    assert_norm (as_nat4 zero = 0);
  let minusThree = felem_sub zero byThree in 
  lemma_mod_sub_distr 0 (as_nat4 a * 3) prime;
  lemma_minus_three (as_nat4 a);
  minusThree

 
(* takes felem4 and returns boolean *)
(* NB: something mod prime!  *) 
let isOne_tuple a = 
  let (a0, a1, a2, a3) = a in 
  let r0 = eq_mask a0 (u64 1) in 
  let r1 = eq_mask a1 (u64 0) in 
  let r2 = eq_mask a2 (u64 0) in 
  let r3 = eq_mask a3 (u64 0) in  
  let r01 = logand r0 r1 in 
    logand_lemma r0 r1;
  let r23 = logand r2 r3 in 
    lemma_log_and1 r2 r3;
  let r = logand r01 r23 in 
    lemma_log_and1 r01 r23;
  let f = eq_u64 r (u64 0xffffffffffffffff) in  
   f



let equalFelem a b = 
    let (a_0, a_1, a_2, a_3) = a in 
    let (b_0, b_1, b_2, b_3) = b in 
    let r_0 = eq_mask a_0 b_0 in 
      eq_mask_lemma a_0 b_0;
    let r_1 = eq_mask a_1 b_1 in 
      eq_mask_lemma a_1 b_1;
    let r_2 = eq_mask a_2 b_2 in 
      eq_mask_lemma a_2 b_2;
    let r_3 = eq_mask a_3 b_3 in 
      eq_mask_lemma a_3 b_3;
    let r01 = logand r_0 r_1 in 
      logand_lemma r_0 r_1;
    let r23 = logand r_2 r_3 in 
      logand_lemma r_2 r_3;
    let r = logand r01 r23 in 
      logand_lemma r01 r23;
      lemma_equality a b; 
      r


let uploadOne () = 
  let one = (u64 (1), u64(0), u64(0), u64(0)) in 
  assert_norm (as_nat4 one == 1);
  one

let uploadZero () = 
  let zero = (u64 (0), u64 (0), u64(0), u64(0)) in 
  assert_norm (as_nat4 zero == 0);
  zero

let isZero_tuple_u a = 
  let (a0, a1, a2, a3) = a in 
  let r0 = eq_mask a0 (u64 0) in 
  let r1 = eq_mask a1 (u64 0) in 
  let r2 = eq_mask a2 (u64 0) in 
  let r3 = eq_mask a3 (u64 0) in 
  let r01 = logand r0 r1 in 
     lemma_log_and1 r0 r1;
  let r23 = logand r2 r3 in 
     lemma_log_and1 r2 r3;
  let r = logand r01 r23 in 
   lemma_log_and1 r01 r23;
      r
  

let isZero_tuple_b a = 
  assert_norm (0xffffffffffffffff = pow2 64 - 1);
  let (a0, a1, a2, a3) = a in 
  let r0 = eq_mask a0 (u64 0) in 
  let r1 = eq_mask a1 (u64 0) in 
  let r2 = eq_mask a2 (u64 0) in 
  let r3 = eq_mask a3 (u64 0) in 
  let r01 = logand r0 r1 in 
    lemma_log_and1 r0 r1;
  let r23 = logand r2 r3 in 
    lemma_log_and1 r2 r3;
  let r = logand r01 r23 in 
    lemma_log_and1 r01 r23;    
  let f = eq_u64 r (u64 0xffffffffffffffff) in  
   f
   