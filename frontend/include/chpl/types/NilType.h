/*
 * Copyright 2021-2024 Hewlett Packard Enterprise Development LP
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

#ifndef CHPL_TYPES_NIL_TYPE_H
#define CHPL_TYPES_NIL_TYPE_H

#include "chpl/types/Type.h"

namespace chpl {
namespace types {


/**
  This class represents the type of `nil`.
 */
class NilType final : public Type {
 private:
  NilType() : Type(typetags::NilType) { }

  bool contentsMatchInner(const Type* other) const override {
    return true;
  }

  void markUniqueStringsInner(Context* context) const override {
  }

  Genericity genericity() const override {
    return CONCRETE;
  }

  static const owned<NilType>& getNilType(Context* context);

 public:
  ~NilType() = default;

  static const NilType* get(Context* context);

  void stringify(std::ostream& ss, StringifyKind stringKind) const override;
};


} // end namespace uast
} // end namespace chpl

#endif
