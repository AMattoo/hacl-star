module Spec.RSA.Lemmas

open FStar.Mul
open FStar.Math.Lemmas
open Spec.Lib.IntTypes

type elem (n:nat) = e:nat{e < n}

(* LEMMAS *)
#reset-options "--z3rlimit 30 --max_fuel 2"
val pow : x:nat -> n:nat -> Tot nat
let rec pow x n =
  match n with
  | 0 -> 1
  | n -> x * pow x (n - 1)

val lemma_pow: x:nat -> n:nat -> m:nat -> Lemma
  (pow x n * pow x m = pow x (n + m))
let rec lemma_pow x n m =
  let ass (x y z : nat) : Lemma ((x*y)*z == x*(y*z)) = () in
  match n with
  | 0 -> ()
  | _ -> lemma_pow x (n-1) m; ass x (pow x (n-1)) (pow x m)

val lemma_pow_greater_0: a:nat{a > 0} -> b:nat -> Lemma
  (pow a b > 0)
  [SMTPat (pow a b)]
let rec lemma_pow_greater_0 a b =
  match b with
  | 0 -> ()
  | _ -> lemma_pow_greater_0 a (b - 1)

val lemma_pow_0: b:nat{b > 0} -> Lemma (pow 0 b = 0)
let rec lemma_pow_0 b =
  match b with
  | 1 -> ()
  | _ -> lemma_pow_0 (b - 1)

val lemma_pow_1: b:nat -> Lemma (pow 1 b = 1)
let rec lemma_pow_1 b =
  match b with
  |  0 -> ()
  | _ -> lemma_pow_1 (b - 1)

#reset-options "--z3rlimit 30 --max_fuel 0"

val lemma_pow_pow:
  a:nat -> b:nat -> c:nat -> Lemma
  (pow a (b * c) = pow (pow a b) c)
let lemma_pow_pow a b c = admit()

val lemma_pow_mul:
  a:nat -> b:nat -> c:nat -> Lemma
  (pow (a * b) c = (pow a c) * (pow b c))
let lemma_pow_mul a b c = admit()

val lemma_pow_div:
  a:nat -> b:nat -> d:nat{d > 0} -> Lemma
  (pow (a / d) b = (pow a b) / pow d b)
let lemma_pow_div a b d = admit()

val lemma_pow_a2_b:
  a:nat -> b:nat -> Lemma
  (pow (a * a) b = pow a (2 * b))
let lemma_pow_a2_b a b =
  lemma_pow_mul a a b;
  lemma_pow a b b

val lemma_pow_mod:
  a:nat -> b:nat -> n:pos -> Lemma
  ((pow a b) % n == (pow (a % n) b) % n)
let lemma_pow_mod a b n = admit()

val lemma_mod_mult_div_1:
  a:nat -> d:nat{d > 0} -> n:nat{n > 0} -> Lemma
  ((a / d) % n == ((a % n) / d) % n)
let lemma_mod_mult_div_1 a d n = admit()

val lemma_mod_mult_div:
  a:nat -> b:nat -> d:nat{d > 0} -> n:nat{n > 0} -> Lemma
  ((a * b / d) % n == ((a % n) * b / d) % n)
let lemma_mod_mult_div a b d n =
  lemma_mod_mult_div_1 (a * b) d n;
  lemma_mod_mul_distr_l a b n;
  lemma_mod_mult_div_1 ((a % n) * b) d n

// (1 / d) % n is an inverse element of d
val lemma_mult_div_mod:
  a:nat -> b:nat -> d:nat{d > 0} -> n:nat{n > 0} -> Lemma
  ((a * (b / d)) % n == (a * b / d) % n)
let lemma_mult_div_mod a b d n = admit()

