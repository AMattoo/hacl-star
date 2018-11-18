module Hacl.Spec.Curve25519.Finv.Field51

open FStar.Mul
open Lib.Sequence
open Lib.IntTypes
open Hacl.Spec.Curve25519.Field51

#reset-options "--z3rlimit 50 --max_fuel 2 --max_ifuel 0 --using_facts_from '* -FStar.Seq'"

let felem5 = x:felem5{felem_fits5 x (1, 2, 1, 1, 1)}
let one5:felem5 = (u64 1, u64 0, u64 0, u64 0, u64 0)

let felem = x:nat{x < prime}
let feval (f:felem5) : GTot felem = (as_nat5 f) % prime
let one:felem =
  assert_norm (1 < prime);
  1

val fmul5: f1:felem5 -> f2:felem5 -> r:felem5{feval r == (feval f1 * feval f2) % prime}
let fmul5 f1 f2 =
  let r = fmul5 f1 f2 in
  assert ((as_nat5 r) % prime == (as_nat5 f1 * as_nat5 f2) % prime);
  FStar.Math.Lemmas.lemma_mod_mul_distr_l (as_nat5 f1) (as_nat5 f2) prime;
  FStar.Math.Lemmas.lemma_mod_mul_distr_r ((as_nat5 f1) % prime) (as_nat5 f2) prime;
  r

val fmul: felem -> felem -> felem
let fmul f1 f2 = (f1 * f2) % prime

val pow: a:felem -> b:nat -> res:felem
let rec pow a b =
  if b = 0 then 1
  else fmul a (pow a (b - 1))

val pow5: a:felem5 -> b:nat -> res:felem5
let rec pow5 a b =
  if b = 0 then one5
  else fmul5 a (pow5 a (b - 1))

val lemma_pow_one: x:felem
  -> Lemma
    (requires True)
    (ensures  x == pow x 1)
let lemma_pow_one x =
  assert (pow x 1 == fmul x 1);
  FStar.Math.Lemmas.modulo_lemma x prime

val lemma_fmul_assoc: a:felem -> b:felem -> c:felem
  -> Lemma
    (fmul (fmul a b) c == fmul a (fmul b c))
let lemma_fmul_assoc a b c =
  let r = fmul (fmul a b) c in
  FStar.Math.Lemmas.lemma_mod_mul_distr_l (a * b) c prime;
  FStar.Math.Lemmas.paren_mul_right a b c;
  FStar.Math.Lemmas.lemma_mod_mul_distr_r a (b * c) prime

val lemma_pow_add: x:felem -> n:nat -> m:nat
  -> Lemma
    (requires True)
    (ensures  fmul (pow x n) (pow x m) == pow x (n + m))
let rec lemma_pow_add x n m =
  if n = 0 then FStar.Math.Lemmas.modulo_lemma (pow x m) prime
  else begin
    lemma_pow_add x (n - 1) m;
    lemma_fmul_assoc x (pow x (n - 1)) (pow x m)
  end

val lemma_pow_mul: x:felem -> n:nat -> m:nat
  -> Lemma
    (requires True)
    (ensures  pow (pow x n) m == pow x (n * m))
let rec lemma_pow_mul x n m =
  if m = 0 then ()
  else begin
    //assert (pow (pow x n) m == fmul (pow x n) (pow (pow x n) (m - 1)));
    lemma_pow_mul x n (m - 1);
    //assert (pow (pow x n) (m - 1) == pow x (n * (m - 1)));
    lemma_pow_add x n (n * (m - 1));
    assert_spinoff (n + n * (m - 1) = n * m)
  end

val fsqr: felem -> felem
let fsqr f1 = (f1 * f1) % prime

val fsqr5: f1:felem5 -> r:felem5{feval r == (feval f1 * feval f1) % prime}
let fsqr5 f1 =
  let r = fsqr5 f1 in
  assert ((as_nat5 r) % prime == (as_nat5 f1 * as_nat5 f1) % prime);
  FStar.Math.Lemmas.lemma_mod_mul_distr_l (as_nat5 f1) (as_nat5 f1) prime;
  FStar.Math.Lemmas.lemma_mod_mul_distr_r ((as_nat5 f1) % prime) (as_nat5 f1) prime;
  r

val fsquare_times:
    inp:felem
  -> n:size_nat{0 < n}
  -> out:felem{out == pow inp (pow2 n)}
