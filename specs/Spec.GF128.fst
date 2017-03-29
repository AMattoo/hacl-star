module Spec.GF128

open FStar.Mul
open FStar.Seq
open FStar.UInt8
open FStar.Endianness
open Spec.GaloisField

(* Field types and parameters *)

#set-options "--initial_fuel 0 --max_fuel 0 --initial_ifuel 0 --max_ifuel 0"

let irr : polynomial 127 = UInt.to_vec #128 0xe1000000000000000000000000000000
let gf128 = mk_field 128 irr
let elem = felem gf128
let zero = zero #gf128
let op_Plus_At e1 e2 = fadd #gf128 e1 e2
let op_Star_At e1 e2 = fmul #gf128 e1 e2

val add_comm: a:elem -> b:elem -> Lemma (a +@ b == b +@ a)
let add_comm e1 e2 = add_comm #gf128 e1 e2

(* GCM types and specs *)

type word = w:bytes{length w <= 16}
type word_16 = w:bytes{length w = 16}
type key = word_16
type tag = word_16
type text = seq word

let pad (w:word) : Tot word_16 = w @| (create (16 - length w) 0uy)
let encode (w:word) : Tot elem = to_felem (big_endian (pad w))
let decode (e:elem) : Tot word_16 = big_bytes 16ul (from_felem e)

val poly: vs:text -> r:elem -> Tot (a:elem) (decreases (Seq.length vs))
let rec poly vs r =
  if Seq.length vs = 0 then zero
  else
    let v = Seq.head vs in 
    (encode v +@ poly (Seq.tail vs) r ) *@ r

let finish (a:elem) (s:tag) : Tot tag = decode (a +@ (encode s))

let mac (vs:text) (r:elem) (s:tag) : Tot tag  = finish (poly vs r) s

val poly_non_empty: vs:text{Seq.length vs > 0} -> r:elem ->
  Lemma (poly vs r == (encode (Seq.head vs) +@ poly (Seq.tail vs) r) *@ r)
let poly_non_empty vs r = ()

val poly_cons: x:word -> xs:text -> r:elem ->
  Lemma (poly (Seq.cons x xs) r == (encode x +@ poly xs r) *@ r)
let poly_cons x xs r =
  poly_non_empty (Seq.cons x xs) r;
  Seq.lemma_eq_intro (Seq.tail (Seq.cons x xs)) xs

(* Test *)

#reset-options "--initial_fuel 0 --max_fuel 2 --initial_ifuel 0 --max_ifuel 2"

val encode_bytes: txt:bytes -> Tot text (decreases (Seq.length txt))
let rec encode_bytes txt =
  let l = Seq.length txt in
  if l = 0 then
    Seq.createEmpty
  else
    let l0 = FStar.Math.Lib.min l 16 in
    let w, txt = Seq.split txt l0 in
    Seq.snoc (encode_bytes txt) w
    
unfold let info = createL [
  0xfeuy; 0xeduy; 0xfauy; 0xceuy; 0xdeuy; 0xaduy; 0xbeuy; 0xefuy;
  0xfeuy; 0xeduy; 0xfauy; 0xceuy; 0xdeuy; 0xaduy; 0xbeuy; 0xefuy;
  0xabuy; 0xaduy; 0xdauy; 0xd2uy; 0x00uy; 0x00uy; 0x00uy; 0x00uy;
  0x00uy; 0x00uy; 0x00uy; 0x00uy; 0x00uy; 0x00uy; 0x00uy; 0x00uy;
  0x5auy; 0x8duy; 0xefuy; 0x2fuy; 0x0cuy; 0x9euy; 0x53uy; 0xf1uy;
  0xf7uy; 0x5duy; 0x78uy; 0x53uy; 0x65uy; 0x9euy; 0x2auy; 0x20uy;
  0xeeuy; 0xb2uy; 0xb2uy; 0x2auy; 0xafuy; 0xdeuy; 0x64uy; 0x19uy;
  0xa0uy; 0x58uy; 0xabuy; 0x4fuy; 0x6fuy; 0x74uy; 0x6buy; 0xf4uy;
  0x0fuy; 0xc0uy; 0xc3uy; 0xb7uy; 0x80uy; 0xf2uy; 0x44uy; 0x45uy;
  0x2duy; 0xa3uy; 0xebuy; 0xf1uy; 0xc5uy; 0xd8uy; 0x2cuy; 0xdeuy;
  0xa2uy; 0x41uy; 0x89uy; 0x97uy; 0x20uy; 0x0euy; 0xf8uy; 0x2euy;
  0x44uy; 0xaeuy; 0x7euy; 0x3fuy ]

unfold let h : word = createL [
  0xacuy; 0xbeuy; 0xf2uy; 0x05uy; 0x79uy; 0xb4uy; 0xb8uy; 0xebuy;
  0xceuy; 0x88uy; 0x9buy; 0xacuy; 0x87uy; 0x32uy; 0xdauy; 0xd7uy ]

unfold let expected = createL [
  0xccuy; 0x9auy; 0xe9uy; 0x17uy; 0x57uy; 0x29uy; 0xa6uy; 0x49uy;
  0x93uy; 0x6euy; 0x89uy; 0x0buy; 0xd9uy; 0x71uy; 0xa8uy; 0xbfuy ]

let test() = Spec.GaloisField.test() &&
             (decode (poly (encode_bytes info) (encode h)) = expected)