(* LEMMAS for Montgomery's arithmetic *)
val lemma_beta_mul_by_beta_i: i:size_nat{i + 1 < max_size_t} -> Lemma
  (pow2 64 * pow2 (64 * i) == pow2 (64 * (i + 1)))
let lemma_beta_mul_by_beta_i i =
  pow2_plus 64 (64 * i)

val lemma_mul_le: a:nat -> b:nat{b > 0} -> c:nat{c > 0} -> Lemma
  (requires (a <= b))
  (ensures (a * c <= b * c))
let lemma_mul_le a b c = ()

val lemma_div_exact_le:
  a:nat -> b:nat -> c:nat{c > 0} -> Lemma
  (requires (a < b * c))
  (ensures (a / c < b))
let lemma_div_exact_le a b c = ()

val lemma_mod_div_simplify:
  res:nat -> a:nat -> r:nat{r > 0} -> n:nat{n > 0} -> Lemma
  (requires (res % n == (a * ((r * r) % n) / r) % n))
  (ensures (res % n == (a * r) % n))
  #reset-options "--z3rlimit 50 --max_fuel 0"
let lemma_mod_div_simplify res a r n =
  assert (res % n == (a * ((r * r) % n) / r) % n);
  lemma_mod_mult_div (r * r) a r n;
  assert (res % n == (a * (r * r) / r) % n);
  paren_mul_right a r r;
  paren_mul_left a r r;
  multiple_division_lemma (a * r) r

(* LEMMAS for modular exponentiation *)

val lemma_mult_abc:
  a:nat -> b:nat -> c:nat -> Lemma
  (a * b * c == a * c * b)
let lemma_mult_abc a b c = ()

val lemma_r_n:
  modBits:nat{modBits > 0} -> r:nat{r > 0} -> n:nat{n > 0} -> Lemma
  (requires (r == pow2 (64 * ((modBits - 1) / 64 + 2)) /\ n < pow2 modBits))
  (ensures (4 * n < r))
let lemma_r_n modBits r n =
  assert (4 * n < 4 * pow2 modBits);
  assert_norm (pow2 2 = 4);
  pow2_plus 2 modBits;
  assert (4 * n < pow2 (modBits + 2));
  euclidean_division_definition (modBits - 1) 64;
  assert (64 * ((modBits - 1) / 64) = modBits - 1 - (modBits - 1) % 64);
  let exp2_r = 64 * ((modBits - 1) / 64 + 2) in
  assert (exp2_r = 64 * ((modBits - 1) / 64) + 128);
  assert (modBits + 63 < exp2_r);
  pow2_lt_compat (modBits + 63) (modBits + 2);
  pow2_lt_compat exp2_r (modBits + 63);
  assert (4 * n < r)

val lemma_mod_exp:
  n:nat{n > 1} -> a:nat -> a2:nat ->
  b:nat -> b2:nat -> acc:nat -> r:nat{r > 0} -> res:nat -> Lemma
  (requires (a2 % n == (a * a / r) % n /\ b2 == b / 2 /\
             res % n == ((pow a2 b2) * acc / pow r b2) % n))
  (ensures (res % n == ((pow a (2 * b2)) * acc / pow r (2 * b2)) % n))
let lemma_mod_exp n a a2 b b2 acc r res =
  lemma_mod_mult_div (pow a2 b2) acc (pow r b2) n;
  lemma_pow_mod a2 b2 n;
  lemma_pow_mod (a * a / r) b2 n;
  lemma_pow_div (a * a) b2 r;
  lemma_pow_a2_b a b2;
  lemma_mod_mult_div (pow a (2 * b2) / pow r b2) acc (pow r b2) n;
  lemma_mod_mult_div_1 ((pow a (2 * b2) / pow r b2) * acc) (pow r b2) n;
  lemma_mult_div_mod acc (pow a (2 * b2)) (pow r b2) n;
  lemma_mod_mult_div_1 ((acc * pow a (2 * b2)) / pow r b2) (pow r b2) n;
  division_multiplication_lemma (acc * pow a (2 * b2)) (pow r b2) (pow r b2);
  lemma_pow r b2 b2

val lemma_mod_exp_1:
  n:nat{n > 1} -> a:nat -> a2:nat ->
  b:nat -> b2:nat -> acc:nat -> acc':nat -> r:nat{r > 0} -> res:nat -> Lemma
  (requires (a2 % n == (a * a / r) % n /\ b2 == b / 2 /\
             res % n == ((pow a2 b2) * acc' / pow r b2) % n /\
             acc' % n == (a * acc / r) % n))
  (ensures (res % n == ((pow a (2 * b2 + 1)) * acc / pow r (2 * b2 + 1)) % n))
let lemma_mod_exp_1 n a a2 b b2 acc acc' r res =
  assert (res % n == ((pow a2 b2) * acc' / pow r b2) % n);
  lemma_mod_exp n a a2 b b2 acc' r res;
  lemma_mod_mult_div acc' (pow a (2 * b2)) (pow r (2 * b2)) n;
  lemma_mod_mult_div (a * acc / r) (pow a (2 * b2)) (pow r (2 * b2)) n;
  lemma_mod_mult_div_1 ((pow a (2 * b2)) * (a * acc / r)) (pow r (2 * b2)) n;
  lemma_mult_div_mod (pow a (2 * b2)) (a * acc) r n;
  lemma_mod_mult_div_1 ((pow a (2 * b2)) * (a * acc) / r) ( pow r (2 * b2)) n;
  division_multiplication_lemma ((pow a (2 * b2)) * (a * acc)) r (pow r (2 * b2));
  paren_mul_right (pow a (2 * b2)) a acc;
  paren_mul_left (pow a (2 * b2)) a acc;
  assert_norm (pow a 1 = a);
  lemma_pow a 1 (2 * b2);
  assert_norm (pow r 1 = r);
  lemma_pow r 1 (2 * b2)

val lemma_mod_exp_2:
  n:nat{n > 1} -> a:nat -> a_r:nat ->
  b:nat -> acc_r:nat -> r:nat{r > 0} -> res_r:nat -> Lemma
  (requires (a_r % n == (a * r) % n /\ acc_r % n == r % n /\
             res_r % n == ((pow a_r b) * acc_r / pow r b) % n))
  (ensures (res_r % n == ((pow a b) * r) % n))
  #reset-options "--z3rlimit 50 --max_fuel 2"
let lemma_mod_exp_2 n a a_r b acc_r r res_r =
  assert (res_r % n == ((pow a_r b) * acc_r / pow r b) % n);
  lemma_mod_mult_div (pow a_r b) acc_r (pow r b) n;
  lemma_pow_mod a_r b n;
  lemma_pow_mod (a * r) b n;
  assert ((pow a_r b) % n == (pow (a * r) b) % n);
  lemma_pow_mul a r b;
  assert (res_r % n == (((pow a b * pow r b) % n) * acc_r / pow r b) % n);
  lemma_mod_mult_div (pow a b * pow r b) acc_r (pow r b) n;
  assert (res_r % n == (pow a b * (pow r b) * acc_r / pow r b) % n);
  lemma_mult_abc (pow a b) (pow r b) acc_r;
  multiple_division_lemma ((pow a b) * acc_r) (pow r b);
  lemma_mod_mul_distr_l acc_r (pow a b) n;
  lemma_mod_mul_distr_l r (pow a b) n

(* LEMMAS for exponent blinding *)
val lemma_mod_pq:
  a:nat -> b:nat -> p:nat{p > 1} -> q:nat{q > 1} -> Lemma
  (requires (a % p == b % p /\ a % q == b % q))
  (ensures (a % (p * q) == b % (p * q)))
let lemma_mod_pq a b p q = admit()

// m ^ (p - 1) = 1 (mod p) where gcd(m, p) = 1 and p is a prime number
val fermat_little_theorem:
  p:nat{p > 1} -> m:nat{m > 0} -> Lemma
  (requires (m % p <> 0))
  (ensures ((pow m (p - 1)) % p == 1))
let fermat_little_theorem p m = admit()

val lemma_exp_blinding_q:
  n:nat{n > 1} -> phi_n:nat -> p:elem n{p > 1} ->
  q:elem n{q > 1} -> m:elem n{m > 0} -> Lemma
  (requires (phi_n == (p - 1) * (q - 1) /\ n = p * q /\ m % q <> 0))
  (ensures ((pow m phi_n) % q == 1))
  #reset-options "--z3rlimit 50 --max_fuel 2"
let lemma_exp_blinding_q n phi_n p q m =
  let res = (pow m phi_n) % q in
  lemma_pow_pow m (q - 1) (p - 1);
  lemma_pow_mod (pow m (q - 1)) (p - 1) q;
  fermat_little_theorem q m;
  lemma_pow_1 (p - 1)

val lemma_exp_blinding_pq:
  n:nat{n > 1} -> phi_n:nat -> p:elem n{p > 1} ->
  q:elem n{q > 1} -> m:elem n{m > 0} -> Lemma
  (requires (phi_n == (p - 1) * (q - 1) /\ n = p * q /\ m % p <> 0 /\ m % q <> 0))
  (ensures ((pow m phi_n) % (p * q) == 1))
  #reset-options "--z3rlimit 50 --max_fuel 0"
let lemma_exp_blinding_pq n phi_n p q m =
  lemma_exp_blinding_q n phi_n p q m;
  small_modulo_lemma_1 1 q;
  lemma_exp_blinding_q n phi_n q p m;
  small_modulo_lemma_1 1 p;
  lemma_mod_pq (pow m phi_n) 1 p q;
  small_modulo_lemma_1 1 n

val lemma_exp_blinding_1:
  n:nat{n > 1} -> phi_n:nat -> p:elem n{p > 1} -> q:elem n{q > 1} ->
  d:elem n{d > 0} -> m:elem n{m > 0} -> r:nat -> Lemma
  (requires (phi_n = (p - 1) * (q - 1) /\ n = p * q /\ m % p <> 0 /\ m % q <> 0))
  (ensures ((pow m (d + r * phi_n)) % n  == (pow m d) % n))
let lemma_exp_blinding_1 n phi_n p q d m r =
  lemma_exp_blinding_pq n phi_n p q m;
  assert ((pow m phi_n) % (p * q) == 1);
  let res:nat = (pow m (d + r * phi_n)) % n in
  lemma_pow m d (r * phi_n);
  lemma_pow_pow m phi_n r;
  lemma_pow_mod (pow m phi_n) r n;
  assert ((pow (pow m phi_n) r) % n == (pow ((pow m phi_n) % n) r) % n);
  assert ((pow (pow m phi_n) r) % n == (pow 1 r) % n);
  lemma_pow_1 r;
  modulo_lemma 1 n;
  lemma_mod_mul_distr_l (pow m (r * phi_n)) (pow m d) n

val lemma_exp_blinding_0_q0:
  n:nat{n > 1} -> phi_n:nat -> p:elem n{p > 1} -> q:elem n{q > 1} ->
  d:elem n{d > 0} -> m:elem n{m > 0} -> r:nat -> Lemma
  (requires (phi_n = (p - 1) * (q - 1) /\ n = p * q /\ m % q = 0))
  (ensures ((pow m (d + r * phi_n)) % q == (pow m d) % q))
let lemma_exp_blinding_0_q0 n phi_n p q d m r =
  let res:nat = pow m (d + r * phi_n) in
  assert (res % q == (pow m (d + r * phi_n)) % q);
  lemma_pow_mod m (d + r * phi_n) q;
  lemma_pow_0 (d + r * phi_n);
  lemma_pow_mod m d q;
  lemma_pow_0 d

val lemma_exp_blinding_0_q1:
  n:nat{n > 1} -> phi_n:nat -> p:elem n{p > 1} -> q:elem n{q > 1} ->
  d:elem n{d > 0} -> m:elem n{m > 0} -> r:nat -> Lemma
  (requires (phi_n = (p - 1) * (q - 1) /\ n = p * q /\ m % p <> 0))
  (ensures ((pow m (d + r * phi_n)) % p == (pow m d) % p))
let lemma_exp_blinding_0_q1 n phi_n p q d m r =
  lemma_exp_blinding_q n phi_n q p m;
  assert ((pow m phi_n) % p == 1);
  let res:nat = pow m (d + r * phi_n) in
  assert (res % p == (pow m (d + r * phi_n)) % p);
  lemma_pow m d (r * phi_n);
  assert (res % p == ((pow m d) * (pow m (r * phi_n))) % p);
  lemma_mod_mul_distr_l (pow m (r * phi_n)) (pow m d) p;
  lemma_pow_pow m phi_n r;
  lemma_pow_mod (pow m phi_n) r p;
  assert ((pow m (r * phi_n)) % p == (pow ((pow m phi_n) % p) r) % p);
  assert ((pow (pow m phi_n) r) % p == (pow 1 r) % p);
  lemma_pow_1 r;
  modulo_lemma 1 p;
  assert (res % p == ((pow m d) * 1) % p)

val lemma_exp_blinding_0_q:
  n:nat{n > 1} -> phi_n:nat -> p:elem n{p > 1} -> q:elem n{q > 1} ->
  d:elem n{d > 0} -> m:elem n{m > 0} -> r:nat -> Lemma
  (requires (phi_n = (p - 1) * (q - 1) /\ n = p * q /\ m % q = 0 /\ m % p <> 0))
  (ensures ((pow m (d + r * phi_n)) % n == (pow m d) % n))
let lemma_exp_blinding_0_q n phi_n p q d m r =
  let res:nat = pow m (d + r * phi_n) in
  lemma_exp_blinding_0_q0 n phi_n p q d m r;
  lemma_exp_blinding_0_q1 n phi_n p q d m r;
  lemma_mod_pq res (pow m d) p q;
  assert (res % n == (pow m d) % n)

val lemma_exp_blinding_0_pq:
  n:nat{n > 1} -> phi_n:nat -> p:elem n{p > 1} -> q:elem n{q > 1} ->
  d:elem n{d > 0} -> m:elem n -> r:nat -> Lemma
  (requires (phi_n = (p - 1) * (q - 1) /\ n = p * q /\ m % q = 0 /\ m % p = 0))
  (ensures ((pow m (d + r * phi_n)) % n == (pow m d) % n))
let lemma_exp_blinding_0_pq n phi_n p q d m r =
  small_modulo_lemma_1 0 p;
  small_modulo_lemma_1 0 q;
  lemma_mod_pq m 0 p q;
  small_modulo_lemma_1 0 n;
  assert (m % n == 0);
  small_modulo_lemma_1 m n;
  assert (m = 0);
  lemma_pow_0 (d + r * phi_n);
  lemma_pow_0 d

val lemma_exp_blinding_0:
  n:nat{n > 1} -> phi_n:nat -> p:elem n{p > 1} -> q:elem n{q > 1} ->
  d:elem n{d > 0} -> m:elem n -> r:nat -> Lemma
  (requires (phi_n = (p - 1) * (q - 1) /\ n = p * q /\
            (m = 0 \/ m % p = 0 \/ m % q = 0)))
  (ensures ((pow m (d + r * phi_n)) % n  == (pow m d) % n))
let lemma_exp_blinding_0 n phi_n p q d m r =
  if (m = 0) then begin
    lemma_pow_0 (d + r * phi_n);
    lemma_pow_0 d end
  else begin
    if (m % p = 0 && m % q <> 0) then
      lemma_exp_blinding_0_q n phi_n q p d m r
    else begin
      if (m % q = 0 && m % p <> 0) then
	lemma_exp_blinding_0_q n phi_n p q d m r
      else begin
	assert (m % p = 0 && m % q = 0);
	lemma_exp_blinding_0_pq n phi_n p q d m r end
    end
  end

val lemma_exp_blinding:
  n:nat{n > 1} -> phi_n:nat -> p:elem n{p > 1} -> q:elem n{q > 1} ->
  d:elem n{d > 0} -> m:elem n -> r:nat -> Lemma
  (requires (phi_n = (p - 1) * (q - 1) /\ n = p * q))
  (ensures ((pow m (d + r * phi_n)) % n  == (pow m d) % n))
let lemma_exp_blinding n phi_n p q d m r =
  if (m = 0 || m % p = 0 || m % q = 0) then
    lemma_exp_blinding_0 n phi_n p q d m r
  else lemma_exp_blinding_1 n phi_n p q d m r

(* LEMMAS for Karatsuba's multiplication *)
val abs: x:int -> Tot (y:nat{(x >= 0 ==> y = x) /\ (x < 0 ==> y = -x)})
let abs x = if x >= 0 then x else -x

val lemma_distributivity_mult:
  a:nat -> b:nat -> c:nat -> d:nat -> Lemma
  ((a + b) * (c + d) = a * c + a * d + b * c + b * d)
let lemma_distributivity_mult a b c d = ()

val lemma_karatsuba_mult:
  x:size_nat -> a:nat -> a0:nat -> a1:nat -> b:nat -> b0:nat -> b1:nat -> Lemma
  (requires (let pow_x = pow2 (pow2 x) in
	     a == a1 * pow_x + a0 /\ b == b1 * pow_x + b0))
  (ensures (let pow_x = pow2 (pow2 x) in
	    let pow_x1 = pow2 (pow2 (x + 1)) in
	    a * b == a1 * b1 * pow_x1 + (a0 * b1 + a1 * b0) * pow_x + a0 * b0))
  #reset-options "--z3rlimit 50 --max_fuel 2"
let lemma_karatsuba_mult x a a0 a1 b b0 b1 =
  let pow_x = pow2 (pow2 x) in
  let pow_x1 = pow2 (pow2 (x + 1)) in
  assert (a * b == (a1 * pow_x + a0) * (b1 * pow_x + b0));
  lemma_distributivity_mult (a1 * pow_x) a0 (b1 * pow_x) b0;
  pow2_plus (pow2 x) (pow2 x);
  pow2_double_sum x

val lemma_pow_div_karatsuba:
  x0:size_nat{x0 > 0} -> b:nat{b < pow2 (pow2 x0)} -> Lemma
  (requires (True))
  (ensures (let pow_x = pow2 (pow2 (x0 - 1)) in
	    let b1 = b / pow_x in
	    0 <= b1 /\ b1 < pow_x))
  #reset-options "--z3rlimit 150 --max_fuel 0"
let lemma_pow_div_karatsuba x0 b =
  let x = x0 - 1 in
  let pow_x = pow2 (pow2 x) in
  pow2_lt_compat x0 x;
  lemma_div_lt b (pow2 x0) (pow2 x);
  assert (b / pow_x < pow2 (pow2 x0 - pow2 x));
  pow2_plus (x0 - 1) 1;
  assert_norm (pow2 1 = 2)
