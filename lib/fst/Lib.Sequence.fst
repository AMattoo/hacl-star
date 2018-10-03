module Lib.Sequence

open FStar.Mul
open Lib.IntTypes
//open Lib.RawIntTypes

#reset-options "--z3rlimit 300"

let decr (x:size_nat{x > 0}) : size_nat = x - 1
let incr (x:size_nat{x < max_size_t}) : size_nat = x + 1

let seq (a:Type0) =  s:list a {List.Tot.length s <= max_size_t}
let length (#a:Type0) (l:seq a) = List.Tot.length l

let to_lseq #a (s:seq a) = s
let to_seq #a #len (s:lseq a len) = s

val create_: #a:Type -> len:size_nat -> init:a -> Tot (lseq a len) (decreases (len))
let rec create_ #a len x =
  if len = 0 then []
  else
    let t = create_ #a (decr len) x in
    x :: t

val index_: #a:Type -> #len:size_nat{len > 0} -> lseq a len -> n:size_nat{n < len} -> Tot a (decreases (n))
let rec index_ #a #len l i =
  match i, l with
  | 0, h::t -> h
  | n, h::t -> index_ #a #(decr len) t (decr i)

let index #a #len s n = index_ #a #len s n

val upd_: #a:Type -> #len:size_nat -> lseq a len -> n:size_nat{n < len /\ len > 0} -> x:a -> Tot (o:lseq a len{index o n == x}) (decreases (n))
let rec upd_ #a #len l i x =
  match i,l with
  | 0, h::t -> x::t
  | n, h::t -> h::upd_ #a #(decr len) t (decr i) x

let upd #a #len s n x = upd_ #a #len s n x

let create = create_

let createL #a l = l

val prefix_: #a:Type -> #len:size_nat -> lseq a len -> n:size_nat{n <= len} -> Tot (lseq a n) (decreases (n))
let rec prefix_ #a #len l n =
  match n,l with
  | 0, _ -> []
  | n', h::t -> h::prefix_ #a #(decr len) t (decr n)

let prefix #a #len = prefix_ #a #len

val suffix: #a:Type -> #len:size_nat -> lseq a len -> n:size_nat{n <= len} -> Tot (lseq a (len - n)) (decreases (n))
let rec suffix #a #len l n =
  match n,l with
  | 0, _ ->   l
  | _, h::t -> suffix #a #(decr len) t (decr n)

let sub #a #len l s n =
  let suf = suffix #a #len l s in
  prefix #a #(len - s) suf n

val last: #a:Type -> #len:size_nat{len > 0} -> x:lseq a len -> a
let last #a #len x = index #a #len x (decr len)

val snoc: #a:Type -> #len:size_nat{len < maxint U32} -> i:lseq a len -> x:a -> Tot (o:lseq a (incr len){i == prefix #a #(incr len) o len /\ last o == x}) (decreases (len))
let rec snoc #a #len i x =
  match i with
  | [] -> [x]
  | h::t -> h::snoc #a #(decr len) t x

val update_prefix: #a:Type -> #len:size_nat -> lseq a len -> n:size_nat{n <= len} -> x:lseq a n -> Tot (o:lseq a len{sub o 0 n == x}) (decreases (len))
let rec update_prefix #a #len l n l' =
  match n,l,l' with
  | 0, _, _ -> l
  | _, h::t, h'::t' -> h':: update_prefix #a #(decr len) t (decr n) t'

val update_sub_: #a:Type -> #len:size_nat -> lseq a len -> start:size_nat -> n:size_nat{start + n <= len} -> x:lseq a n -> Tot (o:lseq a len{sub o start n == x}) (decreases (len))
let rec update_sub_ #a #len l s n l' =
  match s,l with
  | 0, l -> update_prefix #a #len l n l'
  | _, h::t -> h:: update_sub_ #a #(decr len) t (decr s) n l'

let update_sub = update_sub_

val repeat_range_: #a:Type -> min:size_nat -> max:size_nat{min <= max} -> (s:size_nat{s >= min /\ s < max} -> a -> Tot a) -> a -> Tot (a) (decreases (max - min))
let rec repeat_range_ #a min max f x =
  if min = max then x
  else repeat_range_ #a (incr min) max f (f min x)

val repeat_range_ghost_: #a:Type -> min:size_nat -> max:size_nat{min <= max} -> (s:size_nat{s >= min /\ s < max} -> a -> GTot a) -> a -> GTot (a) (decreases (max - min))
let rec repeat_range_ghost_ #a min max f x =
  if min = max then x
  else repeat_range_ghost_ #a (incr min) max f (f min x)

val repeat_range_all_ml_: #a:Type -> min:size_nat -> max:size_nat{min <= max} -> (s:size_nat{s >= min /\ s < max} -> a -> FStar.All.ML a) -> a -> FStar.All.ML a
let rec repeat_range_all_ml_ #a min max f x =
  if min = max then x
  else repeat_range_all_ml_ #a (incr min) max f (f min x)

let repeat_range = repeat_range_
let repeat_range_ghost = repeat_range_ghost_
let repeat_range_all_ml = repeat_range_all_ml_
let repeati #a = repeat_range #a 0
let repeati_ghost #a = repeat_range_ghost #a 0
let repeati_all_ml #a = repeat_range_all_ml #a 0
let repeat #a n f x = repeat_range 0 n (fun i -> f) x


val fold_left_range_: #a:Type -> #b:Type -> #len:size_nat -> min:size_nat ->
  max:size_nat{min <= max /\ len = max - min} ->
  (i:size_nat{i >= min /\ i < max} -> a -> b -> Tot b) ->
  lseq a len -> b -> Tot b (decreases (max - min))
let rec fold_left_range_ #a #b #len min max f l x =
  match l with
  | [] -> x
  | h::t -> fold_left_range_ #a #b #(len - 1) (min + 1) max f t (f min h x)

let fold_left_range #a #b #len min max f l x =
  fold_left_range_ #a #b #(max - min) min max f (slice #a #len l min max) x

let fold_lefti #a #b #len = fold_left_range #a #b #len 0 len

let fold_left #a #b #len f = fold_left_range #a #b #len 0 len (fun i -> f)

(*
let fold_left_slices #a #b #len #slice_len f l b =
  let n = lin / slice_len in
  repeati #a n (fun i -> let sl = sub #a #len
*)
val map_: #a:Type -> #b:Type -> #len:size_nat -> (a -> Tot b) -> lseq a len -> Tot (lseq b len) (decreases (len))
let rec map_ #a #b #len f x =
  match x with
  | [] -> []
  | h :: t ->
	 let t' : lseq a (decr len) = t in
	 f h :: map_ #a #b #(decr len) f t'
let map = map_


val for_all_: #a:Type -> #len:size_nat -> (a -> Tot bool) -> lseq a len -> Tot bool (decreases (len))
let rec for_all_ #a #len f x =
  match x with
  | [] -> true
  | h :: t ->
	 let t' : lseq a (decr len) = t in
	 f h && for_all_ #a #(decr len) f t'

let for_all = for_all_

val ghost_map_: #a:Type -> #b:Type -> #len:size_nat -> (a -> GTot b) -> lseq a len -> GTot (lseq b len) (decreases (len))
let rec ghost_map_ #a #b #len f x = match x with
  | [] -> []
  | h :: t ->
	 let t' : lseq a (decr len) = t in
	 f h :: ghost_map_ #a #b #(decr len) f t'

let ghost_map = ghost_map_

val map2_: #a:Type -> #b:Type -> #c:Type -> #len:size_nat -> (a -> b -> Tot c) -> lseq a len -> lseq b len -> Tot (lseq c len) (decreases (len))
let rec map2_ #a #b #c #len f x y = match x,y with
  | [],[] -> []
  | h1 :: t1, h2 :: t2 ->
	 let t1' : lseq a (decr len) = t1 in
	 let t2' : lseq b (decr len) = t2 in
	 f h1 h2 :: map2_ #a #b #c #(decr len) f t1' t2'

let map2 = map2_

val for_all2_: #a:Type -> #b:Type -> #len:size_nat -> (a -> b -> Tot bool) -> lseq a len -> lseq b len -> Tot (bool) (decreases (len))
let rec for_all2_ #a #b #len f x y = match x,y with
  | [],[] -> true
  | h1 :: t1, h2 :: t2 ->
	 let t1' : lseq a (decr len) = t1 in
	 let t2' : lseq b (decr len) = t2 in
	 f h1 h2 && for_all2_ #a #b #(decr len) f t1' t2'

let for_all2 = for_all2_


let as_list #a #len l = l


let rec concat #a s1 s2 =
  match s1 with
  | [] -> s2
  | h :: t -> h :: (concat #a t s2)

let map_blocks #a bs nb f inp =
  let len = nb * bs in
  let out = inp in
  let out = repeati #(lseq a len) nb
	    (fun i out ->
	         update_slice #a out (i * bs) ((i+1) * bs)
			      (f i (slice #a inp (i * bs) ((i+1) * bs))))
	    out in
  out

let reduce_blocks #a #b bs nb f inp init =
  let len = nb * bs in
  let acc = init in
  let acc = repeati #b nb
	    (fun i acc ->
	       f i (slice #a inp (i * bs) ((i+1) * bs)) acc)
	    acc in
  acc


(*
#reset-options "--z3rlimit 400 --max_fuel 0"

let reduce_blocks #a #b bs inp f g init =
  let len = length inp in
  let blocks = len / bs in
  let rem = len % bs in
  let acc = repeati #b blocks
	       (fun i acc -> f i (slice (to_lseq inp) (i * bs) ((i+1) * bs)) acc)
	    init in
  let acc = g blocks rem (sub (to_lseq inp) (blocks * bs) rem) acc in
  acc


*)
