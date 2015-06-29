
open CAS.Sugar
open Reaction.Sugar

type 'a status =
  | Waiting
  | Completed of 'a reaction_build
  | WakedUp

(* The thread is suposed to be resumed only once, and when   *)
(* the offer has been completed.                             *)
(* Also, all completed offers should be waken at some point. *)
type 'a t = { state  : 'a status casref ;
              thread : 'a reaction_build Sched.cont }

let is_waiting o = match !(o.state) with
  | Waiting -> true
  | _       -> false


(* completed does not mean waken up *)
let complete_cas o a rx = o.state <:= Waiting --> Completed { rx ; result = a }

let wake o () =
  let s = !(o.state) in
  match s with
  | Completed v when o.state <!= s --> WakedUp
      -> perform (Sched.Resume (o.thread, v))
  | _ -> failwith "Offer.wake: trying to wake a non-completed offer"

let suspend f =
  perform (Sched.Suspend (fun k -> f { state  = ref Waiting ;
                                       thread = k }))

let try_resume o a =
  if o.state <!= Waiting --> Completed a then ( wake o () ; true )
  else false
