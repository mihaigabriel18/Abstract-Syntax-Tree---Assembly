# Abstract Abstract Syntax Tree

Name and Surname: MIHAI-GABRIEL CALITESCU

Group and Series: 321CB

Detailed descriptions of _iocla\_atoi_ and _create\_tree_ functions are
presented below.

## iocla_atoi:

The function reads character with character from the string given input and 
builds in eax a new integer the same one given input.

We start by checking if the number is negative, storing the boolean value
in _is\_negative\_atoi_, knowing if we should make the number negative at the end.

The algorithm is simple: loop for every byte in the string paramter, until the
value from iterator is 0 (condition test bl, bl is met). For every char read,
substract '0' from it to make it an actual digit. Then eax is multiplied by 10
and the digit is added to it.

At the end eax becomes -eax if the original number was a negativ one.

## create_tree

To help solve this task i have created 2 helper functions: 

### -> replace_nexy_white_char

This functions replaces the use of the usual _strtok_, what this function does
is receiving a string input and replacing the next delimiter character with a
string terminator and storing in ebx a pointer to the character after the string
terminator we have just added, or a _null_ (0x0) if there is no character after
the terminator.

The algorithm is simple: loop through the string until a delimiter character is
found, replace it, and return the character of the next char after the 
delimiter in ebx.

Example: "12 34 5454" becomes 12(\0)34 5454, the first space is replaced with 
'\0' and ebx will point to the string "34 5454".

### -> check_if_operator

When we will parse numbers and operators, this function will tell us if the
string parsed is number or operator.

The logic is simple for checking matches with '*', '+', '/' (the first 
character of the string is matched with those ASCII characters), but for '-'
the logic does not apply because a negative number will also start with a '-'.
This problem is dealt with easily by checking the second character: if it is
a '\0' then it is an operator, otherwise it is a number. This information is
stored in _is\_operator_

### The actual function:

The function begins with a call to the _replace\_next\_white\_char_ function
and with a set of instructions that creates a new node, initializes the data
field of that node with the string given parameter (the string consists of only 
1 number/operator because we have called the parsing function, and a '\0' has
been placed after the number/operator, and ebx now has an address to the next
number/operator after the one we are analyzing now), and the left and right
values are set to _null_ (0x0), all with the help of saving registers to stack
and restoring them after (and also malloc and strdup, we cannot forget about 
them, can't we). Before looping for every number that follows, initialize _root_
with the node created before, it will be the root of the graph, and 
_current\_node_ is also updated to this node.

In the loop for every number/operator the next algorithm is applied:

-> update the pointer to the number by moving in edx the address returned by
the previous call of _replace\_next\_white\_char_, and after that, another call 
to _replace\_next\_white\_char_, to be used in the next iteration.

-> create a new node with a value of the string (number/operator)

-> check if the string is value of operator (different thing need to be done
for each)

-> _things\_to\_do\_if\_operator_ is a label denoting the set of instructions
that need to be performed if the string is an operator: push the node to stack
(because we simulate a DFS in an iterative manner using the stack). Next up, we
check if left side of _current\_node_ (*the parrent node!!*) is null or not.
If it is null, we need to add to the left, if it is not null, we add to the
right (there is no way both of them are full because once we put something into
the right side _current\_node_ is changed).

-> _things\_to\_do\_if\_not\_operator_ is a label denoting the set of 
instructions that need to be performed if the string is a number: do *NOT* push
the node to the stack (because it would be useless in a DFS, a number is always 
a leaf), and after this do the exact same thing as in the operator label (check
left value and push to either right or left based on that).

-> add\_to\_left\_operator moves the value of the node to the left, and updates
_current\_node_ to that node.

-> add\_to\_right\_operator moves the value of the node to the right, and 
updates _current\_node_ to that node. 

-> add\_to\_left\_value moves the number to the left but it does *NOT* update
_current\_node_, since the next value that will be read will surely be it's right neighbour, which has the same parrent (_current\_node_ is the *PARRENT*).

-> add\_to\_right\_value moves the number to the right, but the update for
_current\_node_ is unfortunately an exhaustive process. By multiple _pops_ from
the stack and _peeks_ into it, we try to find a parrent node that has the right
value _null_ (not filled yet, it expects children). When this is criteria is met
the loop is ended.

-> when the end of the token is reached, there are still nodes pushed to the
stack that have not yet been poped, so we pop nodes until the offset between ebp
and esp is 0x4(we pushed ebx at the beginning of the function to save it, we
will pop it after we pop the extra nodes).

At the end we move the original value from _root_ into eax.