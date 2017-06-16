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

module Hacl.Impl.Ed25519.SecretExpand

open FStar.Buffer
open Hacl.UInt8


#reset-options "--max_fuel 0 --max_ifuel 0 --z3rlimit 20"

let hint8_p = buffer Hacl.UInt8.t
let op_String_Access h b = Hacl.Spec.Endianness.reveal_sbytes (as_seq h b)


val secret_expand:
  expanded:hint8_p{length expanded = 64} ->
  secret:hint8_p{length secret = 32} ->
  Stack unit
    (requires (fun h -> live h expanded /\ live h secret))
    (ensures (fun h0 _ h1 -> live h0 expanded /\ live h0 secret /\
      live h1 expanded /\ modifies_1 expanded h0 h1 /\
      (let low = Buffer.sub expanded 0ul 32ul in let high = Buffer.sub expanded 32ul 32ul in
      (h1.[low], h1.[high]) == Spec.Ed25519.secret_expand h0.[secret])))
