#!/bin/sh

# Check for input file
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <filename>"
    exit 1
fi

filename=$(basename "$1" .cpp)

# Add header
cat <<EOT > "$filename.new"
#include "witness/include/witness.h"
#include "witness/src/generate.rs.h"

/// We need this accessor since cxx doesn't support hashmaps yet
class IOSignalInfoAccessor {
private:
  Circom_CalcWit *calcWitContext;

public:
  explicit IOSignalInfoAccessor(Circom_CalcWit *calcWit)
      : calcWitContext(calcWit) {}
  auto operator[](size_t index) const -> decltype(auto) {
    return (calcWitContext
                ->templateInsId2IOSignalInfoList)[index % get_size_of_input_hashmap()];
  }
};

typedef void (*Circom_TemplateFunction)(uint __cIdx, Circom_CalcWit* __ctx);

//////////////////////////////////////////////////////////////////
/// Generated code from circom compiler below
//////////////////////////////////////////////////////////////////

EOT

# Replace a few things we can't do in cxx
sed -e 's/FrElement\* signalValues/rust::Vec<FrElement> \&signalValues/g' \
-e 's/std::string/rust::string/g' \
-e 's/ctx->templateInsId2IOSignalInfo/IOSignalInfoAccessor(ctx)/g' \
-e 's/u32\* mySubcomponents/rust::Vec<u32> mySubcomponents/g' \
-e 's/FrElement\* circuitConstants/rust::Vec<FrElement> \&circuitConstants/g' \
-e 's/rust::string\* listOfTemplateMessages/rust::Vec<rust::string> \&listOfTemplateMessages/g' \
-e 's/FrElement expaux\[\([0-9]*\)\];/rust::Vec<FrElement> expaux = create_vec(\1);/g' \
-e 's/FrElement lvar\[\([0-9]*\)\];/rust::Vec<FrElement> lvar = create_vec(\1);/g' \
-e 's/FrElement lvarcall\[\([0-9]*\)\];/rust::Vec<FrElement> lvarcall = create_vec(\1);/g' \
-e 's/PFrElement aux_dest/FrElement \*aux_dest/g' \
-e 's/subcomponents = new uint\[\([0-9]*\)\];/subcomponents = create_vec_u32(\1);/g' \
-e '/trace/d' \
-e 's/\(ctx,\)\(lvarcall,\)\(myId,\)/\1\&\2\3/g' \
-e '/^#include/d' \
-e '/assert/d' \
-e '/mySubcomponentsParallel/d' \
-e 's/FrElement lvarcall\[\([0-9]*\)\];/rust::Vec<FrElement> lvarcall = create_vec(\1);/g' \
-e 's/,FrElement\* lvar,/,rust::Vec<FrElement>\& lvar,/g' \
-e 's/ctx,\&lvarcall,myId,/ctx,lvarcall,myId,/g' \
-e '/delete \[\][^;]*;/d' -e 'N;/\ndelete/!P;D' \
-e '/^#include/d' "$1" >> "$filename.new"

sed -E -e 's/"([^"]+)"\+ctx->generate_position_array\(([^)]+)\)/generate_position_array("\1", \2)/g' \
-e 's/subcomponents = new uint\[([0-9]+)\]\{0\};/subcomponents = create_vec_u32(\1);/g' \
-e 's/^uint aux_dimensions\[([0-9]+)\] = \{([^}]+)\};$/rust::Vec<uint> aux_dimensions = rust::Vec<uint32_t>{\2};/' "$filename.new" > "src/circuit.cc"

file_path="src/circuit.cc"
tmp_file=$(mktemp)

# Initialize an empty array to act as the stack
# stack=()

# # Function to push an element onto the stack
# push() {
#     stack+=("$1")
#     echo "Pushed $1 onto the stack"
# }

# # Function to pop an element from the stack
# pop() {
#     if [ ${#stack[@]} -eq 0 ]; then
#         echo "Error: Stack is empty"
#     else
#         top_index=$((${#stack[@]} - 1))  # Get the index of the top element
#         popped_element="${stack[$top_index]}"  # Get the top element of the stack
#         unset 'stack[$top_index]'             # Remove the top element from the stack
#         echo "$popped_element"
#     fi
# }

# # Read the file line by line
# while IFS= read -r line; do

#     if [[ "$line" == *'if('* ]]; then
#         # Capture the statement
#         STATEMENT="${line#if(}"
#         push "$STATEMENT"
#         echo "$line" >> "$tmp_file"
#         elif [[ "$line" == *'}else{'* ]]; then
#         # Pop the last element from stack
#         STATEMENT=$(pop)
#         if [[ "$STATEMENT" == *'Fr_isTrue'* ]]; then
#             # Replace 'else' with the captured STATEMENT
#             echo "}if(!$STATEMENT" >> "$tmp_file"
#         else
#             echo "$line" >> $tmp_file
#         fi

#     else
#         echo "$line" >> "$tmp_file"
#         # Output the original line
#     fi
# done < "src/circuit.cc"

# # Overwrite the original file with the modified content
# mv "$tmp_file" "$file_path"

# # Remove the temporary file
# rm -f "$tmp_file"

cp "$(echo $filename)_cpp/$filename.dat" src/constants.dat
