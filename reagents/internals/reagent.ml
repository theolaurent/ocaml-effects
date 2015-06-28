
type ('a, 'b) t = {
    tryReact : 'a -> Reaction.t -> 'b Offer.t option -> 'b option ; (* None stands for Block *)
    compose : 'c . ('b, 'c) t -> ('a, 'c) t ;
  }

(* for the moment just try without and then with offer; cf scala implem (canSync...) *)


let run r a =
  match r.tryReact a Reaction.inert None with
  (* for now, no retry, cf scala code *)
  | None -> perform (Sched.Suspend (fun k -> ignore (r.tryReact a Reaction.inert (Some (Offer.make k)))))
  | Some x -> x


let commit : ('a, 'a) t =
  let tryReact a rx offer = match offer with
    | Some o when Offer.try_complete o a
        -> failwith ".........."
    | _ -> if Reaction.try_commit rx then
             Some a
           else failwith "Reagent.commit: that shouldn't happen yet, no parallelism."
  in
  let compose (type b) (r:('a, b) t) = r
  in { tryReact ; compose }

(*
let rec never () =
  let tryReact a rx offer =
    None
  in
(*let compose (type c) (r:(u, c) t) = never () *)
(*in { tryReact ; compose } *)
  let compose = (fun _ -> never ())
  in { tryReact ; compose = Obj.magic compose }
*)

let pipe r1 r2 = r1.compose r2

let rec choice (r1:('a, 'b) t) (r2:('a, 'b) t) =
  let tryReact a rx offer =
    match r1.tryReact a rx offer with
    | None -> r2.tryReact a rx offer
    | Some x -> Some x
  in
(*let compose (type c) (r:('b, c) t) = *)
(*  (* hmm what is this case Choice thing in the scala code? *) *)
(*  choice (r1.compose r) (r2.compose r) *)
(*in { tryReact ; compose } *)
  let compose = (fun r -> choice (r1.compose r) (r2.compose r))
  in { tryReact ; compose = Obj.magic compose }

(* TODO: post commit => what is this auto cont thing? *)

(* moved from offer.ml to avoid circular dependencies *)
let comsume_and_continue o complete_with continue_with rx k enclosing_offer =
  (* forgetting the immediate CAS for now; cf scala implem *)
  let new_rx = Reaction.add_pc (Offer.rx_with_completion o rx complete_with)
                               (Offer.wake o) in
  (* for now, only blocking ones; cf scala implem *)
  k.tryReact continue_with new_rx enclosing_offer
