section .data
    delim db " ", 0

section .bss
    root resd 1
    current_node resd 1
    is_operator resd 1
    is_negative_atoi resd 1

section .text

extern evaluate_ast
extern create_node
extern malloc
extern strdup
global create_tree
global iocla_atoi


iocla_atoi:             ;change string to number
    enter 0, 0
    push ebx            ;saving callee registers

    mov eax, [ebp + 8]
    xor ecx, ecx  ;stores the result
    xor ebx, ebx  ;stores character

    mov edx, 0
    mov [is_negative_atoi], edx   ;the default way is that the number is positive
    ;we check to see if the number is negative or not
    mov bl, [eax]
    cmp bl, '-'                 ;compare to minus character
    jnz atoi_loop          ;if it is not a minus sign just do the rest as usual
    mov edx, 1
    mov [is_negative_atoi], edx   ;change global variable
    inc eax                     ;get rid of the minus

atoi_loop:
    mov bl, [eax]               ;get the character
    test bl, bl                 ;check if we reached the end
    jz end_of_atoi
    imul ecx, 0xa               ;multiply ecx by 10
    sub bl, '0'
    add ecx, ebx
    inc eax
    jmp atoi_loop

end_of_atoi:

    ;checking to see if the number was negative or not
    mov eax, ecx
    mov edx, [is_negative_atoi]
    cmp edx, 0
    jz is_positive_number
    ;we do the next only of the number is negative
    mov eax, 0
    sub eax, ecx
is_positive_number:

    pop ebx         ;restoring callee registers
    leave
    ret


replace_next_white_char:    ;replaces next space character with '\0'
                            ;returns a pointer to the word after the space, or
                            ;a 0 if this word was the last one (in ebx)
    enter 0, 0
    mov ebx, [ebp + 8]      ; the parameter is a string

starting_loop:
    mov cl, [ebx]
    cmp cl, [delim]
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
                            ;(+,-,*,/), store the information in "is_operator"
    enter 0, 0
    push ebx

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
    mov [is_operator], ebx
    jmp end                

is_a_minus:
    mov cl, [eax + 0x1]     ;get the second character
    cmp cl, 0               ;if the next char is '\0' is an operator
    jz is_an_operator
    mov ebx, 0x0            ; it is not an operator
    mov [is_operator], ebx
    jmp end

is_an_operator:
    mov ebx, 0x1
    mov [is_operator], ebx
    
end:

    pop ebx
    leave
    ret

create_tree:
    enter 0, 0
    push ebx            ;saving registers

    mov edx, [ebp + 8]

    push eax            ;saving eax register
    push ecx            ;saving ecx register
    push edx            ;pushing parameter

    call replace_next_white_char

    pop edx             ;removing paramter
    pop ecx             ;restoring ecx register
    pop eax             ;restoring eax register

    ;initializing root Node
    push ebx            ;saving ebx register
    push ecx            ;saving ecx register
    push edx            ;saving edx register

    push edx            ;save edx register for malloc
    push 0xc 
    call malloc         ;allocate space for structure
    add esp, 0x4
    pop edx             ;restore edx register from malloc
    push eax            ;save eax

    push edx
    call strdup         ;duplicate node value 
    add esp, 0x4
    mov edx, eax

    pop eax             ;restore eax with node address
    mov [eax], edx              ;set value field
    mov [eax + 0x4], DWORD 0    ;set left to null
    mov [eax + 0x8], DWORD 0    ;set right to null

    pop edx             ;restoring edx register
    pop ecx             ;restoring ecx register
    pop ebx             ;restoring ebx register

    mov [root], eax;    ;initialize the root
    mov [current_node], eax  ;initialize the current_node for the first time
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

    ;create node
    push ebx            ;saving ebx register
    push ecx            ;saving ecx register
    push edx            ;saving edx register
    
    push edx            ;save edx register for malloc
    push 0xc 
    call malloc         ;allocate space for structure
    add esp, 0x4
    pop edx             ;restore edx register from malloc
    push eax            ;save eax

    push edx
    call strdup         ;duplicate node value 
    add esp, 0x4
    mov edx, eax

    pop eax             ;restore eax with node address
    mov [eax], edx              ;set value field
    mov [eax + 0x4], DWORD 0    ;set left to null
    mov [eax + 0x8], DWORD 0    ;set right to null

    pop edx             ;restoring edx register
    pop ecx             ;restoring ecx register
    pop ebx             ;restoring ebx register 
    
    push eax            ;saving eax register
    push ebx            ;saving ebx register
    push ecx            ;saving ecx register
    push edx            ;pushing parameter
    call check_if_operator
    add esp, 0x4        ;removing parameter
    pop ecx             ;restoring ecx register
    pop ebx             ;restoring ebx register
    pop eax             ;restoring eax register

    mov ecx, [is_operator];
    cmp ecx, 0x1
    je things_to_do_if_operator     ;it is an operator
    jmp things_to_do_if_not_operator ;it is not an operator

