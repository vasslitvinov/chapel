/*
 * Copyright 2021-2023 Hewlett Packard Enterprise Development LP
 * Other additional copyright holders may be indicated within.
 *
 * The entirety of this work is licensed under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 *
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

//
// This file defines nearly all the methods exposed to python from the frontend.
//
// To use these definitions, define the macro and then `#include` this file.
// See `chapel.cpp` for examples. If the macros below are not defined, they are
// defined to be empty. Only the ones that are used at the time of include need
// to be defined.
//

//
// Defines the beginning of an ast node
//
#ifndef CLASS_BEGIN
#define CLASS_BEGIN(TAG)
#endif

//
// Defines the end of an ast node
//
#ifndef CLASS_END
#define CLASS_END(TAG)
#endif

//
// Defines a simple getter that takes no arguments
//
// BODY is an inline definition of the getter. Available variables:
// - contextObject: the current frontend context
// - node: the ast node
// TYPESTR is the return type. Possible values:
// - "O" = python object
// - "s" = string, can be a C string, C++ string, or chpl UniqueStr
// - "b" = bool
//
#ifndef PLAIN_GETTER
#define PLAIN_GETTER(NODE, NAME, DOCSTR, TYPESTR, BODY)
#endif

//
// Declares a simple getter that takes no arguments. The definition is expected
// elsewhere in a function named `NODEObject_NAME`. See the `ACTUAL_ITERATOR`
// macro for an example
//
#ifndef METHOD_PROTOTYPE
#define METHOD_PROTOTYPE(NODE, NAME, DOCSTR)
#endif


//
// The order here should be kept in sync with the order in the uast list.
// Not all nodes need methods exposed to python, so not all uast nodes are listed here.
// See list in frontend/include/chpl/uast/uast-classes-list.h.
//
// Inside each method table, methods should be listed in alphabetical order
//

CLASS_BEGIN(AnonFormal)
  PLAIN_GETTER(AnonFormal, intent, "Get the intent for this formal",
               "s", return intentToString(node->intent()))
  PLAIN_GETTER(AnonFormal, type_expression, "Get the type expression for this formal",
               "O", return  wrapAstNode(contextObject, node->typeExpression()))
CLASS_END(AnonFormal)

CLASS_BEGIN(Array)
  PLAIN_GETTER(Array, exprs, "Get the Array exprs",
               "O", return wrapIterPair(contextObject, node->exprs()))
  PLAIN_GETTER(Array, has_trailing_comma, "Check if the Array had a trailing comma",
               "b", return node->hasTrailingComma())
  PLAIN_GETTER(Array, is_associative, "Check if the Array is associative",
               "b", return node->isAssociative())
CLASS_END(Array)

CLASS_BEGIN(Attribute)
  METHOD_PROTOTYPE(Attribute, actuals, "Get the actuals for this Attribute node")
  PLAIN_GETTER(Attribute, name, "Get the name of this Attribute node",
               "s", return node->name())
CLASS_END(Attribute)

CLASS_BEGIN(AttributeGroup)
  PLAIN_GETTER(AttributeGroup, is_unstable, "Check if the attribute group contains the 'unstable' attribute",
               "b", return node->isUnstable())
CLASS_END(AttributeGroup)

CLASS_BEGIN(Break)
  PLAIN_GETTER(Break, target, "Get the target of this Break node",
               "O", return wrapAstNode(contextObject, node->target()))
CLASS_END(Break)

CLASS_BEGIN(Conditional)
  PLAIN_GETTER(Conditional, condition, "Get the condition of this Conditional AST node",
               "O", return wrapAstNode(contextObject, node->condition()))
  PLAIN_GETTER(Conditional, else_block, "Get the else block of this Conditional AST node, or None if no else block",
               "O", return wrapAstNode(contextObject, node->elseBlock()))
  PLAIN_GETTER(Conditional, is_expression_level, "Checks if this Conditional is expression level",
               "b", return node->isExpressionLevel())
  PLAIN_GETTER(Conditional, then_block, "Get the then block of this Conditional AST node",
               "O", return wrapAstNode(contextObject, node->thenBlock()))
CLASS_END(Conditional)

CLASS_BEGIN(Comment)
  PLAIN_GETTER(Comment, text, "Get the text of the Comment node",
               "s", return node->c_str())
CLASS_END(Comment)

CLASS_BEGIN(Continue)
  PLAIN_GETTER(Continue, target, "Get the target of this Continue node",
               "O", return wrapAstNode(contextObject, node->target()))
CLASS_END(Continue)

CLASS_BEGIN(Delete)
  PLAIN_GETTER(Delete, exprs, "Get the exprs of this Delete node",
               "O", return wrapIterPair(contextObject, node->exprs()))
CLASS_END(Delete)

CLASS_BEGIN(Domain)
  PLAIN_GETTER(Domain, exprs, "Get the domain exprs",
               "O", return wrapIterPair(contextObject, node->exprs()))
  PLAIN_GETTER(Domain, used_curly_braces, "Check if the Domain node used curly braces",
               "b", return node->usedCurlyBraces())
CLASS_END(Domain)

CLASS_BEGIN(Dot)
  PLAIN_GETTER(Dot, field, "Get the field accessed in the Dot node",
               "s", return node->field())
  PLAIN_GETTER(Dot, receiver, "Get the receiver of the Dot node",
               "O", return wrapAstNode(contextObject, node->receiver()))
CLASS_END(Dot)

CLASS_BEGIN(FunctionSignature)
  PLAIN_GETTER(FunctionSignature, formals, "Get the formals for this FunctionSignature",
               "O", return wrapIterPair(contextObject, node->formals()))
  PLAIN_GETTER(FunctionSignature, is_parenless, "Check if this FunctionSignature is parenless",
               "b", return node->isParenless())
  PLAIN_GETTER(FunctionSignature, kind, "Get the kind of this FunctionSignature node",
               "s", return chpl::uast::Function::kindToString(node->kind()))
  PLAIN_GETTER(FunctionSignature, return_intent, "Get the return intent of this FunctionSignature",
               "s",  return intentToString(node->returnIntent()))
  PLAIN_GETTER(FunctionSignature, return_type, "Get the return type for this FunctionSignature",
               "O", return wrapAstNode(contextObject, node->returnType()))
  PLAIN_GETTER(FunctionSignature, this_formal, "Get the thisFormal for this FunctionSignature",
               "O", return wrapAstNode(contextObject, node->thisFormal()))
  PLAIN_GETTER(FunctionSignature, throws, "Check if this FunctionSignature is marked throws",
               "b", return node->throws())
CLASS_END(FunctionSignature)

CLASS_BEGIN(Identifier)
  PLAIN_GETTER(Identifier, name, "Get the name of this Identifier node",
               "s", return node->name())
CLASS_END(Identifier)

CLASS_BEGIN(Init)
  PLAIN_GETTER(Init, target, "Get the Init target",
               "O", return wrapAstNode(contextObject, node->target()))
CLASS_END(Init)

CLASS_BEGIN(Label)
  PLAIN_GETTER(Label, loop, "Get the loop of the Label",
               "O", return wrapAstNode(contextObject, node->loop()))
  PLAIN_GETTER(Label, name, "Get the name of the Label",
               "s", return node->name())
CLASS_END(Label)

CLASS_BEGIN(New)
  PLAIN_GETTER(New, management, "Get the management style for this New",
               "s", return chpl::uast::New::managementToString(node->management()))
  PLAIN_GETTER(New, type_expression, "Get the type expression for this New",
               "O", return wrapAstNode(contextObject, node->typeExpression()))
CLASS_END(New)

CLASS_BEGIN(Range)
  PLAIN_GETTER(Range, lower_bound, "Get the lower bound of the Range",
               "O", return wrapAstNode(contextObject, node->lowerBound()))
  PLAIN_GETTER(Range, op_kind, "Get the op kind of this Range node",
               "s", return opKindToString(node->opKind()))
  PLAIN_GETTER(Range, upper_bound, "Get the upper bound of the Range",
               "O", return wrapAstNode(contextObject, node->upperBound()))
CLASS_END(Range)

CLASS_BEGIN(Return)
  PLAIN_GETTER(Return, value, "Get the value of the return",
               "O", return wrapAstNode(contextObject, node->value()))
CLASS_END(Return)

CLASS_BEGIN(Throw)
  PLAIN_GETTER(Throw, error_expression, "Get the error expression of the throw",
               "O", return wrapAstNode(contextObject, node->errorExpression()))
CLASS_END(Throw)

CLASS_BEGIN(VisibilityClause)
  PLAIN_GETTER(VisibilityClause, symbol, "Get the symbol referenced by this VisibilityClause node",
               "O", return wrapAstNode(contextObject, node->symbol()))
CLASS_END(VisibilityClause)

CLASS_BEGIN(WithClause)
  PLAIN_GETTER(WithClause, exprs, "Get the exprs of this WithClause node",
               "O", return wrapIterPair(contextObject, node->exprs()))
CLASS_END(WithClause)

CLASS_BEGIN(Yield)
  PLAIN_GETTER(Yield, value, "Get the value of the yield",
               "O", return wrapAstNode(contextObject, node->value()))
CLASS_END(Yield)

CLASS_BEGIN(START_SimpleBlockLike)
  PLAIN_GETTER(SimpleBlockLike, block_style, "Get the style of this block-like AST node",
               "s", return blockStyleToString(node->blockStyle()))
CLASS_END(START_SimpleBlockLike)

CLASS_BEGIN(Begin)
  PLAIN_GETTER(Begin, with_clause, "Get the with clause of this Begin node",
               "O", return wrapAstNode(contextObject, node->withClause()))
CLASS_END(Begin)

CLASS_BEGIN(Local)
  PLAIN_GETTER(Local, condition, "Get the condition of the Local",
               "O", return wrapAstNode(contextObject, node->condition()))
CLASS_END(Local)

CLASS_BEGIN(On)
  PLAIN_GETTER(On, destination, "Get the destination of the On",
               "O", return wrapAstNode(contextObject, node->destination()))
CLASS_END(On)

CLASS_BEGIN(Serial)
  PLAIN_GETTER(Serial, condition, "Get the condition of the Serial",
               "O", return wrapAstNode(contextObject, node->condition()))
CLASS_END(Serial)

CLASS_BEGIN(START_Loop)
  PLAIN_GETTER(Loop, block_style, "Get the style of this loop AST node",
               "s", return blockStyleToString(node->blockStyle()))
  PLAIN_GETTER(Loop, body, "Get the body of this loop AST node",
               "O", return wrapAstNode(contextObject, node->body()))
CLASS_END(START_Loop)

CLASS_BEGIN(DoWhile)
  PLAIN_GETTER(DoWhile, condition, "Get the condition of this loop AST node",
               "O", return wrapAstNode(contextObject, node->condition()))
CLASS_END(DoWhile)

CLASS_BEGIN(While)
  PLAIN_GETTER(While, condition, "Get the condition of this loop AST node",
               "O", return wrapAstNode(contextObject, node->condition()))
CLASS_END(While)

CLASS_BEGIN(START_IndexableLoop)
  PLAIN_GETTER(IndexableLoop, index, "Get the index of this loop AST node",
               "O", return wrapAstNode(contextObject, node->index()))
  PLAIN_GETTER(IndexableLoop, is_expression_level, "Check if loop is expression level",
               "b", return node->isExpressionLevel())
  PLAIN_GETTER(IndexableLoop, iterand, "Get the iterand of this loop AST node",
               "O", return wrapAstNode(contextObject, node->iterand()))
  PLAIN_GETTER(IndexableLoop, with_clause, "Get the with clause of this loop node",
               "O", return wrapAstNode(contextObject, node->withClause()))
CLASS_END(START_IndexableLoop)

CLASS_BEGIN(BracketLoop)
  PLAIN_GETTER(BracketLoop, is_maybe_array_type, "Check if a bracket loop is actually a type",
               "b", return node->isMaybeArrayType())
CLASS_END(BracketLoop)

CLASS_BEGIN(For)
  PLAIN_GETTER(For, is_param, "Check if loop is a param for loop",
               "b", return node->isParam())
CLASS_END(For)

CLASS_BEGIN(BoolLiteral)
  PLAIN_GETTER(BoolLiteral, value, "Get the value of the BoolLiteral node",
               "s", return (node->value() ? "true" : "false"))
CLASS_END(BoolLiteral)

CLASS_BEGIN(ImagLiteral)
  PLAIN_GETTER(ImagLiteral, text, "Get the value of the ImagLiteral node",
               "s", return node->text())
CLASS_END(ImagLiteral)

CLASS_BEGIN(IntLiteral)
  PLAIN_GETTER(IntLiteral, text, "Get the value of the IntLiteral node",
               "s", return node->text())
CLASS_END(IntLiteral)

CLASS_BEGIN(RealLiteral)
  PLAIN_GETTER(RealLiteral, text, "Get the value of the RealLiteral node",
               "s", return node->text())
CLASS_END(RealLiteral)

CLASS_BEGIN(UintLiteral)
  PLAIN_GETTER(UintLiteral, text, "Get the value of the UintLiteral node",
               "s", return node->text())
CLASS_END(UintLiteral)

CLASS_BEGIN(START_StringLikeLiteral)
  PLAIN_GETTER(StringLikeLiteral, value, "Get the value of the StringLikeLiteral node",
               "s", return node->value())
CLASS_END(START_StringLikeLiteral)

CLASS_BEGIN(START_Call)
  PLAIN_GETTER(Call, actuals, "Get the arguments to this Call node",
               "O", return wrapIterPair(contextObject, node->actuals()))
  PLAIN_GETTER(Call, called_expression, "Get the expression invoked by this Call node",
               "O", return wrapAstNode(contextObject, node->calledExpression()))
CLASS_END(START_Call)

CLASS_BEGIN(FnCall)
  // actuals defined elsewhere, this call overrides the one in START_Call
  METHOD_PROTOTYPE(FnCall, actuals, "Get the actuals of this function call")
  PLAIN_GETTER(FnCall, used_square_brackets, "Check whether or not this function call was made using square brackets",
               "b", return node->callUsedSquareBrackets())
CLASS_END(FnCall)

CLASS_BEGIN(OpCall)
  PLAIN_GETTER(OpCall, is_binary_op, "Check if this OpCall is a binary op",
               "b", return node->isBinaryOp())
  PLAIN_GETTER(OpCall, is_unary_op, "Check if this OpCall is an unary op",
               "b", return node->isUnaryOp())
  PLAIN_GETTER(OpCall, op, "Get the op string for this OpCall",
               "s", return node->op())
CLASS_END(OpCall)

CLASS_BEGIN(Reduce)
  PLAIN_GETTER(Reduce, iterand, "Get the iterand AST node",
               "O", return wrapAstNode(contextObject, node->iterand()))
  PLAIN_GETTER(Reduce, op, "Get the op AST node",
               "O", return wrapAstNode(contextObject, node->op()))
CLASS_END(Reduce)

CLASS_BEGIN(START_Decl)
  PLAIN_GETTER(Decl, linkage, "Get the linkage of this VarLikeDecl node",
               "s", return chpl::uast::Decl::linkageToString(node->linkage()))
  PLAIN_GETTER(Decl, linkage_name, "Get the linkage name of this VarLikeDecl node",
               "O", return wrapAstNode(contextObject, node->linkageName()))
  PLAIN_GETTER(Decl, visibility, "Get the visibility of this VarLikeDecl node",
               "s", return chpl::uast::Decl::visibilityToString(node->visibility()))
CLASS_END(START_Decl)

CLASS_BEGIN(TupleDecl)
  PLAIN_GETTER(TupleDecl, decls, "Get the decls for this ast",
               "O", return wrapIterPair(contextObject, node->decls()))
  PLAIN_GETTER(TupleDecl, init_expression, "Get the init expression of this ast",
               "O", return wrapAstNode(contextObject, node->typeExpression()))
  PLAIN_GETTER(TupleDecl, intent_or_kind, "Get the intent or kind of this ast",
               "s", return chpl::uast::TupleDecl::intentOrKindToString(node->intentOrKind()))
  PLAIN_GETTER(TupleDecl, type_expression, "Get the type expression of this ast",
               "O", return wrapAstNode(contextObject, node->initExpression()))
CLASS_END(TupleDecl)

CLASS_BEGIN(START_NamedDecl)
  PLAIN_GETTER(NamedDecl, name, "Get the name of this NamedDecl node",
               "s", return node->name())
CLASS_END(START_NamedDecl)

CLASS_BEGIN(EnumElement)
  PLAIN_GETTER(EnumElement, init_expression, "Get the initExpression of this enum element AST node",
               "O", return wrapAstNode(contextObject, node->initExpression()))
CLASS_END(EnumElement)

CLASS_BEGIN(Function)
  PLAIN_GETTER(Function, formals, "Get the formals for this function",
               "O", return wrapIterPair(contextObject, node->formals()))
  PLAIN_GETTER(Function, body, "Get the body for this function",
               "O", return wrapAstNode(contextObject, node->body()))
  PLAIN_GETTER(Function, is_anonymous, "Check if this function is anonymous",
               "b", return node->isAnonymous())
  PLAIN_GETTER(Function, is_inline, "Check if this function is marked inline",
               "b", return node->isInline())
  PLAIN_GETTER(Function, is_method, "Check if this function is a method",
               "b", return node->isMethod())
  PLAIN_GETTER(Function, is_override, "Check if this function is an override",
               "b", return node->isOverride())
  PLAIN_GETTER(Function, is_parenless, "Check if this function is parenless",
               "b", return node->isParenless())
  PLAIN_GETTER(Function, is_primary_method, "Check if this function is a primary method",
               "b", return node->isPrimaryMethod())
  PLAIN_GETTER(Function, kind, "Get the kind of this Function node",
               "s", return chpl::uast::Function::kindToString(node->kind()))
  PLAIN_GETTER(Function, lifetime_clauses, "Get the lifetime clauses for this function",
               "O", return wrapIterPair(contextObject, node->lifetimeClauses()))
  PLAIN_GETTER(Function, return_intent, "Get the return intent of this function",
               "s",  return intentToString(node->returnIntent()))
  PLAIN_GETTER(Function, return_type, "Get the return type for this function",
               "O", return wrapAstNode(contextObject, node->returnType()))
  PLAIN_GETTER(Function, this_formal, "Get the thisFormal for this function",
               "O", return wrapAstNode(contextObject, node->thisFormal()))
  PLAIN_GETTER(Function, throws, "Check if this function is marked throws",
               "b", return node->throws())
  PLAIN_GETTER(Function, where_clause, "Get the where clause for this function",
               "O", return wrapAstNode(contextObject, node->whereClause()))
CLASS_END(Function)

CLASS_BEGIN(Module)
  PLAIN_GETTER(Module, kind, "Get the kind of this module",
               "s", return chpl::uast::Module::moduleKindToString(node->kind()))
CLASS_END(Module)

CLASS_BEGIN(ReduceIntent)
  PLAIN_GETTER(ReduceIntent, op, "Get the op AST node",
               "O", return wrapAstNode(contextObject, node->op()))
CLASS_END(ReduceIntent)

CLASS_BEGIN(START_VarLikeDecl)
  PLAIN_GETTER(VarLikeDecl, init_expression, "Get the init expression of this VarLikeDecl node",
               "O", return  wrapAstNode(contextObject, node->initExpression()))
  PLAIN_GETTER(VarLikeDecl, storage_kind, "Get the storage kind of this VarLikeDecl node",
               "s", return chpl::uast::qualifierToString(node->storageKind()))
  PLAIN_GETTER(VarLikeDecl, type_expression, "Get the type expression of this VarLikeDecl node",
               "O", return wrapAstNode(contextObject, node->typeExpression()))
CLASS_END(START_VarLikeDecl)

CLASS_BEGIN(Formal)
  PLAIN_GETTER(Formal, intent, "Get the intent for this formal",
               "s", return intentToString(node->intent()))
CLASS_END(Formal)

CLASS_BEGIN(TaskVar)
  PLAIN_GETTER(TaskVar, intent, "Get the intent of the task variable",
               "s", return intentToString(node->intent()))
CLASS_END(TaskVar)

CLASS_BEGIN(Variable)
  PLAIN_GETTER(Variable, is_config, "Check if the given Variable node is a config variable",
               "b", return node->isConfig())
  PLAIN_GETTER(Variable, is_field, "Check if the given Variable node is a class field variable",
               "b", return node->isField())
  PLAIN_GETTER(Variable, kind, "Get the  kind of this Variable node",
               "s", return chpl::uast::qualifierToString(node->storageKind()))
CLASS_END(Variable)

CLASS_BEGIN(START_AggregateDecl)
  PLAIN_GETTER(AggregateDecl, decls_or_comments, "Get the decls and comments of this AggregateDecl node",
               "O", return wrapIterPair(contextObject, node->declOrComments()))
CLASS_END(START_AggregateDecl)

CLASS_BEGIN(Class)
  PLAIN_GETTER(Class, inherit_exprs, "Get the inherit expressions of this class AST node",
               "O", return wrapIterPair(contextObject, node->inheritExprs()))
CLASS_END(Class)

CLASS_BEGIN(Record)
  PLAIN_GETTER(Record, interface_exprs, "Get the interface expressions of this record AST node",
               "O", return wrapIterPair(contextObject, node->interfaceExprs()))
CLASS_END(Record)

//
// Cleanup and undefine all macros
//
#undef CLASS_BEGIN
#undef CLASS_END
#undef PLAIN_GETTER
#undef METHOD_PROTOTYPE
