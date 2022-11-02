/*
 * Copyright 2021-2022 Hewlett Packard Enterprise Development LP
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

#ifndef VAR_SCOPE_VISITOR_H
#define VAR_SCOPE_VISITOR_H

#include "chpl/framework/ID.h"
#include "chpl/resolution/ResolvedVisitor.h"

namespace chpl {
namespace uast {
  class AstNode;
  class Conditional;
  class FnCall;
  class Identifier;
  class OpCall;
  class Return;
  class Throw;
  class Try;
}
namespace types {
  class QualifiedType;
}

namespace resolution {

struct VarFrame;
struct ControlFlowSubBlock;

/** Helper visitor for traversals that work with variable
    init and deinit. This class is intended to factor out code
    common between 3 analysis:
     * split init
     * copy elision
     * computing where copies and deinits occur

    Since it is only used internally for these cases,
    the interface covers whatever these analyses need. */
class VarScopeVisitor {
 protected:
  using RV = ResolvedVisitor<VarScopeVisitor>;

  // ----- inputs to the process
  Context* context = nullptr;


  // ----- internal variables
  std::vector<owned<VarFrame>> scopeStack;


  // ----- methods to be implemented by specific analysis subclass

  /** Called for a variable declaration */
  virtual void handleDeclaration(const uast::VarLikeDecl* ast, RV& rv) = 0;
  /** Called for an Identifier not used in one of the below cases */
  virtual void handleMention(const uast::Identifier* ast, ID varId, RV& rv) = 0;
  /** Called for Identifier = <expr> assignment pattern */
  virtual void handleVarAssign(const uast::OpCall* ast, ID varId, RV& rv) = 0;
  /** Called for an actual passed to an 'out' formal */
  virtual void handleOutFormal(const uast::FnCall* ast,
                               const uast::AstNode* actual,
                               const types::QualifiedType& formalType, RV& rv) = 0;
  /** Called for an actual passed to an 'in' formal */
  virtual void handleInFormal(const uast::FnCall* ast,
                              const uast::AstNode* actual,
                              const types::QualifiedType& formalType,
                              RV& rv) = 0;
  /** Called for an actual passed to an 'out' formal */
  virtual void handleInoutFormal(const uast::FnCall* ast,
                                 const uast::AstNode* actual,
                                 const types::QualifiedType& formalType,
                                 RV& rv) = 0;
 
  /** Called to process a Conditional after handling its contents --
      should update currentFrame() which is the frame for the Conditional.
      The then/else frames are sitting in currentFrame().subBlocks. */
  virtual void handleConditional(const uast::Conditional* cond) = 0;
  /** Called to process a Try after handling its contents --
      should update currentFrame() which is the frame for the Try.
      The catch clause frames are sitting in currentFrame().subBlocks. */
  virtual void handleTry(const uast::Try* t) = 0;
  /** Called to process any other Scope after handling its contents --
      should update scopeStack.back() which is the frame for the Try.
      Not called for Conditional or Try. */
  virtual void handleScope(const uast::AstNode* ast) = 0;


  // ----- methods for use by specific analysis subclasses

  VarScopeVisitor(Context* context) : context(context), scopeStack() { }

 public:
  void process(const uast::AstNode* symbol,
               const ResolutionResultByPostorderID& byPostorder);

 protected:

  /** Return the current frame. This should always be safe to call
      from one of the handle* methods. */
  VarFrame* currentFrame() {
    assert(!scopeStack.empty());
    return scopeStack.back().get();
  }

  /** If ast is an Identifier that refers to a VarLikeDecl, return the
      Id of the VarLikeDecl. Otherwise, return an empty ID. */
  ID refersToId(const AstNode* ast, RV& rv);

  /** Call handleMention for any Identifiers contained in this ast node.
      Only appropriate for expressions (not for Loops) */
  void handleMentions(const AstNode* ast, RV& rv);

