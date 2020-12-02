%include "utils/printf32.asm"
section .data
    delim db " ", 0

section .bss
    root resd 1
    currentNode resd 1
    isOperator resd 1
    isNegativeAtoi resd 1

section .text

extern evaluate_ast
extern create_node
extern printf
global create_tree
global iocla_atoi


iocla_atoi:             ;change string to number
    enter 0, 0
    push ebx
    push ecx
    push edx

    mov eax, [ebp + 8]
    xor ecx, ecx  ;stores the result
    xor ebx, ebx  ;stores character

    mov edx, 0
    mov [isNegativeAtoi], edx   ;the default way is that the number is positive
    ;we check to see if the number is negative or not
    mov bl, [eax]
    cmp bl, '-'   ;compare to minus character
    jnz atoi_loop ;if it is not a minus sign just do the rest as usual
    mov edx, 1
    mov [isNegativeAtoi], edx   ;change global variable
    inc eax                     ;get rid of the minus

atoi_loop:
    mov bl, [eax] ;get the character
    test bl, bl   ;check if we reached the end
    jz end_of_atoi
    cmp bl, ' '
    jz end_of_atoi
    cmp bl, 10
    jz end_of_atoi
    imul ecx, 0xa ;multiply ecx by 10
    sub bl, '0'
    add ecx, ebx
    inc eax
    jmp atoi_loop

end_of_atoi:

    ;checking to see if the number was negative or not
    mov eax, ecx
    mov edx, [isNegativeAtoi]
    cmp edx, 0
    jz is_positive_number
    ;we do the next only of the number is negative
    mov eax, 0
    sub eax, ecx
is_positive_number:

    pop edx
    pop ecx
    pop ebx
    leave
    ret


replace_next_white_char:    ;replaces next space character with '\0'
                            ;returns a pointer to the word after the space, or
                            ;a 0 if this word was the last one (in ebx)
    enter 0, 0

    mov ebx, [ebp + 8]      ; the parameter is a string

starting_loop:
    mov cl, [ebx]
    cmp cl, ' '
    jz end_of_replacement    ;we have found a space, going to replace it
    cmp cl, 0
    jz last_word_case        ;we have foudn a '\0' char, this is the last word
    inc ebx;
    jmp starting_loop

end_of_replacement:
    mov cl, 0
    mov [ebx], cl          ;replace the space character with a '\0'
    inc ebx                 ;return the value after the '\0'
    jmp end_of_replacement_function

last_word_case:
    mov ebx, 0              ;return 0 in ebx

end_of_replacement_function:
      
    leave
    ret

check_if_operator:          ;check is the symbol given parameter is an operator
                            ;(+,-,*,/), store the information in "isOperator"
    enter 0, 0

    mov eax, [ebp + 8]      ;puttin into ecx the string
    mov cl, [eax]           ;putting into cl the first character of the string

    cmp cl, '+'
    jz is_an_operator
    cmp cl, '-'
    jz is_a_minus           ;it could either a operator or a negative number
    cmp cl, '*'
    jz is_an_operator
    cmp cl, '/'
    jz is_an_operator
    mov ebx, 0x0            ; it is not an operator
    mov [isOperator], ebx
    jmp end                

is_a_minus:
    mov cl, [eax + 0x1]     ;get the second character
    cmp cl, 0               ;if the next char is '\0' is an operator
    jz is_an_operator
    mov ebx, 0x0            ; it is not an operator
    mov [isOperator], ebx
    jmp end

is_an_operator:
    ;PRINTF32 `OPERATOR:%c:OPERATOR\n\x0`,ecx
    mov ebx, 0x1
    mov [isOperator], ebx
    
end:

    leave
    ret

create_tree:
    enter 0, 0
    push ebx
    push ecx
    push edx

    mov edx, [ebp + 8]

    push eax            ;saving eax register
    push ecx            ;saving ecx register
    push edx            ;pushing parameter

    call replace_next_white_char

    pop edx             ;removing paramter
    pop ecx             ;restoring ecx register
    pop eax             ;restoring eax register

    ;PRINTF32 `DA:%s:DA\n\x0`,edx

    ;initializing root Node
    push edx            ;pushing parameter
    call create_node
    pop edx             ;restore edx and empty parameter pushed to stack

    mov [root], eax;    ;initialize the root
    mov [currentNode], eax  ;initialize the currentNode for the first time
    push eax;           ;push first node to stack

