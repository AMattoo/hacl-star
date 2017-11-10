module Flag

module ST = FStar.HyperStack.ST

open FStar.HyperStack.All
open Crypto.Indexing

(* Settings *all* flags to false, for extracting real implementation *) 

inline_for_extraction let cipher_prf  a = false 
inline_for_extraction let mac_log       = false
inline_for_extraction let mac_int1cma a = false 
inline_for_extraction let prf_cpa       = false  
inline_for_extraction let safeHS      i = false 
inline_for_extraction let safeId      i = false 
inline_for_extraction let mac1_implies_mac_log i = ()
inline_for_extraction let mac1_implies_prf     i = ()
inline_for_extraction let safeId_implies_mac1  i = ()
inline_for_extraction let safeId_implies_cpa   i = ()
inline_for_extraction let aes_ct        = false
