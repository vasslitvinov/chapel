/*
 * Copyright 2020-2024 Hewlett Packard Enterprise Development LP
 * Copyright 2004-2019 Cray Inc.
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

#ifndef _CONVERT_UAST_H_
#define _CONVERT_UAST_H_

#include "alist.h"
#include "baseAST.h"
#include "ModuleSymbol.h"

#include "chpl/framework/Context.h"
#include "chpl/framework/ID.h"
#include "chpl/resolution/call-graph.h"
#include "chpl/uast/BuilderResult.h"
#include "chpl/uast/Module.h"
#include "chpl/util/memory.h"

struct Converter;
struct TypedConverter;

// base class for Converter and TypedConverter
class UastConverter {
 public:
  virtual ~UastConverter();

  // these help to know if submodules should be handled.
  // when converting, only convert modules that were added to this set.
  virtual void clearModulesToConvert() = 0;
  virtual void addModuleToConvert(chpl::ID id) = 0;

  // Provide the set of functions that should be converted with full
  // type information.
  // This doesn't do anything for the untyped Converter.
  virtual void
  setFunctionsToConvertWithTypes(chpl::resolution::CalledFnsSet calledFns) = 0;

  // convert a toplevel module
  virtual ModuleSymbol*
  convertToplevelModule(const chpl::uast::Module* mod, ModTag modTag) = 0;

  // convert AST, in an untyped manner
  virtual Expr* convertAST(const chpl::uast::AstNode* node) = 0;

  // apply fixups to fix SymExprs to refer to Symbols that
  // might have been created in a different order.
  virtual void postConvertApplyFixups() = 0;
};

chpl::owned<UastConverter> createUntypedConverter(chpl::Context* context);

chpl::owned<UastConverter> createTypedConverter(chpl::Context* context);


#endif