let fsquare_times inp n =
  let out = fsqr inp in
  lemma_pow_one inp;
  lemma_pow_add inp 1 1;
  assert_norm (pow2 1 = 2);
  assert (out == pow inp (pow2 1));
  let out =
    Lib.LoopCombinators.repeati_inductive #felem (n - 1)
    (fun i out -> out == pow inp (pow2 (i + 1)))
    (fun i out ->
      assert (out == pow inp (pow2 (i + 1)));
      let res = fsqr out in
      lemma_pow_one out;
      lemma_pow_add out 1 1;
      lemma_pow_mul inp (pow2 (i + 1)) (pow2 1);
      assert_norm (pow2 (i + 1) * pow2 1 = pow2 (i + 2));
      assert (res == pow inp (pow2 (i + 2)));
      res) out in
  assert (out == pow inp (pow2 n));
  out

val fsquare_times5:
    inp:felem5
  -> n:size_nat{0 < n}
  -> out:felem5{feval out == fsquare_times (feval inp) n}
let fsquare_times5 inp n =
  let out:felem5 = fsqr5 inp in
  lemma_pow_one (feval inp);
  lemma_pow_add (feval inp) 1 1;
  assert_norm (pow2 1 = 2);
  assert (feval out == pow (feval inp) (pow2 1));
  let out =
    Lib.LoopCombinators.repeati_inductive #felem5 (n - 1)
    (fun i out -> feval out == pow (feval inp) (pow2 (i + 1)))
    (fun i out ->
      let res = fsqr5 out in
      lemma_pow_one (feval out);
      lemma_pow_add (feval out) 1 1;
      lemma_pow_mul (feval inp) (pow2 (i + 1)) (pow2 1);
      res) out in
  assert (feval out == pow (feval inp) (pow2 n));
  out

let pow_inv:nat =
  assert_norm (pow2 255 - 21 > 0);
  pow2 255 - 21

#set-options "--max_fuel 0 --max_ifuel 0"

val finv: inp:felem -> out:felem{out == pow inp (pow2 255 - 21)}
let finv i =
  (* 2 *)  let a  = fsquare_times i 1 in
  assert (a == pow i 2);
  (* 8 *)  let t0 = fsquare_times a 2 in
  assert (t0 == pow a 4);
  lemma_pow_mul i 2 4;
  assert (t0 == pow i 8);
  (* 9 *)  let b  = fmul t0 i in
  lemma_pow_one i;
  lemma_pow_add i 8 1;
  assert (b == pow i 9);
  (* 11 *) let a  = fmul b a in
  lemma_pow_add i 9 2;
  assert (a == pow i 11);
  (* 22 *) let t0 = fsquare_times a 1 in
  lemma_pow_mul i 11 2;
  assert (t0 == pow i 22);
  (* 2^5 - 2^0 = 31 *) let b = fmul t0 b in
  lemma_pow_add i 22 9;
  assert (b == pow i 31);
  (* 2^10 - 2^5 *) let t0 = fsquare_times b 5 in
  lemma_pow_mul i 31 (pow2 5);
  assert_norm (31 * pow2 5 = pow2 10 - pow2 5);
  assert (t0 == pow i (pow2 10 - pow2 5));
  (* 2^10 - 2^0 *) let b = fmul t0 b in
  assert_norm (31 = pow2 5 - 1);
  lemma_pow_add i (pow2 10 - pow2 5) (pow2 5 - 1);
  assert (b == pow i (pow2 10 - 1));
  (* 2^20 - 2^10 *) let t0 = fsquare_times b 10 in
  lemma_pow_mul i (pow2 10 - 1) (pow2 10);
  assert_norm ((pow2 10 - 1) * pow2 10 == pow2 20 - pow2 10);
  assert (t0 == pow i (pow2 20 - pow2 10));
  (* 2^20 - 2^0 *) let c = fmul t0 b in
  lemma_pow_add i (pow2 20 - pow2 10) (pow2 10 - 1);
  assert_norm (pow2 20 - pow2 10 + pow2 10 - 1 = pow2 20 - 1);
  assert (c == pow i (pow2 20 - 1));
  (* 2^40 - 2^20 *) let t0 = fsquare_times c 20 in
  lemma_pow_mul i (pow2 20 - 1) (pow2 20);
  assert_norm ((pow2 20 - 1) * pow2 20 = pow2 40 - pow2 20);
  assert (t0 == pow i (pow2 40 - pow2 20));
  (* 2^40 - 2^0 *) let t0 = fmul t0 c in
  lemma_pow_add i (pow2 40 -pow2 20) (pow2 20 - 1);
  assert_norm (pow2 40 - pow2 20 + pow2 20 - 1 = pow2 40 - 1);
  assert (t0 == pow i (pow2 40 - 1));
  (* 2^50 - 2^10 *) let t0 = fsquare_times t0 10 in
  lemma_pow_mul i (pow2 40 - 1) (pow2 10);
  assert_norm ((pow2 40 - 1) * pow2 10 = pow2 50 - pow2 10);
  assert (t0 == pow i (pow2 50 - pow2 10));
  (* 2^50 - 2^0 *) let b = fmul t0 b in
  lemma_pow_add i (pow2 50 - pow2 10) (pow2 10 - 1);
  assert_norm (pow2 50 - pow2 10 + pow2 10 - 1 = pow2 50 - 1);
  assert (b == pow i (pow2 50 - 1));
  (* 2^100 - 2^50 *) let t0 = fsquare_times b 50 in
  lemma_pow_mul i (pow2 50 - 1) (pow2 50);
  assert_norm ((pow2 50 - 1) * pow2 50 = pow2 100 - pow2 50);
  assert (t0 == pow i (pow2 100 - pow2 50));
  (* 2^100 - 2^0 *) let c = fmul t0 b in
  lemma_pow_add i (pow2 100 - pow2 50) (pow2 50 - 1);
  assert_norm (pow2 100 - pow2 50 + pow2 50 - 1 = pow2 100 - 1);
  assert (c == pow i (pow2 100 - 1));
  (* 2^200 - 2^100 *) let t0 = fsquare_times c 100 in
  lemma_pow_mul i (pow2 100 - 1) (pow2 100);
  assert_norm ((pow2 100 - 1) * pow2 100 = pow2 200 - pow2 100);
  assert (t0 == pow i (pow2 200 - pow2 100));
  (* 2^200 - 2^0 *) let t0 = fmul t0 c in
  lemma_pow_add i (pow2 200 - pow2 100) (pow2 100 - 1);
  assert_norm (pow2 200 - pow2 100 + pow2 100 - 1 = pow2 200 - 1);
  assert (t0 == pow i (pow2 200 - 1));
  (* 2^250 - 2^50 *) let t0 = fsquare_times t0 50 in
  lemma_pow_mul i (pow2 200 - 1) (pow2 50);
  assert_norm ((pow2 200 - 1) * pow2 50 = pow2 250 - pow2 50);
  assert (t0 == pow i (pow2 250 - pow2 50));
  (* 2^250 - 2^0 *) let t0 = fmul t0 b in
  lemma_pow_add i (pow2 250 - pow2 50) (pow2 50 - 1);
  assert_norm (pow2 250 - pow2 50 + pow2 50 - 1 = pow2 250 - 1);
  assert (t0 == pow i (pow2 250 - 1));
  (* 2^255 - 2^5 *) let t0 = fsquare_times t0 5 in
  lemma_pow_mul i (pow2 250 - 1) (pow2 5);
  assert_norm ((pow2 250 - 1) * pow2 5 = pow2 255 - pow2 5);
  assert (t0 == pow i (pow2 255 - pow2 5));
  (* 2^255 - 21 *) let o = fmul t0 a in
  lemma_pow_add i (pow2 255 - pow2 5) 11;
  assert_norm (pow2 255 - pow2 5 + 11 = pow2 255 - 21);
  assert (o == pow i (pow2 255 - 21));
  o

