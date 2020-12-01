%include "utils/printf32.asm"
section .data
    delim db " ", 0

section .bss
    root resd 1
    currentNode resd 1
    isOperator resd 1

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

    mov eax, ecx    ;return value
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

    mov cl, [ebp + 8]
    ;PRINTF32 `OPERATOR:%c:OPERATOR\n\x0`,ecx
    cmp cl, '+'
    jz is_an_operator
    cmp cl, '-'
    jz is_an_operator
    cmp cl, '*'
    jz is_an_operator
    cmp cl, '/'
    jz is_an_operator
    mov ebx, 0x0            ; it is not an operator
    mov [isOperator], ebx
    jmp end                

is_an_operator:
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
    push ebx            ;pushing parameter
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
    jz add_to_left
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

end_of_operator_actions:

    jmp traverse_token  ;iterate for next character

add_to_left:
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

add_to_right_value:     ;adding to the right for integer values
    mov ecx, [currentNode]  ;move to ecx the node
    mov [ecx + 0x8], eax    ;right value is updated
    pop ecx                 ;pop the parrent node of value
    mov ecx, [esp + 0x4]    ;mov to ecx the future currentNode without poping
    mov [currentNode], ecx  ;update currentNode to future currentNode
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
    
    pop edx
    pop ecx
    pop ebx
    leave
    ret