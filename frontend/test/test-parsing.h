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

#ifndef TEST_PARSING_H
#define TEST_PARSING_H

#include "test-common.h"

#include <string>

// forward declare classes and namespaces
namespace chpl {
  class Context;
  namespace uast {
    class Module;
  }
  namespace parsing {
  }
  namespace uast {
  }
}

using namespace chpl;
using namespace parsing;
using namespace uast;

// Get the top-level module resulting from parsing the given string.
const Module* parseModule(Context* context, std::string src);

#endif
