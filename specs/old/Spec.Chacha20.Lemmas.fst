module Spec.Chacha20.Lemmas

module ST = FStar.HyperStack.ST

open FStar.Mul
open FStar.Seq
open FStar.UInt32
open FStar.Old.Endianness
open Spec.Lib

val lemma_seq_cons_4: #a:Type -> x:a -> y:a -> z:a -> w:a -> Lemma
  (requires (True))
  (ensures (length (createL [x; y; z; w]) = 4))
  [SMTPat (createL [x; y; z; w])]
let lemma_seq_cons_4 #a x y z w = assert_norm(List.Tot.length [x; y; z; w] = 4)
