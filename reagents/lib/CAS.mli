
type 'a ref

type 'a updt = { expect : 'a ; update : 'a }

type t

val ref : 'a -> 'a ref

val get : 'a ref -> 'a

val docas : 'a ref -> 'a updt -> bool

val build : 'a ref -> 'a updt -> t

val commit : t -> bool

val kCAS : t list -> bool

module Sugar : sig
  type 'a casupdt = 'a updt
  type 'a casref = 'a ref
  val ref : 'a -> 'a casref
  val (!) : 'a casref -> 'a
  val (-->) : 'a -> 'a -> 'a casupdt
  val (<!=) : 'a casref -> 'a casupdt -> bool
  val (<:=) : 'a casref -> 'a casupdt -> t
end
