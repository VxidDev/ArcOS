time:
    mov ah, 0x00
    int 0x1A

    mov [time_hours], 0
    mov [time_minutes], 0
    mov [time_seconds], 0

    .convertToHMS:
        .hours:
            ; if cx:dx < 65543, go to minutes
            cmp cx, 1
            jb .minutes
            ja .do_sub_hours

            cmp dx, 7
            jb .minutes

            .do_sub_hours:
                ; subtract 65543 from cx:dx
                sub dx, 7
                sbb cx, 1

                inc word [time_hours]

                jmp .hours

        .minutes:
            ; if cx:dx < 1092, go to seconds
            cmp cx, 0
            ja .do_sub_minutes
            jb .seconds

            cmp dx, 1092
            jb .seconds

            .do_sub_minutes:
                sub dx, 1092
                sbb cx, 0

                inc word [time_minutes]

                jmp .minutes

        .seconds:
            cmp cx, 0
            ja .do_sub_seconds
            jb .done

            cmp dx, 18
            jb .done

            .do_sub_seconds:
                sub dx, 18
                sbb cx, 0

                inc word [time_seconds]

                jmp .seconds

            .done:

    .print:
        mov bx, 4

        mov si, time_hoursItoaBuf
        mov ax, [time_hours]

        add al, byte [tz_offset]

        call .zeroPadding

        call itoa 
        call .printConverted
        call .printSeparator

        mov si, time_minutesItoaBuf
        mov ax, [time_minutes]

        call .zeroPadding

        call itoa
        call .printConverted
        call .printSeparator

        mov si, time_secondsItoaBuf
        mov ax, [time_seconds]

        call .zeroPadding
        call itoa 
        call .printConverted

        ret

        .zeroPadding:
            mov cx, ax 

            cmp ax, 10
            jge .skipPadding

            mov si, time_zero
            mov ah, 0x01 
            int 0x80

            mov ax, cx

            .skipPadding:
                ret 

        .printSeparator:
            mov si, time_separator
            mov ah, 0x01
            int 0x80 

            ret

        .printConverted:
            add si, bx 
            sub si, di 

            mov ah, 0x01 
            int 0x80

            ret

    ret