ReadJoy:
    lda #$01
    sta JOY1
    sta buttons
    lsr a
    sta JOY1
joyloop:
    lda JOY1
    lsr a
    rol buttons
    bcc joyloop
    rts