val finv5: inp:felem5 -> out:felem5{feval out == pow (feval inp) (pow2 255 - 21)}
let finv5 i =
  (* 2 *)  let a  = fsquare_times5 i 1 in
  (* 8 *)  let t0 = fsquare_times5 a 2 in
  (* 9 *)  let b  = fmul5 t0 i in
  (* 11 *) let a  = fmul5 b a in
  (* 22 *) let t0 = fsquare_times5 a 1 in
  (* 2^5 - 2^0 = 31 *) let b = fmul5 t0 b in
  (* 2^10 - 2^5 *) let t0 = fsquare_times5 b 5 in
  (* 2^10 - 2^0 *) let b = fmul5 t0 b in
  (* 2^20 - 2^10 *) let t0 = fsquare_times5 b 10 in
  (* 2^20 - 2^0 *) let c = fmul5 t0 b in
  (* 2^40 - 2^20 *) let t0 = fsquare_times5 c 20 in
  (* 2^40 - 2^0 *) let t0 = fmul5 t0 c in
  (* 2^50 - 2^10 *) let t0 = fsquare_times5 t0 10 in
  (* 2^50 - 2^0 *) let b = fmul5 t0 b in
  (* 2^100 - 2^50 *) let t0 = fsquare_times5 b 50 in
  (* 2^100 - 2^0 *) let c = fmul5 t0 b in
  (* 2^200 - 2^100 *) let t0 = fsquare_times5 c 100 in
  (* 2^200 - 2^0 *) let t0 = fmul5 t0 c in
  (* 2^250 - 2^50 *) let t0 = fsquare_times5 t0 50 in
  (* 2^250 - 2^0 *) let t0 = fmul5 t0 b in
  (* 2^255 - 2^5 *) let t0 = fsquare_times5 t0 5 in
  (* 2^255 - 21 *) let o = fmul5 t0 a in
  assert (feval o == finv (feval i));
  o
