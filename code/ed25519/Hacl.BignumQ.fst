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

module Hacl.BignumQ

open FStar.Mul

(*
  Barrett modular reduction:

  let reduce a =
    let q = (a * m) >> k in
    let a = a - q * n in
    if n <= a then a - n else a

  compute a % n where:
  - n = 2^252 + 27742317777372353535851937790883648493
  - k = 33 * 8 = 264
  - m = floor ( 2^k / L )

*)

#set-options "--max_fuel 0 --max_ifuel 0"

let l = 
  assert_norm(0x1000000000000000000000000000000014def9dea2f79cd65812631a5cf5d3ed = pow2 252 +  27742317777372353535851937790883648493);
  0x1000000000000000000000000000000014def9dea2f79cd65812631a5cf5d3ed
let k = 512
let pow2k : p:nat{p = pow2 512} =
  assert_norm(0x100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000 = pow2 512);
  0x100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
let m :m:pos{m = pow2 k / l} =
  assert_norm(pow2 512 / 0x1000000000000000000000000000000014def9dea2f79cd65812631a5cf5d3ed
  = 0xfffffffffffffffffffffffffffffffeb2106215d086329a7ed9ce5a30a2c131b);
  0xfffffffffffffffffffffffffffffffeb2106215d086329a7ed9ce5a30a2c131b

let barrett_reduce (a:nat{a < l * l}) : Tot (b:nat{b < l}) =
  let q = (a * m) / pow2k in
  let a = a - q * l in
  if l <= a then a - l else a

let test () =  
  assert_norm (0x19cd65812631a59cd65812631a59cd65812631a514def9dea2f74def9dea2f74def9dea2f79cd65812636581261a5ffff % 0x1000000000000000000000000000000014def9dea2f79cd65812631a5cf5d3ed = barrett_reduce 0x19cd65812631a59cd65812631a59cd65812631a514def9dea2f74def9dea2f74def9dea2f79cd65812636581261a5ffff)

#set-options "--max_fuel 0 --max_ifuel 0 --z3rlimit 50"

val lemma_barrett_reduce:
  a:nat{a < l * l} ->
  Lemma (barrett_reduce a = a % l)
let lemma_barrett_reduce a =
  assert_norm(((l * l) * (l - 1) + (pow2k - 1) * l) / pow2k < 2 * l);
  let q = (m * a) / pow2k in
  Math.Lemmas.modulo_lemma (barrett_reduce a) l;
  let a' = a - q * l in
  cut (a' = a - ((a * (pow2k / l)) / pow2k) * l);
  cut (0 <= a');
  cut (a' % l = a % l);
  Math.Lemmas.distributivity_sub_right pow2k a (((a * (pow2k / l)) / pow2k) * l);
  cut (pow2k * a' = pow2k * a - (pow2k * ((a * (pow2k / l)) / pow2k)) * l);
  Math.Lemmas.lemma_div_mod (a * (pow2k / l)) pow2k;
  cut (pow2k * a' = pow2k * a - ((a * (pow2k / l)) - ((a * (pow2k / l)) % pow2k)) * l);
  Math.Lemmas.distributivity_sub_left (a * (pow2k / l)) ((a * (pow2k / l)) % pow2k) l;
  cut (pow2k * a' = pow2k * a - (a * (pow2k / l)) * l + ((a * (pow2k / l)) % pow2k) * l);
  cut (pow2k * a' <= pow2k * a - (a * (pow2k / l)) * l + (pow2k - 1) * l);
  cut (pow2k * a - (a * (pow2k / l)) * l + (pow2k - 1) * l = a * pow2k - a * ((pow2k / l) * l) + (pow2k - 1) * l);
  Math.Lemmas.distributivity_sub_right a pow2k ((pow2k / l) * l);
  Math.Lemmas.lemma_div_mod pow2k l;
  cut (pow2k * a - (a * (pow2k / l)) * l + (pow2k - 1) * l = a * (pow2k % l) + (pow2k - 1) * l);
  cut (pow2k * a - (a * (pow2k / l)) * l + (pow2k - 1) * l <= a * (l - 1) + (pow2k - 1) * l);
  cut (pow2k * a - (a * (pow2k / l)) * l + (pow2k - 1) * l <= (l * l) * (l - 1) + (pow2k - 1) * l);
  cut (a' <= ((l * l) * (l - 1) + (pow2k - 1) * l) / pow2k);
  cut (a' <= 2 * l)
