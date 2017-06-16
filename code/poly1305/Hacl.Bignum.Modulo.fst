//
//   Copyright 2016-2017  INRIA
//
//   Maintainers: Jean-Karim Zinzindohoué
//                Karthikeyan Bhargavan
//                Benjamin Beurdouche
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
//   distributed under the License is distributed on an "AS IS" BASIS,
//   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//   See the License for the specific language governing permissions and
//   limitations under the License.
//

module Hacl.Bignum.Modulo

open FStar.Mul
open FStar.HyperStack
open FStar.Buffer

open Hacl.Bignum.Constants
open Hacl.Bignum.Parameters
open Hacl.Spec.Bignum.Bigint
open Hacl.Bignum.Limb

open Hacl.Spec.Bignum.Modulo

#set-options "--initial_fuel 0 --max_fuel 0"

inline_for_extraction let mask_2_42 : p:Hacl.Bignum.Wide.t{w p = pow2 42 - 1} =
  assert_norm (pow2 64 = 0x10000000000000000); assert_norm(pow2 42 - 1 = 0x3ffffffffff);
  limb_to_wide (uint64_to_limb 0x3ffffffffffuL)

inline_for_extraction let mask_2_42' : p:t{v p = pow2 42 - 1} =
  assert_norm (pow2 64 = 0x10000000000000000); assert_norm(pow2 42 - 1 = 0x3ffffffffff);
  uint64_to_limb 0x3ffffffffffuL

[@"c_inline"]
val reduce:
  b:felem ->
  Stack unit
  (requires (fun h -> live h b /\ reduce_pre (as_seq h b)))
  (ensures (fun h0 _ h1 -> live h0 b /\ reduce_pre (as_seq h0 b) /\ live h1 b /\ modifies_1 b h0 h1
    /\ as_seq h1 b == reduce_spec (as_seq h0 b)))
[@"c_inline"]
let reduce b =
  assert_norm(pow2 4 = 16);
  assert_norm(pow2 2 = 4);
  let b0 = b.(0ul) in
  Math.Lemmas.modulo_lemma (v b0 * 16) (pow2 64);
  Math.Lemmas.modulo_lemma (v b0 * 4) (pow2 64);
  b.(0ul) <- (b0 <<^ 4ul) +^ (b0 <<^ 2ul)


#set-options "--z3rlimit 20"

[@"c_inline"]
val carry_top:
  b:felem ->
  Stack unit
  (requires (fun h -> live h b /\ carry_top_pre (as_seq h b)))
  (ensures (fun h0 _ h1 -> live h0 b /\ carry_top_pre (as_seq h0 b) /\ live h1 b /\ modifies_1 b h0 h1
    /\ as_seq h1 b == carry_top_spec (as_seq h0 b)))
[@"c_inline"]
let carry_top b =
  let b2 = b.(2ul) in
  let b0 = b.(0ul) in
  assert_norm((1 * pow2 limb_size) % pow2 (word_size) = pow2 (limb_size));
  assert_norm(pow2 limb_size > 1);
  Math.Lemmas.modulo_lemma (v b2 / pow2 42) (pow2 word_size);
  let b2_42 = b2 >>^ 42ul in
  cut (v b2_42 = v b2 / pow2 42);
  assert_norm(pow2 2 = 4); Math.Lemmas.modulo_lemma (v b2_42 * 4) (pow2 64);
  b.(2ul) <- b2 &^ mask_2_42';
  b.(0ul) <- ((b2_42 <<^ 2ul) +^ b2_42) +^ b0


[@"c_inline"]
val carry_top_wide:
  b:felem_wide ->
  Stack unit
    (requires (fun h -> live h b /\ carry_top_wide_pre (as_seq h b)))
    (ensures (fun h0 _ h1 -> live h0 b /\ carry_top_wide_pre (as_seq h0 b) /\ live h1 b /\ modifies_1 b h0 h1
      /\ as_seq h1 b == carry_top_wide_spec (as_seq h0 b)))
[@"c_inline"]
let carry_top_wide b =
  let b2 = b.(2ul) in
  let b0 = b.(0ul) in
  let open Hacl.Bignum.Wide in
  assert_norm((1 * pow2 limb_size) % pow2 (2 * word_size) = pow2 (limb_size));
  assert_norm(pow2 limb_size > 1);
  let b2' = b2 &^ mask_2_42 in
  Math.Lemmas.modulo_lemma (v b2 / pow2 42) (pow2 word_size);
  let b2_42 = wide_to_limb (b2 >>^ 42ul) in
  assert_norm(pow2 2 = 4); Math.Lemmas.modulo_lemma (Hacl.Bignum.Limb.v b2_42 * 4) (pow2 64);
  let b0' = b0 +^ limb_to_wide Hacl.Bignum.Limb.((b2_42 <<^ 2ul) +^ b2_42) in
  b.(2ul) <- b2';
  b.(0ul) <- b0'
