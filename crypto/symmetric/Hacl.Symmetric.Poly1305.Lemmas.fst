module Hacl.Symmetric.Poly1305.Lemmas

open FStar.Mul
open FStar.HyperStack
open FStar.ST
open FStar.Ghost
open FStar.Buffer
open FStar.Math.Lib
open FStar.Math.Lemmas
open Hacl.UInt64
open Hacl.Cast
open Hacl.SBuffer
open Hacl.Symmetric.Poly1305.Parameters
open Hacl.Symmetric.Poly1305.Bigint
open Hacl.Symmetric.Poly1305.Bignum.Lemmas
open Hacl.Symmetric.Poly1305.Bignum


(* Module abbreviations *)
module HH = FStar.HyperHeap
module HS = FStar.HyperStack

module U8   = FStar.UInt8
module U32  = FStar.UInt32
module U64  = FStar.UInt64
module H8   = Hacl.UInt8
module H32  = Hacl.UInt32
module H64  = Hacl.UInt64

#reset-options "--lax"

(* Auxiliary lemmas and functions *)

val max_value_increases: h:heap -> b:bigint{live h b} -> n:pos -> m:pos{m>=n /\ m <= length b} -> Lemma
  (maxValue h b n <= maxValue h b m)
let rec max_value_increases h b n m =
  match (m-n) with
  | 0 -> () | _ -> max_value_increases h b n (m-1)

val pow2_5_lemma: unit -> Lemma (requires (True)) (ensures (pow2 5 = 32))
let pow2_5_lemma () = 
  ()

val satisfies_constraints_after_multiplication: h:heap -> b:bigint{live h b /\ length b >= 2*norm_length-1 /\ maxValue h b (length b) <= norm_length * pow2 53} -> Lemma (requires (True))
  (ensures (satisfiesModuloConstraints h b)) 
let satisfies_constraints_after_multiplication h b =
  max_value_increases h b (2*norm_length-1) (length b);
  pow2_5_lemma ();
  cut (maxValue h b (2*norm_length-1) * 6 <= 30 * pow2 53 /\ 30 * pow2 53 < pow2 5 * pow2 53);  
  (* IntLibLemmas.pow2_exp 5 53; *)
  (* IntLibLemmas.pow2_increases 63 58; *)
  ()

assume val aux_lemma': a:nat -> n:nat{n <= 32} -> Lemma (requires True) (ensures ((((a * pow2 (32 - n)) % pow2 63) % pow2 26) % pow2 (32 - n) = 0 ))
(* let aux_lemma' a n =  *)
(*   if 32-n > 26 then ( *)
(*     IntLibLemmas.pow2_exp (32-n-26) 26; *)
(*     IntLibLemmas.modulo_lemma (a * pow2 (32-n-26)) (pow2 26) ) *)
(*   else if 32 - n = 26 then  *)
(*     IntLibLemmas.modulo_lemma a (pow2 26) *)
(*   else () *)

val aux_lemma: x:s64{v x < pow2 32} -> y:s64{v y < pow2 32} -> n:nat{n >= 7 /\ n < 32} -> Lemma
  (requires (True))
  (ensures (Math.Lib.div (v x) (pow2 n) + (((v y * pow2 (32 - n)) % pow2 63) % pow2 26) < pow2 26)) 
let aux_lemma x y n =
  (* IntLibLemmas.div_pow2_inequality (v x) 32; *)
  (* IntLibLemmas.pow2_increases 26 (32-n); *)
  aux_lemma' (v y) n;
  let a = Math.Lib.div (v x) (pow2 n) in
  let b = ((v y * pow2 (32 - n)) % pow2 63) % pow2 26 in
  let n1 = 26 in
  let n2 = 32 - n in 
  (* IntLibLemmas.div_positive (v x) (pow2 n);  *)
  (* IntLibLemmas.pow2_disjoint_ranges a b n1 n2; *)
  ()

val aux_lemma_1: x:s64{v x < pow2 32} -> Lemma (requires (True)) (ensures (v (x >>^ 8ul) < pow2 24)) 
let aux_lemma_1 x = 
  (* IntLibLemmas.div_pow2_inequality (v x) 32; *)
  ()
  

(* val aux_lemma_2: b:bigint -> Lemma (requires (True)) (ensures ((arefs (only b)) = !{content b}))  *)
(* let aux_lemma_2 b =  *)
(*   FStar.Set.lemma_equal_intro (arefs (only b)) !{content b}; *)
(*   cut (True /\ arefs (only b) = !{content b}) *)

(* val aux_lemma_3: h0:heap -> h1:heap -> b:bigint -> Lemma (requires (modifies (arefs (only b)) h0 h1)) *)
(*   (ensures (modifies !{content b} h0 h1)) *)
(* let aux_lemma_3 h0 h1 b =  *)
(*   aux_lemma_2 b; () *)
