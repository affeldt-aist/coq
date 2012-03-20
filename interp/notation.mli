(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2010     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)

open Errors
open Util
open Pp
open Bigint
open Names
open Nametab
open Libnames
open Glob_term
open Topconstr
open Ppextend

(** Notations *)

(** {6 Scopes } *)
(** A scope is a set of interpreters for symbols + optional
   interpreter and printers for integers + optional delimiters *)

type level = precedence * tolerability list
type delimiters = string
type scope
type scopes (** = [scope_name list] *)

type local_scopes = tmp_scope_name option * scope_name list

val type_scope : scope_name
val declare_scope : scope_name -> unit

val current_scopes : unit -> scopes

(** Check where a scope is opened or not in a scope list, or in
 * the current opened scopes *)
val scope_is_open_in_scopes : scope_name -> scopes -> bool
val scope_is_open : scope_name -> bool

(** Open scope *)

val open_close_scope :
  (** locality *) bool * (* open *) bool * scope_name -> unit

(** Extend a list of scopes *)
val empty_scope_stack : scopes
val push_scope : scope_name -> scopes -> scopes

val find_scope : scope_name -> scope

(** Declare delimiters for printing *)

val declare_delimiters : scope_name -> delimiters -> unit
val find_delimiters_scope : loc -> delimiters -> scope_name

(** {6 Declare and uses back and forth an interpretation of primitive token } *)

(** A numeral interpreter is the pair of an interpreter for **integer**
   numbers in terms and an optional interpreter in pattern, if
   negative numbers are not supported, the interpreter must fail with
   an appropriate error message *)

type notation_location = (dir_path * dir_path) * string
type required_module = full_path * string list
type cases_pattern_status = bool (** true = use prim token in patterns *)

type 'a prim_token_interpreter =
    loc -> 'a -> glob_constr

type 'a prim_token_uninterpreter =
    glob_constr list * (glob_constr -> 'a option) * cases_pattern_status

val declare_numeral_interpreter : scope_name -> required_module ->
  bigint prim_token_interpreter -> bigint prim_token_uninterpreter -> unit

val declare_string_interpreter : scope_name -> required_module ->
  string prim_token_interpreter -> string prim_token_uninterpreter -> unit

(** Return the [term]/[cases_pattern] bound to a primitive token in a
   given scope context*)

val interp_prim_token : loc -> prim_token -> local_scopes ->
  glob_constr * (notation_location * scope_name option)
val interp_prim_token_cases_pattern : loc -> prim_token -> name ->
  local_scopes -> cases_pattern * (notation_location * scope_name option)

(** Return the primitive token associated to a [term]/[cases_pattern];
   raise [No_match] if no such token *)

val uninterp_prim_token :
  glob_constr -> scope_name * prim_token
val uninterp_prim_token_cases_pattern :
  cases_pattern -> name * scope_name * prim_token

val availability_of_prim_token :
  prim_token -> scope_name -> local_scopes -> delimiters option option

(** {6 Declare and interpret back and forth a notation } *)

(** Binds a notation in a given scope to an interpretation *)
type interp_rule =
  | NotationRule of scope_name option * notation
  | SynDefRule of kernel_name

val declare_notation_interpretation : notation -> scope_name option ->
      interpretation -> notation_location -> unit

val declare_uninterpretation : interp_rule -> interpretation -> unit

(** Return the interpretation bound to a notation *)
val interp_notation : loc -> notation -> local_scopes ->
      interpretation * (notation_location * scope_name option)

(** Return the possible notations for a given term *)
val uninterp_notations : glob_constr ->
      (interp_rule * interpretation * int option) list
val uninterp_cases_pattern_notations : cases_pattern ->
      (interp_rule * interpretation * int option) list

(** Test if a notation is available in the scopes 
   context [scopes]; if available, the result is not None; the first 
   argument is itself not None if a delimiters is needed *)
val availability_of_notation : scope_name option * notation -> local_scopes ->
  (scope_name option * delimiters option) option

(** {6 Declare and test the level of a (possibly uninterpreted) notation } *)

val declare_notation_level : notation -> level -> unit
val level_of_notation : notation -> level (** raise [Not_found] if no level *)

(** {6 Miscellaneous} *)

val interp_notation_as_global_reference : loc -> (global_reference -> bool) ->
      notation -> delimiters option -> global_reference

(** Checks for already existing notations *)
val exists_notation_in_scope : scope_name option -> notation ->
      interpretation -> bool

(** Declares and looks for scopes associated to arguments of a global ref *)
val declare_arguments_scope :
  bool (** true=local *) -> global_reference -> scope_name option list -> unit

val find_arguments_scope : global_reference -> scope_name option list

val declare_class_scope : scope_name -> Classops.cl_typ -> unit
val declare_ref_arguments_scope : global_reference -> unit

val compute_arguments_scope : Term.types -> scope_name option list

(** Building notation key *)

type symbol =
  | Terminal of string
  | NonTerminal of identifier
  | SProdList of identifier * symbol list
  | Break of int

val make_notation_key : symbol list -> notation
val decompose_notation_key : notation -> symbol list

(** Prints scopes (expects a pure aconstr printer) *)
val pr_scope : (glob_constr -> std_ppcmds) -> scope_name -> std_ppcmds
val pr_scopes : (glob_constr -> std_ppcmds) -> std_ppcmds
val locate_notation : (glob_constr -> std_ppcmds) -> notation ->
      scope_name option -> std_ppcmds

val pr_visibility: (glob_constr -> std_ppcmds) -> scope_name option -> std_ppcmds

(** {6 Printing rules for notations} *)

(** Declare and look for the printing rule for symbolic notations *)
type unparsing_rule = unparsing list * precedence
val declare_notation_printing_rule : notation -> unparsing_rule -> unit
val find_notation_printing_rule : notation -> unparsing_rule

(** Rem: printing rules for primitive token are canonical *)

val with_notation_protection : ('a -> 'b) -> 'a -> 'b
