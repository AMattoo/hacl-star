open Chacha
open Char
open Hacl_SBuffer
open Hacl_Cast
       
let key = {content = Array.init 32 (fun x -> (Hacl_UInt8.of_string (string_of_int x))); idx = 0; length = 32 }
    
let nonce =
  let n = create (Hacl_UInt8.of_string "0") 12 in
  upd n 7 (Hacl_UInt8.of_string "0x4a");
  n

let counter = Hacl_UInt32.of_int (Prims.parse_int "1")

let from_string s =
  let b = create (Hacl_UInt8.of_string "0") (String.length s) in
  for i = 0 to (String.length s - 1) do
    upd b i (Hacl_UInt8.of_string (string_of_int (code (String.get s i))))
  done;
  b
                
let print (b:bytes) =
  let s = ref "" in
  for i = 0 to b.length - 1 do
    let s' = Printf.sprintf "%X" (int_of_string (Hacl_UInt8.to_string (index b i)))  in
    let s' = if String.length s' = 1 then "0" ^ s' else s' in 
    s := !s ^ s';
  done;
  !s

let max x y =
  if x > y then x else y
   
let print_array (a) =
  let s = ref "" in
  for i = 0 to a.length - 1 do
    let s' = Printf.sprintf "%X" (index a i)  in
    let s' = String.init (max (8 - String.length s') 0) (fun x -> '0')  ^ s' in
    let s' = if i mod 4 = 3 then s' ^ "\n" else s' ^ " " in
    s := !s ^ s';
  done;
  print_string !s; print_string "\n"

let print_bytes b =
  print_string (print b); print_string "\n"

let plaintext = from_string "Ladies and Gentlemen of the class of '99: If I could offer you only one tip for the future, sunscreen would be it."
                            
let expected = "  000  6e 2e 35 9a 25 68 f9 80 41 ba 07 28 dd 0d 69 81  n.5.%h..A..(..i.
  016  e9 7e 7a ec 1d 43 60 c2 0a 27 af cc fd 9f ae 0b  .~z..C`..'......
  032  f9 1b 65 c5 52 47 33 ab 8f 59 3d ab cd 62 b3 57  ..e.RG3..Y=..b.W
  048  16 39 d6 24 e6 51 52 ab 8f 53 0c 35 9f 08 61 d8  .9.$.QR..S.5..a.
  064  07 ca 0d bf 50 0d 6a 61 56 a3 8e 08 8a 22 b6 5e  ....P.jaV....\".^
  080  52 bc 51 4d 16 cc f8 06 81 8c e9 1a b7 79 37 36  R.QM.........y76
  096  5a f9 0b bf 74 a3 5b e6 b4 0b 8e ed f2 78 5e 42  Z...t.[......x^B
  112  87 4d\n"

let _ =
  let ciphertext = create (uint8_to_sint8 0) 114 in
  chacha20_encrypt ciphertext key counter nonce plaintext 114;
  print_string "Test key:\n";
  print_bytes key;
  print_string "Test nonce:\n";
  print_bytes nonce;
  print_string "Expected ciphertext:\n";
  print_string expected;
  print_string "Got ciphertext:\n";
  print_bytes ciphertext;
  let ok = "6e2e359a2568f98041ba0728dd0d6981e97e7aec1d4360c20a27afccfd9fae0bf91b65c5524733ab8f593dabcd62b3571639d624e65152ab8f530c359f0861d807ca0dbf500d6a6156a38e088a22b65e52bc514d16ccf806818ce91ab77937365af90bbf74a35be6b40b8eedf2785e42874d" in
  for i = 0 to 113 do
    if not(Hacl_UInt8.to_string_hex (index ciphertext i) = String.sub ok (2*i) 2) then
      failwith (Printf.sprintf "Ciphertext differs at byte %d: %s %s\n" i (Hacl_UInt8.to_string_hex (index ciphertext i)) (String.sub ok (2*i) 2)) 
  done