traverse_token:
    cmp ebx, 0          ;the previous word was the last one
    jz reached_end_token;

    mov edx, ebx        ;move edx to the next word and call the function that
                        ;puts a '\0' tot the end of it
    push eax            ;saving eax register
    push ecx            ;saving ecx register
    push edx            ;pushing parameter
    call replace_next_white_char
    add esp, 0x4        ;removing paramter
    pop ecx             ;restoring ecx register
    pop eax             ;restoring eax register

    ;PRINTF32 `DA:%s:DA\n\x0`,edx

    ;push ecx
    ;mov ecx, [currentNode]
    ;mov ecx, [ecx]
    ;PRINTF32 `INLINE:%s:INLINE\n\x0`,ecx
    ;pop ecx

    push ebx            ;saving ebx register
    push ecx            ;saving ecx register
    push edx            ;saving edx register
    push edx            ;pushing parameter
    call create_node
    add esp, 0x4        ;removing parameter
    pop edx             ;restoring edx register
    pop ecx             ;restoring ecx register
    pop ebx             ;restoring ebx register 
    
    push eax            ;saving eax register
    push ebx            ;saving ebx register
    push ecx            ;saving ecx register (nu e neaparat momentan)
    push edx            ;pushing parameter
    call check_if_operator
    add esp, 0x4        ;removing parameter
    pop ecx             ;restoring ecx register
    pop ebx             ;restoring ebx register
    pop eax             ;restoring eax register

    mov ecx, [isOperator];
    cmp ecx, 0x1
    je things_to_do_if_operator     ;it is an operator
    jmp things_to_do_if_not_operator ;it is not an operator

things_to_do_if_operator:
    push eax
    ;now we add the eax node either to the left or right of currentNode
    ;if left is null, add to left; if left is not null, add to right and change
    ;currentNode to parrent node
    mov ecx, [currentNode]  ;move to ecx the node
    mov ecx, [ecx + 0x4]    ;move to ecx the left node address
    cmp ecx, 0x0            ;check if it si null
    jz add_to_left_operator
    jmp add_to_right_operator
    ; DONE

things_to_do_if_not_operator:
    ;NO need to push eax because integer values are always leafs
    ;we add the eax node either to the left or right, if we add to the right
    ;the currentNode is updated by poping the stack
    mov ecx, [currentNode]  ;move to ecx the node
    mov ecx, [ecx + 0x4]    ;move to ecx the left node address
    cmp ecx, 0x0            ;check if it si null
    jz add_to_left_value
    jmp add_to_right_value
    ; DONE

end_of_operator_actions:

    jmp traverse_token  ;iterate for next character

add_to_left_operator:
    mov ecx, [currentNode]          ;move to ecx the node
    mov [ecx + 0x4], eax            ;left value is updated
    mov [currentNode], eax  ;currentNode is updated to the inserted value
    jmp end_of_operator_actions ;TBDT

add_to_right_operator:  ;adding to the right for operators
    mov ecx, [currentNode]  ;move to ecx the node
    mov [ecx + 0x8], eax    ;right value is updated
    mov [currentNode], eax  ;currentNode is updated to the inserted value
    jmp end_of_operator_actions ;TBDT

add_to_left_value:
    mov ecx, [currentNode]          ;move to ecx the node
    mov [ecx + 0x4], eax            ;left value is updated
    jmp end_of_operator_actions ;TBDT

add_to_right_value:         ;adding to the right for integer values
    mov ecx, [currentNode]  ;move to ecx the node
    mov [ecx + 0x8], eax    ;right value is updated

    ;now currentNode becomes the value in the stack that has a free right spot
    ;we are going to check for ecx, and when we find the value, we stop
loop_for_currentNode:
    pop ecx                 ;pop the parrent node of value
    mov ecx, [esp]          ;mov to ecx the future currentNode without poping
    mov [currentNode], ecx  ;update currentNode to future currentNode
    ;now we test to see if currentNode(ecx) has a free right
    mov ecx, [ecx + 0x8]    ;move to ecx the right value
    cmp ecx , 0x0           ;check if right tree is null
    jz we_have_found_currNode
    jmp loop_for_currentNode

we_have_found_currNode:
        
    jmp end_of_operator_actions ;TBDT

reached_end_token:  
    ;now we should pop the remaining stack nodes that we have pushed
    ;we pop everytime into the currentNode and do that until currentNode = ebp
    
loop_for_poping_remaining_nodes:
    mov ecx, ebp
    sub ecx, esp
    sub ecx, 0xc
    jz very_end          ;reached the bottom of the stack, the frame pointer
    add esp, 0x4         ;pop node into ecx (we do nothing with it)

very_end:
    mov eax, [root]     ;put in eax the root
    
    ;mov ecx, [eax + 0x8]  ; left of "+"
    ;mov ecx, [ecx + 0x4]  ; right of "*"
    ;mov ecx, [ecx + 4]  ; right of "/"
    ;mov ecx, [ecx + 4]
    ;mov ecx, [ecx]      ; 
    
    ;push eax
    ;push ecx
    ;call iocla_atoi
    ;PRINTF32 `SFARSIT:%d:SFARSIT\n\x0`,eax
    ;add esp, 0x4
    ;pop eax
    
    pop edx
    pop ecx
    pop ebx
    leave
    ret