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

module Hacl.Lib.Create64

#reset-options "--max_fuel 0 --z3rlimit 100"

open FStar.Buffer
open Seq.Create

let h64 = Hacl.UInt64.t

val make_h64_5: b:buffer h64{length b = 5} ->
  s0:h64 -> s1:h64 -> s2:h64 -> s3:h64 -> s4:h64 ->
  Stack unit
    (requires (fun h -> live h b))
    (ensures (fun h0 _ h1 -> live h1 b /\ modifies_1 b h0 h1 /\
      as_seq h1 b == create_5 s0 s1 s2 s3 s4))
let make_h64_5 b s0 s1 s2 s3 s4 =
  b.(0ul) <- s0;  b.(1ul) <- s1;  b.(2ul) <- s2;  b.(3ul) <- s3; b.(4ul) <- s4;
  let h = ST.get() in
  Seq.lemma_eq_intro (as_seq h b) (create_5 s0 s1 s2 s3 s4)


val make_h64_10: b:buffer h64{length b = 10} ->
  s0:h64 -> s1:h64 -> s2:h64 -> s3:h64 -> s4:h64 ->
  s5:h64 -> s6:h64 -> s7:h64 -> s8:h64 -> s9:h64 ->
  Stack unit
    (requires (fun h -> live h b))
    (ensures (fun h0 _ h1 -> live h1 b /\ modifies_1 b h0 h1 /\
      as_seq h1 b == create_10 s0 s1 s2 s3 s4 s5 s6 s7 s8 s9))
let make_h64_10 b s0 s1 s2 s3 s4 s5 s6 s7 s8 s9 =
  b.(0ul) <- s0;  b.(1ul) <- s1;  b.(2ul) <- s2;  b.(3ul) <- s3; b.(4ul) <- s4;
  b.(5ul) <- s5;  b.(6ul) <- s6;  b.(7ul) <- s7;  b.(8ul) <- s8; b.(9ul) <- s9;
  let h = ST.get() in
  Seq.lemma_eq_intro (as_seq h b) (create_10 s0 s1 s2 s3 s4 s5 s6 s7 s8 s9)