things_to_do_if_operator:
    push eax
    ;now we add the eax node either to the left or right of current_node
    ;if left is null, add to left; if left is not null, add to right and change
    ;current_node to parrent node
    mov ecx, [current_node]  ;move to ecx the node
    mov ecx, [ecx + 0x4]    ;move to ecx the left node address
    cmp ecx, 0x0            ;check if it si null
    jz add_to_left_operator
    jmp add_to_right_operator
    ; DONE

things_to_do_if_not_operator:
    ;NO need to push eax because integer values are always leafs
    ;we add the eax node either to the left or right, if we add to the right
    ;the current_node is updated by poping the stack
    mov ecx, [current_node]  ;move to ecx the node
    mov ecx, [ecx + 0x4]    ;move to ecx the left node address
    cmp ecx, 0x0            ;check if it si null
    jz add_to_left_value
    jmp add_to_right_value
    ; DONE

end_of_operator_actions:

    jmp traverse_token  ;iterate for next character

add_to_left_operator:
    mov ecx, [current_node]          ;move to ecx the node
    mov [ecx + 0x4], eax            ;left value is updated
    mov [current_node], eax  ;current_node is updated to the inserted value
    jmp end_of_operator_actions ;TBDT

add_to_right_operator:  ;adding to the right for operators
    mov ecx, [current_node]  ;move to ecx the node
    mov [ecx + 0x8], eax    ;right value is updated
    mov [current_node], eax  ;current_node is updated to the inserted value
    jmp end_of_operator_actions ;TBDT

add_to_left_value:
    mov ecx, [current_node]          ;move to ecx the node
    mov [ecx + 0x4], eax            ;left value is updated
    jmp end_of_operator_actions ;TBDT

add_to_right_value:         ;adding to the right for integer values
    mov ecx, [current_node]  ;move to ecx the node
    mov [ecx + 0x8], eax    ;right value is updated

    ;now current_node becomes the value in the stack that has a free right spot
    ;we are going to check for ecx, and when we find the value, we stop
loop_for_current_node:
    pop ecx                 ;pop the parrent node of value
    mov ecx, [esp]          ;mov to ecx the future current_node without poping
    mov [current_node], ecx  ;update current_node to future current_node
    ;now we test to see if current_node(ecx) has a free right
    mov ecx, [ecx + 0x8]    ;move to ecx the right value
    cmp ecx , 0x0           ;check if right tree is null
    jz we_have_found_currNode
    jmp loop_for_current_node

we_have_found_currNode:
        
    jmp end_of_operator_actions ;TBDT

reached_end_token:  
    ;now we should pop the remaining stack nodes that we have pushed
    ;we pop everytime into the current_node and do that until current_node = ebp
    
loop_for_poping_remaining_nodes:
    mov ecx, ebp
    sub ecx, esp
    sub ecx, 0x4
    jz very_end          ;reached the bottom of the stack, the frame pointer
    add esp, 0x4         ;pop node into ecx (we do nothing with it)

very_end:
    mov eax, [root]     ;put in eax the root
    
    pop ebx
    leave
    ret