 public:
  // ----- visitor implementation
  void enterScope(const uast::AstNode* ast);
  void exitScope(const uast::AstNode* ast);

  bool enter(const VarLikeDecl* ast, RV& rv);
  void exit(const VarLikeDecl* ast, RV& rv);

  bool enter(const OpCall* ast, RV& rv);
  void exit(const OpCall* ast, RV& rv);

  bool enter(const FnCall* ast, RV& rv);
  void exit(const FnCall* ast, RV& rv);

  bool enter(const Return* ast, RV& rv);
  void exit(const Return* ast, RV& rv);

  bool enter(const Throw* ast, RV& rv);
  void exit(const Throw* ast, RV& rv);

  bool enter(const Identifier* ast, RV& rv);
  void exit(const Identifier* ast, RV& rv);

  bool enter(const uast::AstNode* node, RV& rv);
  void exit(const uast::AstNode* node, RV& rv);
};

/** Collects information about a Conditional's then/else blocks
    or a Try's Catch blocks. */
struct ControlFlowSubBlock {
  const AstNode* block = nullptr; // then block / else block / catch block
  owned<VarFrame> frame;
  ControlFlowSubBlock(const AstNode* block) : block(block) { }
};

/** Collects information about a variable declaration frame / scope.
    Note that some of the fields here will only be used by a single subclass.
    Keeping them declared here keeps things simple. */
struct VarFrame {
  // ----- variables used by VarScopeVisitor
  const AstNode* scopeAst = nullptr; // for debugging

  // Which variables are declared in this scope?
  // For split init, only variables without init expressions.
  std::set<ID> declaredVars;

  // Which variables are initialized in this scope?
  // This includes both locally declared and outer variables.
  std::set<ID> initedVars;

  // has the block already encountered a return?
  bool returns = false;

  // has the block already encountered a throw?
  bool throws = false;

  // When processing a conditional or catch blocks,
  // instead of popping the SplitInitFrame for the then/else/catch blocks,
  // store them here, for use in handleExitScope(Conditional or Try).
  std::vector<ControlFlowSubBlock> subBlocks;


  // ----- variables declared here for use in particular subclasses

  // for split init:

  // which variables are declared here in a way that allows split init?
  std::set<ID> eligibleVars;
  // same as initedVars but preserves order & saves types
  std::vector<std::pair<ID, types::QualifiedType>> initedVarsVec;
  // Which variables are mentioned in this scope before
  // being initialized, throwing or returning?
  std::set<ID> mentionedVars;

  VarFrame(const AstNode* scopeAst) : scopeAst(scopeAst) { }

  // returns 'true' if it was inserted
  bool addToDeclaredVars(ID varId);
  // returns 'true' if it was inserted
  bool addToInitedVars(ID varId);
};

/**
  Compute a vector indicating which actuals are passed to an 'out'/'in'/'inout'
  formal in all return intent overloads. For each actual 'i',
  actualFormalIntent[i] will be set to one of the following:
   * uast::IntentList::OUT if it is passed to an 'out' formal
   * uast::IntentList::IN if it is passed to an 'in' or 'const in' formal
   * uast::IntentList::INOUT if it is passed to an 'inout' formal
   * uast::IntentList::UNKNOWN otherwise

  actualFormalTypes will be set so that for actual 'i', if it is passed
  to an 'out'/'in'/'inout' formal, actualFormalTypes[i] will be set to the
  type of the 'out'/'in'/'inout' formal.

  If either of the above computed values do not match among
  the return intent overloads, this function will issue an error
  in the current query.
 */
void
computeActualFormalIntents(Context* context,
                           const MostSpecificCandidates& candidates,
                           const CallInfo& ci,
                           const std::vector<const AstNode*>& actualAsts,
                           std::vector<uast::IntentList>& actualFrmlIntents,
                           std::vector<types::QualifiedType>& actualFrmlTypes);

} // end namespace resolution
} // end namespace chpl

#endif
