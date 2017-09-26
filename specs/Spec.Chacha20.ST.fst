module Spec.Chacha20.ST

module ST = FStar.HyperStack.ST

#set-options "--max_fuel 0 --z3rlimit 100"

//open FStar.Mul
open FStar.Seq
open FStar.UInt32
open Spec.Lib

(* Chacha20 State *)
// internally, blocks are represented as 16 x 4-byte integers
type chacha_st 'b = seq1_st u32 16 'b
type st = seq_l u32 16
let idx = index_l 16

(* Wrapper monadic functions specialized for the Chacha state *)
let copy : chacha_st st = seq1_copy #u32 #16 
unfold let read i : chacha_st u32 = seq1_read #u32 #16 i
unfold let write i x : chacha_st unit = seq1_write #u32 #16 i x
let return (y:'b) : chacha_st 'b = seq1_return y
unfold let bind (f:chacha_st 'b) (g:'b -> chacha_st 'c) : chacha_st 'c = seq1_bind f g
let iter (n:nat) (f:chacha_st unit) = seq1_iter n f
let in_place_map2 (f:u32 -> u32 -> Tot u32) (s:st) = seq1_in_place_map2 f s
let alloc (f:chacha_st 'b) = seq1_alloc 0ul f
let uint32s_from_le src (start:idx) (len:nat{FStar.Mul.(len * 4 = length src)
					    /\ start + len <= 16}): chacha_st unit = 
	seq1_uint32s_from_le src start len
let uint32s_to_le (start:idx) (len:nat{start + len <= 16})
		  : chacha_st (lbytes FStar.Mul.(4 * len)) = 
	seq1_uint32s_to_le start len


(* Chacha20 Spec *)

let keylen = 32   (* in bytes *)
let blocklen = 64 (* in bytes *)
let noncelen = 12 (* in bytes *)

type key = lbytes keylen
type block = lbytes blocklen
type nonce = lbytes noncelen
type counter = UInt.uint_t 32

let line (a:idx) (b:idx) (d:idx) (s:t{0 < v s /\ v s < 32}) : chacha_st unit =
  ma <-- read a ;
  mb <-- read b ;
  write a (ma +%^ mb) ;;
  ma <-- read a ;
  md <-- read d ;
  write d ((md ^^ ma) <<< s)

let quarter_round a b c d : chacha_st unit =
  line a b d 16ul ;;
  line c d b 12ul ;;
  line a b d 8ul  ;;
  line c d b 7ul

let column_round : chacha_st unit = 
  quarter_round 0 4 8  12 ;;
  quarter_round 1 5 9  13 ;;
  quarter_round 2 6 10 14 ;;
  quarter_round 3 7 11 15

let diagonal_round : chacha_st unit =
  quarter_round 0 5 10 15 ;;
  quarter_round 1 6 11 12 ;;
  quarter_round 2 7 8  13 ;;
  quarter_round 3 4 9  14

let double_round: chacha_st unit =
    column_round ;; 
    diagonal_round (* 2 rounds *)

let rounds : chacha_st unit =
    iter 10 double_round (* 20 rounds *)
 
let chacha20_core: chacha_st unit = 
    s <-- copy ;
    rounds ;;
    in_place_map2 (+%^) s

(* state initialization *)
let c0 = 0x61707865ul
let c1 = 0x3320646eul
let c2 = 0x79622d32ul
let c3 = 0x6b206574ul

let setup0 (c:counter): chacha_st unit = 
  write 0 c0 ;;
  write 1 c1 ;;
  write 2 c2 ;;
  write 3 c3 ;;
  write 12 (UInt32.uint_to_t c) 

let setup (k:key) (n:nonce) (c:counter): chacha_st unit =
  uint32s_from_le k 4 8 ;; 
  uint32s_from_le n 13 3

let chacha20_block (k:key) (n:nonce) (c:counter): Tot block =
    alloc (
       setup k n c ;;
       chacha20_core ;;
       uint32s_to_le 0 16 
    )

let chacha20_ctx: Spec.CTR.block_cipher_ctx =
    let open Spec.CTR in
    {
    keylen = keylen;
    blocklen = blocklen;
    noncelen = noncelen;
    counterbits = 32;
    incr = 1
    }

let chacha20_block_cipher: Spec.CTR.block_cipher chacha20_ctx = chacha20_block

let chacha20_encrypt_bytes key nonce counter m =
    let chacha20_ctr = Spec.CTR.counter_mode chacha20_ctx chacha20_block_cipher in
    chacha20_ctr key nonce counter m


unfold let test_plaintext = [
    0x4cuy; 0x61uy; 0x64uy; 0x69uy; 0x65uy; 0x73uy; 0x20uy; 0x61uy;
    0x6euy; 0x64uy; 0x20uy; 0x47uy; 0x65uy; 0x6euy; 0x74uy; 0x6cuy;
    0x65uy; 0x6duy; 0x65uy; 0x6euy; 0x20uy; 0x6fuy; 0x66uy; 0x20uy;
    0x74uy; 0x68uy; 0x65uy; 0x20uy; 0x63uy; 0x6cuy; 0x61uy; 0x73uy;
    0x73uy; 0x20uy; 0x6fuy; 0x66uy; 0x20uy; 0x27uy; 0x39uy; 0x39uy;
    0x3auy; 0x20uy; 0x49uy; 0x66uy; 0x20uy; 0x49uy; 0x20uy; 0x63uy;
    0x6fuy; 0x75uy; 0x6cuy; 0x64uy; 0x20uy; 0x6fuy; 0x66uy; 0x66uy;
    0x65uy; 0x72uy; 0x20uy; 0x79uy; 0x6fuy; 0x75uy; 0x20uy; 0x6fuy;
    0x6euy; 0x6cuy; 0x79uy; 0x20uy; 0x6fuy; 0x6euy; 0x65uy; 0x20uy;
    0x74uy; 0x69uy; 0x70uy; 0x20uy; 0x66uy; 0x6fuy; 0x72uy; 0x20uy;
    0x74uy; 0x68uy; 0x65uy; 0x20uy; 0x66uy; 0x75uy; 0x74uy; 0x75uy;
    0x72uy; 0x65uy; 0x2cuy; 0x20uy; 0x73uy; 0x75uy; 0x6euy; 0x73uy;
    0x63uy; 0x72uy; 0x65uy; 0x65uy; 0x6euy; 0x20uy; 0x77uy; 0x6fuy;
    0x75uy; 0x6cuy; 0x64uy; 0x20uy; 0x62uy; 0x65uy; 0x20uy; 0x69uy;
    0x74uy; 0x2euy
]

unfold let test_ciphertext = [
    0x6euy; 0x2euy; 0x35uy; 0x9auy; 0x25uy; 0x68uy; 0xf9uy; 0x80uy;
    0x41uy; 0xbauy; 0x07uy; 0x28uy; 0xdduy; 0x0duy; 0x69uy; 0x81uy;
    0xe9uy; 0x7euy; 0x7auy; 0xecuy; 0x1duy; 0x43uy; 0x60uy; 0xc2uy;
    0x0auy; 0x27uy; 0xafuy; 0xccuy; 0xfduy; 0x9fuy; 0xaeuy; 0x0buy;
    0xf9uy; 0x1buy; 0x65uy; 0xc5uy; 0x52uy; 0x47uy; 0x33uy; 0xabuy;
    0x8fuy; 0x59uy; 0x3duy; 0xabuy; 0xcduy; 0x62uy; 0xb3uy; 0x57uy;
    0x16uy; 0x39uy; 0xd6uy; 0x24uy; 0xe6uy; 0x51uy; 0x52uy; 0xabuy;
    0x8fuy; 0x53uy; 0x0cuy; 0x35uy; 0x9fuy; 0x08uy; 0x61uy; 0xd8uy;
    0x07uy; 0xcauy; 0x0duy; 0xbfuy; 0x50uy; 0x0duy; 0x6auy; 0x61uy;
    0x56uy; 0xa3uy; 0x8euy; 0x08uy; 0x8auy; 0x22uy; 0xb6uy; 0x5euy;
    0x52uy; 0xbcuy; 0x51uy; 0x4duy; 0x16uy; 0xccuy; 0xf8uy; 0x06uy;
    0x81uy; 0x8cuy; 0xe9uy; 0x1auy; 0xb7uy; 0x79uy; 0x37uy; 0x36uy;
    0x5auy; 0xf9uy; 0x0buy; 0xbfuy; 0x74uy; 0xa3uy; 0x5buy; 0xe6uy;
    0xb4uy; 0x0buy; 0x8euy; 0xeduy; 0xf2uy; 0x78uy; 0x5euy; 0x42uy;
    0x87uy; 0x4duy
]

unfold let test_key = [
    0uy;   1uy;  2uy;  3uy;  4uy;  5uy;  6uy;  7uy;
    8uy;   9uy; 10uy; 11uy; 12uy; 13uy; 14uy; 15uy;
    16uy; 17uy; 18uy; 19uy; 20uy; 21uy; 22uy; 23uy;
    24uy; 25uy; 26uy; 27uy; 28uy; 29uy; 30uy; 31uy
    ]
unfold let test_nonce = [
    0uy; 0uy; 0uy; 0uy; 0uy; 0uy; 0uy; 0x4auy; 0uy; 0uy; 0uy; 0uy
    ]

unfold let test_counter = 1

open Seq.Create
let test() =
  assert_norm(List.Tot.length test_plaintext = 114);
  assert_norm(List.Tot.length test_ciphertext = 114);
  assert_norm(List.Tot.length test_key = 32);
  assert_norm(List.Tot.length test_nonce = 12);
  let test_plaintext = createL test_plaintext in
  let test_ciphertext = createL test_ciphertext in
  let test_key = createL test_key in
  let test_nonce = createL test_nonce in
  chacha20_encrypt_bytes test_key test_nonce test_counter test_plaintext
  = test_ciphertext


