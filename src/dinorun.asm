;*******************************************************************************
;*                                                                             *
;*          Run Dino Run!                                                      *
;*                                                                             *
;*            written by                                                       *
;*            Paul Fiscarelli and Simon Jonassen                               *
;*                                                                             *
;*            v1.1.0                                                           *
;*            August 24, 2019                                                  *
;*                                                                             *
;*******************************************************************************


;*******************************************************************************
;*                                                                             *
;*          Hack close vector for autostart                                    *
;*                                                                             *
;*******************************************************************************
            org     $176
            jmp     Start		


;*******************************************************************************
;*                                                                             *
;*          Include text screen for loader                                     *
;*                                                                             *
;*******************************************************************************
            org     $400
            includebin ".\include\dinorun\screen.bin"

            
;*******************************************************************************
;*                                                                             *
;*          Reserve space for DP variables                                     *
;*                                                                             *
;*******************************************************************************
            org     VID_START+$2500         ; set start of DP variables
            opt     6809            
            opt     cd
            
;{
cactusani                                   ; initialize obstacle pointers
            fdb     obstacle01
            fdb     obstacle02
            fdb     obstacle03
            fdb     obstacle04
            fdb     obstacle05
            fdb     obstacle06
            fdb     obstacle07
            fdb     obstacle08
            fdb     obstacle09
            fdb     obstacle10
            fdb     obstacle11
            fdb     obstacle12
            fdb     obstacle13
            fdb     obstacle14
            fdb     obstacle15
            fdb     obstacle16            
            
vars        equ     *                       ; start of variable space

ButtonFlag  zmb     1                       ; Joy button state
InputFlag   zmb     1                       ; Input flag
JumpState   zmb     1                       ; Dino jump state
DuckState   zmb     1                       ; Dino duck state
ScrUnit     zmb     1                       ; Scoreboard - units value
ScrTen      zmb     1                       ; Scoreboard - tens value
ScrHund     zmb     1                       ; Scoreboard - hundreds value
ScrThou     zmb     1                       ; Scoreboard - thousandths value
ScrTenTh    zmb     1                       ; Scoreboard - ten-thousandths value
ScoreTemp   zmb     1                       ; Score temp value
TempByte    zmb     2                       ; Temp byte storage
MusicFlag   zmb     1                       ; Music on/off flag
CollFlag    zmb     1                       ; Collision detection flag
KeyFlag     zmb     1                       ; Keystroke in buffer flag
PteroFlag   zmb     1                       ; Ptero in sky flag
PteroFlap   zmb     1                       ; Ptero flap flag
PteroHPos   zmb     1                       ; Pterodactyl horizontal position
PteroVPos   zmb     1                       ; Pterodactyl vertical position
TotDist     zmb     2                       ; Total distance traveled
Timer       zmb     2                       ; Simple 2-byte timer (0-65535)
DinoYPos    zmb     2                       ; Dino Y-position on screen
GameLevel   zmb     1                       ; Current Game Level (0-3)
FirstGame   zmb     1                       ; First Game Flag
PauseState  zmb     1                       ; Game pause status
DemoMode    zmb     1                       ; Demo Mode flag
DinoFeet    zmb     2                       ; Offset for Dino's feet from top of sprite
DinoIsGod   zmb     1                       ; Dino is God
DinoBot     zmb     1                       ; Dino Bot Mode
cipher      zmb     2                       ; Cipher for Easter Eggs
curobst1    zmb     1                       ; Obstacle 1 tracker
curobst2    zmb     1                       ; Obstacle 2 tracker
curobst3    zmb     1                       ; Obstacle 3 tracker
curobst4    zmb     1                       ; Obstacle 4 tracker
cheatenable zmb     1                       ; Player activate cheat?

musicframe  fcb     MUSC_CYCLE
cyclegame   fcb     GAME_CYCLE
cyclescroll fcb     SCRL_CYCLE
cyclecactus fcb     CACT_CYCLE
cycleptero  fcb     PTER_CYCLE
cyclemount  fcb     MONT_CYCLE
cyclescore  fcb     SCOR_CYCLE
dinoframe   fcb     DINO_CYCLE
obstaclespd fcb     OBST_SPEED
obstaclechk fcb     OBST_CHCK
repeatnote  fcb     NOTE_REPEAT
obstclrows  fcb     OBST_HEIGHT
cactusdist  fcb     MINDIS_CACT
pterodist   fcb     MINDIS_PTER
obstcldist  fcb     MINDIS_OBST
groundcount fcb     GRND_CONT

newobheight fcb     OBST_HEIGHT
newmntspeed fcb     MONT_CYCLE

noterepeat  fcb     3
duckframe   fcb     2
scoredigits fcb     5
tuneselect  fcb     3

jumpheight  fcb     0,28,23,19,15,12,9,7,5,4,3,2,1,0,0,0,1,2,3,4,5,7,9,12,15,19,23,28
;}


;*******************************************************************************
;*                                                                             *
;*          Multi-voice Note Mixer (located in DP for speed)                   *
;*           Input  : none                                                     *
;*           Output : none                                                     *
;*           Used   : a,d                                                      *
;*                                                                             *
;*******************************************************************************
;{
note        std     <saved+1
sum         ldd     #$0000 
freq        addd    #$0000 
            std     <sum+1
sum2        ldd     #$0000
freq2       addd    #$0000
            std     <sum2+1 
sum3        ldd     #$0000 
freq3       addd    #$0000 
            std     <sum3+1
            adda    <sum+1
            rora
            adda    <sum2+1
            rora
            sta     $ff20           ;dac mixedsa
            lda     $ff93
saved       ldd     #0000
            rti
;}


;*******************************************************************************
;*                                                                             *
;*          Tune Player                                                        *
;*           Input  : none                                                     *
;*           Output : none                                                     *
;*           Used   : a                                                        *
;*                                                                             *
;*******************************************************************************
;{          doSound
doSound
poll        lda     <MusicFlag
            beq     DoMusic
            rts
DoMusic     dec     <musicframe
            bne     poll
            lda     #MUSC_CYCLE
            sta     <musicframe
;{
            
;*******************************************************************************
;*                                                                             *
;*          Note Sequencer                                                     *
;*           Input  : none                                                     *
;*           Output : none                                                     *
;*           Used   : a,b,d,x,u                                                *
;*                                                                             *
;*******************************************************************************
;{          play2
play2 

curnote     ldx     #dinotune1
            ldd     ,x++                    ; load 2 notes from pattern
            bpl     play                    ; go play if positive
            jsr     GetTune                 ; go get new tune
play        asla                            ; times 2 for note freq lookup
            aslb                            
            sta     <v1+2 
            stb     <v2+2
            lda     ,x+
            asla                            ; times 2 for note freq lookup
            sta     <v3+2

v1          ldu     freqtab                 ; get the right freq
            stu     <freq+1                 ; store it
v2          ldu     freqtab                 ; get the right freq2
            stu     <freq2+1                ; store it
v3          ldu     freqtab                 ; get the right freq3
            stu     <freq3+1                ; store it
            dec     repeatnote              ; check for note repeat
            beq     DonePlay                ; at zero? done playing
            rts
            
DonePlay    stx     <curnote+1              
            lda     #NOTE_REPEAT
            lda     noterepeat
            sta     <repeatnote
            rts
;}


;*******************************************************************************
;*                                                                             *
;*          Equate Values (constants)                                          *
;*                                                                             *
;*******************************************************************************
;{
POLCAT      equ     $A000                   ; Keyboard polling ROM routine
JOYIN       equ     $A00A                   ; Joystick polling ROM routine

RGB_PALETTE equ     $E5FA                   ; Set RGB palette ROM routine

VID_START   equ     $0400                   ; Start of video memory
VID_END     equ     VID_START+$1AFF         ; End of video memory
SCORE_START equ     VID_START+$0242         ; Scoreboard location
HIGH_SCORE  equ     VID_START+$0125         ; High Score Location
DINO_START  equ     VID_START+$1300         ; Start position of Dino on graphics page
CACTUS_ROW  equ     VID_START+$1300         ; Start position of Cactus
PTERO_ROW   equ     VID_START+$1300         ; Start position of Pterodactyl
OBST_ROW    equ     VID_START+$1300         ; Bottom row of obstacle band
MOUNT_LOC   equ     VID_START+$0700         ; Start position of Mountains
MOON_POS    equ     VID_START+$0259         ; Moon position
GRND_POS    equ     VID_START+$15C0         ; Ground position

GAME_CYCLE  equ     2                       ; How many cycles per frame (main loop frames)
CACT_CYCLE  equ     100                     ; Initial cactus on screen frame
PTER_CYCLE  equ     50                      ; Initial pterodactyl on screen frame
SCRL_CYCLE  equ     2                       ; How often to we cycle obstacle scroll
SCOR_CYCLE  equ     3                       ; How often to update scoreboard
DINO_CYCLE  equ     3                       ; How often to cycle Dino frames
DUCK_FRAME  equ     3                       ; How many duck frames for Dino
MONT_CYCLE  equ     12                      ; Mountains scroll cycle
MUSC_CYCLE  equ     2                       ; Music cycle rate
OBST_CHCK   equ     0                       ; Obstacle check - obstacle levels
DINO_XOFST  equ     5                       ; Dino X-offset (horizontal)
OBST_SPEED  equ     4                       ; How many ROLs per iteration
NOTE_REPEAT equ     3                       ; repeat notes to save space
OBST_HEIGHT equ     30                      ; obstacle band height (bytes) for ROLs
JUMP_FRAMES equ     27                      ; 27-frames in jump animation
JUMP_OFFSET equ     -1152                   ; 36-rows x 32-bytes per row
TROL_OFFSET equ     $4E0                    ; Offset temp space for ROLs
SCRL_OFFSET equ     $4E7                    ; Offset bytes to scroll scratch space
DINO_TEMPOF equ     $0C80                   ; Offest temp space for com'ed Dino
OBST_TEMPOF equ     $0CA4                   ; Offest temp space for com'ed Obstacles
NEWOB_OFFST equ     $0500                   ; Offset temp space for new Obstacles
MINDIS_CACT equ     1                       ; Minimum spacing distance between Cactus
MINDIS_PTER equ     1                       ; Minimum spacing distance between Pterodactyl
MINDIS_OBST equ     1                       ; Minimum spacing distance between any two Obstacles
GRND_CONT   equ     6                       ; Counter for adding new ground
HASH_VALUE  equ     $FFFF                   ; Easter Egg 1
DINO_GOD    equ     $7E82                   ; Easter Egg 2
DINO_BOT    equ     $1815                   ; Easter Egg 3
LEVEL_1     equ     200                     ; Set value to finish level 1
LEVEL_2     equ     400                     ; Set value to finish level 2
LEVEL_3     equ     800                     ; Set value to finish level 3
LEVEL_4     equ     1200                    ; Set value to finish level 4
LEVEL_5     equ     1500                    ; Set value to finish level 5
LEVEL_6     equ     1600                    ; Set value to finish level 6
LEVEL_7     equ     2000                    ; Set value to finish level 7
COCO_SCORE  equ     6809                    ; Set value to hit secret level
;}


;*******************************************************************************
;*                                                                             *
;*          Game Setup                                                         *
;*           Input  : none                                                     *
;*           Output : none                                                     *
;*           Used   : a,d,dp,cc                                                *
;*                                                                             *
;*******************************************************************************
;{ 
            org     VID_START+$2600         ; start of excecutable code

Start       clr     $FF40                   ; stop drives from spinning
    
            jsr     RGB_PALETTE             ; RGB palette
            orcc    #$50

            lda     #$55                    ; warm restart at reset or exit
            sta     $71

            ldd     #start2
            std     $72

start2      nop 		
            lda     #vars/256               ; fix DP register for variable space
            tfr     a,dp                    ; store DP
           		
            setdp   $29                     ; set DP

            sta     $ffd7                   ; high-speed
            sta     $ffd9                   ; high-speed

            lda     #$d8
            sta     $ff90                   ; gime firq enabled
            lda     #32
            sta     $ff91
            sta     $ff93
            
            ldd     #460                    ; timer value (12bit) (8Khz)
            std     $ff94                   ; 1/7800 -> / 0.000000279 = 460
;}            
            
;*******************************************************************************
;*          Initiate DP at JMP vector                                          *
;*******************************************************************************       
;{
            lda	    #$0e                    ; DP JMP instruction
            ldb	    #note&$ff               ; address of player
            std	    >$fef4                  ; IRQ JUMP VECTOR 
;}

;*******************************************************************************
;           Enable  FIRQ                                                       *
;*******************************************************************************
            andcc   #$bf


;*******************************************************************************
;*                                                                             *
;*          Main Routine                                                       *
;*           Input  : none                                                     *
;*           Output : none                                                     *
;*           Used   : a                                                        *
;*                                                                             *
;*******************************************************************************
;{          Init
Init        nop                             ; no-operation for reset vector
            jsr     InitRandom              ; go handle RND initialize

Graphics    lda     #$F0                    ; Pmode 4 (G6R) - Color Set 1
            sta     $FF22
            sta     $FFC3
            sta     $FFC5

            sta     $FFC9                   ; set video start at $0400

ShowTitle            
            jsr     HandleTitle             ; go draw title screen
NewGame            
            jsr     StageGame               ; go stage game content
            jsr     StartGame               ; go initialize game
Main
            jsr     HandleTime              ; go handle time
            dec     cyclegame               ; cycle game counter
            bne     More                    ; not zero? go do more
            lda     #GAME_CYCLE             ; reset game counter
            sta     cyclegame               ; store game counter

            jsr     ScoreHandle             ; go handle score
            lda     DinoBot                 ; check bot mode
            beq     DoControls              ; not bot mode? go do controls
            jsr     DemoControls            ; use demo mode
            bra     MainCont                ; always go to main continue
DoControls                                  
            jsr     ChckButton              ; go check buttons
            jsr     ChckKeybd               ; go check keyboard
MainCont            
            jsr     doDino                  ; go animate Dino
            jsr     HandleCollision         ; go handle collisions
            jsr     OtherKeys               ; go check other keys (POLCAT)
            dec     cyclemount              ; cycle mountain counter
            bne     Main                    ; at zero? no - loop to Main
            lda     newmntspeed             ; get mountain speed
            sta     cyclemount              ; reset mountain counter
            jsr     doMonts                 ; go do mountains
More        
            
            jsr     doSound                 ; go handle sound
            jsr     doGround                ; go handle ground
            jsr     doObstacle              ; go handle obstacles
            
Done        bra     Main                    ; always loop Main
;}


;*******************************************************************************
;*                                                                             *
;*          Clear Graphics Memory                                              *
;*           Input  : none                                                     *
;*           Output : none                                                     *
;*           Used   : d,x                                                      *
;*                                                                             *
;*******************************************************************************
;{          ClearGraphics
ClearGraphics            
            ldd     #$FFFF
            ldx     #VID_START                  ; beginning of video space
GraphicCLR  std     ,x++
            cmpx    #VID_END                    ; clear $2800-$2C80 for temp space
            blo     GraphicCLR                  ; are we there yet? no - go for more
            
            ldd     #$0000                      ; clear temp space
            ldx     #VID_START+$1B00            ; offset from video space
GraphicCLR2 
            std     ,x++
            cmpx    #VID_START+$24FF
            blo     GraphicCLR2            

            rts
;}


;*******************************************************************************
;*                                                                             *
;*          Get New Tune for synth                                             *
;*           Input  : none                                                     *
;*           Output : none                                                     *
;*           Used   : a,d,x                                                    *
;*                                                                             *
;*******************************************************************************
;{          GetTune
GetTune
            dec     tuneselect
            beq     playTune1
            lda     tuneselect
            cmpa    #02
            beq     playTune2
playTune3   ldx     #dinotune3
            stx     <curnote+1
            ldd     ,x++                    ;get beginning 2 notes from pattern - cont            
            rts
playTune2   ldx     #dinotune2
            stx     <curnote+1
            ldd     ,x++                    ;get beginning 2 notes from pattern - cont
            rts
playTune1   lda     #3
            sta     tuneselect
            ldx     #dinotune1
            stx     <curnote+1
            ldd     ,x++                    ;get beginning 2 notes from pattern - cont
            rts
;}            

;*******************************************************************************
;*                                                                             *
;*          Draw Mountains                                                     *
;*           Input  : none                                                     *
;*           Output : none                                                     *
;*           Used   : a,d,x,y,u                                                *
;*                                                                             *
;*******************************************************************************
;{          doMonts
doMonts
            ldx     #MOUNT_LOC
ddd         ldu     #pic+32
            ldy     #$3b		            ;one less line (black definition line)
mloop       ldd     1,x
            std     ,x
            ldd     3,x
            std     2,x
            ldd     5,x
            std     4,x
            ldd     7,x
            std     6,x
            ldd     9,x
            std     8,x
            ldd     11,x
            std     10,x
            ldd     13,x
            std     12,x
            ldd     15,x
            std     14,x
            ldd     17,x
            std     16,x
            ldd     19,x
            std     18,x
            ldd     21,x
            std     20,x
            ldd     23,x
            std     22,x
            ldd     25,x
            std     24,x
            ldd     27,x
            std     26,x
            ldd     29,x
            std     28,x
            lda     31,x
            sta     30,x

            lda     ,u
            sta     31,x

            leau    64,u	
            leax    32,x
            leay    -1,y
            bne     mloop

            lda     ddd+2
            inca
            anda    #63
            sta     ddd+2
            rts
;}

;*******************************************************************************
;*                                                                             *
;*          Draw Mountains                                                     *
;*           Input  : none                                                     *
;*           Output : none                                                     *
;*           Used   : a,x,y,u                                                  *
;*                                                                             *
;*******************************************************************************
;{          NewMonts
NewMonts    
            lda     #$3c

picptr      ldx     #pic
            ldy     #MOUNT_LOC
next        ldu     ,x
            stu     ,y
            ldu     2,x
            stu     2,y
            ldu     4,x
            stu     4,y
            ldu     6,x
            stu     6,y
            ldu     8,x
            stu     8,y
            ldu     10,x
            stu     10,y
            ldu     12,x
            stu     12,y
            ldu     14,x
            stu     14,y
            ldu     16,x
            stu     16,y
            ldu     18,x
            stu     18,y
            ldu     20,x
            stu     20,y
            ldu     22,x
            stu     22,y
            ldu     24,x
            stu     24,y
            ldu     26,x
            stu     26,y
            ldu     28,x
            stu     28,y
            ldu     30,x
            stu     30,y
            leax    64,x
            leay    32,y
            deca
            bne     next

stor        inc     picptr+2
            rts
;}


;*******************************************************************************
;*                                                                             *
;*          Run in demo mode                                                   *
;*           Input  : none                                                     *
;*           Output : none                                                     *
;*           Used   : a                                                        *
;*                                                                             *
;*******************************************************************************
;{          doDemo
doDemo
            jsr     StageGame
DemoMain
            jsr     HandleTime
            jsr     CheckInput
            lda     InputFlag
            beq     DemoCont
            clr     InputFlag
            clr     DemoMode
            jsr     InitVars
            jmp     NewGame
DemoCont            
            dec     cyclegame
            bne     DemoMore
            lda     #GAME_CYCLE
            sta     cyclegame
            jsr     ScoreHandle
            jsr     DemoControls
            jsr     doDino
            jsr     HandleCollision
            dec     cyclemount
            bne     DemoMain
            lda     newmntspeed
            sta     cyclemount
            jsr     doMonts
DemoMore
            jsr     doGround
            jsr     doObstacle
DemoDone    
            bra     DemoMain
            rts
;}


;*******************************************************************************
;*                                                                             *
;*          Demo Handler                                                       *
;*           Input  : none                                                     *
;*           Output : none                                                     *
;*           Used   : a                                                        *
;*                                                                             *
;*******************************************************************************
;{          DemoControls
DemoControls
            lda     JumpState
            bne     DoneDemoH
            
            lda     curobst1
            beq     ChckOB2
            jsr     DemoJump1
            lda     JumpState
            bne     DoneDemoH
ChckOB2
            lda     curobst2
            beq     ChckOB3
            jsr     DemoJump1
            lda     JumpState
            bne     DoneDemoH            
ChckOB3
            lda     curobst3
            beq     ChckOB4
            jsr     DemoJump1
            lda     JumpState
            bne     DoneDemoH
ChckOB4
            lda     curobst3
            beq     PteroDemo
            jsr     DemoJump1
            lda     JumpState
            bne     DoneDemoH
            bra     PteroDemo
            
DemoJump1
            cmpa    #$3F
            bhi     DoneDemoH
            cmpa    #$30
            blo     DoneDemoH
            lda     DinoBot
            bne     DoJump
            jsr     GetRandom               ; randomly forget to jump
            anda    #%00000111
            bne     DoJump
            clr     curobst2
DoJump
            lda     #JUMP_FRAMES            ; 15-frames in jump animation
            sta     JumpState 
            rts
            
PteroDemo    
            lda     PteroFlag
            beq     DoneDemoH
            lda     JumpState
            bne     DoneDemoH
JumpStart   
            lda     PteroVPos
            bne     DemoJump2
DemoDuck     
            lda     DuckState
            bne     DoneDemoH
            lda     PteroHPos
            cmpa    #$40
            bhi     DoneDemoH
            cmpa    #$30
            blo     DoneDemoH
            lda     #35
            sta     DuckState           
            bra     DoneDemoH
DemoJump2     
            lda     PteroHPos
            cmpa    #$40
            bhi     DoneDemoH
            cmpa    #$30
            blo     DoneDemoH
            lda     #JUMP_FRAMES            ; 15-frames in jump animation
            sta     JumpState
DoneDemoH
            lda     DuckState
            bne     ReallyDone
            lda     #4
            sta     duckframe
ReallyDone            
            rts
;}

;*******************************************************************************
;*                                                                             *
;*          Stage game                                                         *
;*           Input  : none                                                     *
;*           Output : none                                                     *
;*           Used   : a                                                        *
;*                                                                             *
;*******************************************************************************
;{          StageGame
StageGame            
            jsr     ClearGraphics
            jsr     doMoon
            jsr     ResetScore
            lda     FirstGame
            beq     SkipHigh
            jsr     ShowHigh
SkipHigh            
            jsr     NewMonts         
            jsr     NewGround
            jsr     dinoBegEnd

            rts
;}

;*******************************************************************************
;*                                                                             *
;*          Start new game                                                     *
;*           Input  : none                                                     *
;*           Output : none                                                     *
;*           Used   : a,x                                                      *
;*                                                                             *
;*******************************************************************************
;{          StartGame
StartGame
            jsr     GetRandom
            anda    #%00000011
            inca
            sta     tuneselect
            jsr     GetTune
            
            lda     HScrUnit
            bne     SkipInternet
            
            ldx     #nointernet             ; get title text memory index
            stx     StringLoc               ; store in string location var
            ldx     #VID_START+$16D4        ; location to print on screen
            stx     PrintAtLoc              ; store location to print at
            jsr     PrintAtGr               ; go print text

SkipInternet
            jsr     WaitForInput
            
            ldx     #blank                  ; get title text memory index
            stx     StringLoc               ; store in string location var
            ldx     #VID_START+$16C0        ; location to print on screen
            stx     PrintAtLoc              ; store location to print at
            jsr     PrintAtGr               ; Go print text

            lda     #JUMP_FRAMES    
            sta     JumpState
            lda     MusicFlag
            bne     ReturnMain
            lda     $FF23                   ; re-enable sound
            ora     #%00001000
            sta     $FF23
ReturnMain
            rts
;}

;*******************************************************************************
;*                                                                             *
;*          Draw New Ground                                                    *
;*                                                                             *
;*******************************************************************************
;{          NewGround
NewGround    
            ldx     #GRND_POS

loopGround
            jsr     GetRandom
            ora     #%00111100
            sta     32,x
            coma
            sta     ,x+
            
            cmpx    #GRND_POS+DINO_XOFST    ; put some ground in temp space
            blo     ContGround
            cmpx    #GRND_POS+DINO_XOFST+2
            bhi     ContGround
            sta     SCRL_OFFSET+56,x       
            sta     OBST_TEMPOF+64,x
            coma
            sta     SCRL_OFFSET+24,x
            sta     OBST_TEMPOF+32,x
ContGround            
            cmpx    #GRND_POS+32
            bne     loopGround
            
            sta     VID_START+$1AC0         ; put ground offscreen for rols
            sta     VID_START+$1AE1
            coma
            sta     VID_START+$1AE0
            sta     VID_START+$1AC1
            
            rts
;}


;*******************************************************************************
;*                                                                             *
;*          Draw Ground                                                        *
;*                                                                             *
;*******************************************************************************
;{          doGround
doGround
            dec     groundcount
            bne     doneGround
            lda     #GRND_CONT
            sta     groundcount
            jsr     GetRandom
            ora     #%00111100
            sta     VID_START+$1AC0
            sta     VID_START+$1AE1
            sta     VID_START+$1AC2
            coma
            sta     VID_START+$1AE0
            sta     VID_START+$1AC1
            sta     VID_START+$1AE2
doneGround  
            rts
;}
            

;*******************************************************************************
;*                                                                             *
;*          Handle Obstacles                                                   *
;*                                                                             *
;*******************************************************************************
;{          doObstacle
doObstacle  
            dec     obstcldist              ; check min distance between obstacles
            bne     GoScroll

            inc     obstcldist
            
            dec     cactusdist
            bne     TryPtero
            inc     cactusdist
            dec     cyclecactus
            bne     GoScroll
            jsr     GetRandom
            anda    #%00111111
            ora     #%00000001
            sta     cyclecactus
            lda     MINDIS_OBST
            sta     obstcldist
AddCactus   
            jsr     doCactus
            
            ldx     TotDist
            cmpx    #100
            blo     GoCycle
            lda     DemoMode
            bne     GoCycle
            lda     DinoBot
            beq     GoScroll
GoCycle            
            jsr     CycleObst
           
            bra     GoScroll
TryPtero    
            lda     GameLevel               ; Pteros only level-2 and above
            cmpa    #$02
            blo     GoScroll
            dec     pterodist
            bne     GoScroll
            inc     pterodist
            dec     cycleptero
            bne     GoScroll
            jsr     GetRandom
            anda    #%00111111
            ora     #%00000001
            sta     cycleptero
            lda     MINDIS_OBST
            sta     obstcldist
AddPtero    
            jsr     doPtero            
GoScroll    
            jsr     ScrollObst
            rts
;}            


;*******************************************************************************
;*                                                                             *
;*          Cycle Obstacles (demo mode)                                        *
;*                                                                             *
;*******************************************************************************
;{          CycleObst
CycleObst    
            lda     curobst1
            bne     OBcheck2
            lda     #$FF
            sta     curobst1
            rts
OBcheck2
            lda     curobst2
            bne     OBcheck3
            lda     #$FF
            sta     curobst2
            rts
OBcheck3
            lda     curobst3
            bne     OBcheck4
            lda     #$FF
            sta     curobst3
            rts
OBcheck4
            lda     curobst4
            beq     Set4
            rts
Set4
            lda     #$FF
            sta     curobst4
            rts
;}
 
;*******************************************************************************
;*                                                                             *
;*          Draw Moon                                                          *
;*                                                                             *
;*******************************************************************************
;{          doMoon
doMoon
            ldx     #MOON_POS
            ldu     #moon
bigMoon     ldb     #05
loopMoon    lda     ,u+
            beq     CheckCheat
            sta     ,x+
            decb
            bne     loopMoon
            leax    27,x
            bra     bigMoon
CheckCheat
            lda     cheatenable
            beq     doneMoon
            ldx     #MOON_POS+2
            lda     #$FF
            sta     ,x
            ldx     #MOON_POS+800
            sta     ,x
doneMoon
            rts
;}


;*******************************************************************************
;*                                                                             *
;*          Draw Cactus                                                        *
;*                                                                             *
;*******************************************************************************
;{          doCactus
doCactus    
            ldx     TotDist
            cmpx    #COCO_SCORE
            blo     OtherObst
            cmpx    #COCO_SCORE+250
            bhi     OtherObst
            ldy     #coco6809
            bra     DrawCactus
OtherObst            
            jsr     GetRandom
            anda    #%00000011              ; get 1-of-4 in lower nibble
            sta     TempByte
            jsr     GetRandom
            anda    obstaclechk             ; grab value based on obstacle level
            ora     TempByte
            asla
            sta     >cactusnum+3
cactusnum   ldy     >cactusani

DrawCactus
            ldx     #CACTUS_ROW
            leax    NEWOB_OFFST,x
            ldb     #30
loopCactus  lda     ,y+
            beq     doneCactus
            sta     ,x+
            lda     ,y+
            sta     ,x+
            lda     ,y+
            sta     ,x
            abx
            bra     loopCactus
doneCactus  
            sta     VID_START+$1AE0
            lda     MINDIS_CACT
            sta     cactusdist
            rts
;}


;*******************************************************************************
;*                                                                             *
;*          Draw Pterodactyl                                                   *
;*                                                                             *
;*******************************************************************************
;{          doPtero
doPtero     
            lda     PteroFlag
            bne     skipPtero
            lda     GameLevel
            cmpa    #04
            blo     SlowLevel
            lda     #08
            bra     StoreLow
SlowLevel   jsr     GetRandom               ; determine high or low flying
            anda    #%00001000
StoreLow    sta     PteroVPos
            ldb     #32
            mul
            ldx     #PTERO_ROW
            leax    NEWOB_OFFST,x
            leax    d,x
            ldy     #pterodactyl1
loopPtero   lda     ,y+
            beq     donePtero
            sta     ,x+
            lda     ,y+
            sta     ,x+
            lda     ,y+
            sta     ,x
            leax    30,x
            bra     loopPtero
donePtero   
            coma                            ; reset Dino position counter
            sta     PteroHPos
            sta     PteroFlag
            lda     MINDIS_PTER
            sta     pterodist 
skipPtero            
            rts
;}


;*******************************************************************************
;*                                                                             *
;*          Draw Dino (Start and Dead Position)                                *
;*                                                                             *
;*******************************************************************************
;{          dinoBegEnd
dinoBegEnd
            lda     CollFlag
            beq     BeginDino
DeadDino
            ldx     #DINO_START+DINO_XOFST
            ldu     #dinodeadi
            lda     JumpState
            beq     dinoLoop
            leax    JUMP_OFFSET,x
            ldu     #jumpheight
            lda     a,u
            ldb     #32
            mul
            leax    d,x
            dec     JumpState
            ldu     #dinodeadji
            bra     dinoLoop
BeginDino            
            ldx     #DINO_START+DINO_XOFST-$60
            ldu     #dinostandi
dinoLoop
            ldd     ,u++
            cmpa    #$AA
            beq     dinoDone
            ora     OBST_TEMPOF+32,x
            orb     OBST_TEMPOF+33,x
            coma
            comb
            std     ,x      
            lda     ,u+
            ora     OBST_TEMPOF+34,x
            coma
            sta     2,x
            leax    32,x
            bra     dinoLoop
dinoDone            
            rts
;}


;*******************************************************************************
;*                                                                             *
;*          Do Dino Frames (animate)                                           *
;*                                                                             *
;*******************************************************************************
;{          doDino
doDino
            ldx     #DINO_START+DINO_XOFST
            lda     DuckState
            beq     CheckJump
            dec     DuckState
            lda     duckframe
            cmpa    #04             ; clear ani-frame above duck?
            bne     DinoDuck
            dec     duckframe
            ldu     #dinoduck1clear
            bra     DrawDino
DinoDuck    
            ldy     #DINO_START+$02C0
            sty     DinoFeet
            ldx     #DINO_START+DINO_XOFST+384
            dec     duckframe
            beq     DuckFrame1
DuckFrame2  
            ldu     #dinoduck2i
            bra     DrawDino		;BRA cheaper as in +/- 127 range
DuckFrame1  
            lda     #DUCK_FRAME
            sta     duckframe
            ldu     #dinoduck1i
            bra     DrawDino		;BRA cheaper as in +/- 127 range

CheckJump   
            lda     JumpState
            beq     RunDino
DinoJump    
            ldy     #DINO_START+$0200
            sty     DinoFeet
            leax    JUMP_OFFSET,x
            ldu     #jumpheight
            lda     a,u
            ldb     #32
            mul
            leax    d,x
            dec     JumpState
            ldu     #dinostandi
            bra     DrawDino		;BRA CHEAPER (3 cycles total (JMP is 4))
            
RunDino     ldy     #DINO_START+$0280
            sty     DinoFeet
            dec     dinoframe
            bne     run_dino1

run_dino2   ldu     #dinorun2i
            ldb     #DINO_CYCLE
            stb     dinoframe
            bra     DrawDino

run_dino1   ldu     #dinorun1i

DrawDino                            ; Draw Dino on screen and check collisions
            stx     DinoYPos        ; save where we're at
LoopDino    
            ldd     ,u++
            cmpa    #$AA
            beq     doneDino
            std     TempByte
            std     DINO_TEMPOF,x
            ora     OBST_TEMPOF+32,x
            orb     OBST_TEMPOF+33,x
            coma
            comb
            std     ,x+
SkipColl1   
            lda     TempByte+1      ; check for collision
            beq     SkipColl2
            clra
            ora     OBST_TEMPOF+0,x
            beq     SkipColl2
            cmpx    DinoFeet
            bhi     SkipColl2
            inc     CollFlag
            lda     JumpState
            beq     NoJump
            inc     JumpState       ; put Dino back to where he was
NoJump
            bra     HandleCollision
SkipColl2   
            leax    1,x
            lda     ,u+
            sta     TempByte
            sta     DINO_TEMPOF,x
            ora     OBST_TEMPOF+32,x
            coma
            sta     ,x
SkipColl3   
            leax    30,x
            bra     LoopDino
doneDino    
            rts
;}


;*******************************************************************************
;*                                                                             *
;*          Collision Handler                                                  *
;*                                                                             *
;*******************************************************************************
;{          HandleCollision
HandleCollision
            lda     DinoIsGod
            bne     CollDone
            lda     CollFlag
            beq     CollDone
KillDino    
            jsr     doObstacle
            lda     JumpState
            cmpa    #$13
            blo     SkipObst
            jsr     doObstacle
SkipObst            
            jsr     dinoBegEnd
            lda     DemoMode
            bne     doDemoOver
            bra     doGameOver
CollDone    
            clr     CollFlag
            rts
;}


;*******************************************************************************
;*                                                                             *
;*          Game Over                                                          *
;*                                                                             *
;*******************************************************************************
;{          doGameOver
doGameOver
            lda     $FF23               ; turn off music
            anda    #%11110111
            sta     $FF23
            
            ldx     #gameover           ; get title text memory index
            stx     StringLoc           ; store in string location var
            ldx     #VID_START+$0F0B    ; location to print on screen
            stx     PrintAtLoc          ; store location to print at
            jsr     PrintAtGr           ; Go print text
            
            jsr     HandleHigh
            
            ldx     #$5000              ; hang tight to clear keys and buttons
DelayLoop   leax    -1,x
            bne     DelayLoop
            
            clr     Timer
            
OverInput   jsr     CheckInput
            jsr     HandleTime
            lda     Timer
            cmpa    #$E1
            blo     OverInputs
            bra     ContDemo
OverInputs            
            lda     InputFlag
            beq     OverInput            
            
            jsr     InitVars
            jsr     ClearGraphics
            jsr     ShowHigh
            lda     FirstGame
            bne     DoneEnd
            inc     FirstGame
DoneEnd
            jmp     NewGame
;}

;*******************************************************************************
;*                                                                             *
;*          Demo Over                                                          *
;*                                                                             *
;*******************************************************************************
;{          doDemoOver
doDemoOver
            clr     Timer               ; reset timer for timeout
            clr     DemoMode
            clr     CollFlag
            
MoreInput   jsr     CheckInput
            jsr     HandleTime
            lda     Timer
            cmpa    #$60
            blo     CheckInputs
            bra     ContDemo
CheckInputs            
            lda     InputFlag
            beq     MoreInput
            
            clr     InputFlag
            clr     DemoMode
            jsr     InitVars
            jmp     NewGame
ContDemo
            jmp     HandleTitle

;}


;*******************************************************************************
;*                                                                             *
;*          Initialize Variables                                               *
;*                                                                             *
;*******************************************************************************
;{          InitVars
InitVars
            ldx     #dinotune1
            stx     <curnote+1
            
            ldx     #pic+32
            stx     >ddd+1
            
            ldx     #pic
            stx     >picptr+1
            
            clr     CollFlag
            clr     PteroFlag
            clr     DuckState
            clr     JumpState
            clr     GameLevel
            clr     PauseState
            ;clr     DinoBot
            clr     TotDist
            clr     TotDist+1
            clr     DinoIsGod
            clr     curobst1
            clr     curobst2
            clr     curobst3
            clr     curobst4
            
            lda     #30             ; newobheight
            ;sta     newobheight
            ldb     #12             ; newmntspeed
            ;sta     newmntspeed
            std     newobheight
            clr     obstaclechk
            rts
;}            


;*******************************************************************************
;*                                                                             *
;*          Check joystick button                                              *
;*                                                                             *
;*******************************************************************************
;{          ChckButton
ChckButton  
            lda     PauseState      ; game currently paused? 
            bne     ChckPause
            lda     KeyFlag         ; still processing keystroke?
            bne     ButtDone
            lda     JumpState       ; already in jump cycle?
            bne     ButtDone
            
            lda     #$FF            ; Mask keystrokes
            sta     $FF02
            lda     $FF00           ; load PIA0 state
            anda    #%00000010      ; check left-joystick button-1
            beq     SetJump
            lda     $FF00           ; load PIA0 state
            anda    #%00000001      ; check right-joystick button-1
            bne     NextButt
SetJump            
            lda     #JUMP_FRAMES    ; 15-frames in jump animation
            sta     JumpState
            bra     ClearDuck       ; go clear ducking status
JmpButtDone            
            rts
NextButt    
            lda     DuckState       ; currently in a duck state?
            bne     ButtDone
            lda     KeyFlag
            bne     ButtDone
            
            lda     #$FF            ; Mask keystrokes
            sta     $FF02
            lda     $FF00
            anda    #%00001000      ; check left-joystick button-2
            beq     SetDuck
            lda     $FF00           ; load PIA0 state
            anda    #%00000100      ; check right-joystick button-2
            bne     ClearDuck
SetDuck            
            lda     #01 
            sta     DuckState       ; setup Dino ducking
            bra     ButtDone
ClearDuck           
            lda     #04             ; need to clear ani-frame above duck
            sta     duckframe
            bra     ButtDone
ChckPause
            clr     ButtonFlag
            lda     #$FF            ; Mask keystrokes
            sta     $FF02
            lda     $FF00           ; load PIA0 state
            anda    #%00000010      ; check left-joystick button-1
            beq     GotButt1
            lda     $FF00           ; load PIA0 state
            anda    #%00000001      ; check right-joystick button-1
            bne     CheckButt2
GotButt1            
            inc     ButtonFlag
            clr     DuckState
            bra     ClearDuck
CheckButt2  
            lda     #$FF            ; Mask keystrokes
            sta     $FF02
            lda     $FF00           ; load PIA0 state
            anda    #%00001000      ; check left-joystick button-1
            beq     GotButt2
            lda     $FF00           ; load PIA0 state
            anda    #%00000100      ; check right-joystick button-2
            bne     ButtDone
GotButt2            
            inc     ButtonFlag
ButtDone    
            rts
;}


;*******************************************************************************
;*                                                                             *
;*          Check Keyboard                                                     *
;*                                                                             *
;*******************************************************************************
;{
ChckKeybd   
            clr     KeyFlag  
CheckSpace
            lda     #$7F            ; first check <space> with joy buttons
            sta     $FF02
            lda     $FF00
            anda    #%00001000
            coma
            sta     KeyFlag
            beq     CheckEnter
            lda     #$FF            ; mask off keystrokes (just joy buttons)
            sta     $FF02
            lda     $FF00
            anda    #%00001000
            anda    KeyFlag
            beq     CheckEnter
            
            lda     JumpState
            bne     CheckEnter
            lda     #JUMP_FRAMES
            sta     JumpState
            clr     DuckState
            clr     <cipher
            clr     <cipher+1
            clr     KeyFlag
            inc     KeyFlag
            bra     DoneKeybd
ClearDuck2            
            lda     #04             ; need to clear ani-frame above duck
            sta     duckframe
            rts
CheckEnter
            clr     KeyFlag
            lda     DuckState
            bne     DoneKeybd
            lda     JumpState
            bne     DoneKeybd
            lda     #$FE
            sta     $FF02
            lda     $FF00
            anda    #%01000000
            bne     ClearDuck2
            
            lda     #01 
            sta     DuckState       ; setup Dino ducking
            inc     KeyFlag
DoneKeybd   
            rts
;}


;*******************************************************************************
;*                                                                             *
;*          Pause Game (other)                                                 *
;*                                                                             *
;*******************************************************************************
;{          otherPause
otherPause
            lda     $FF23
            anda    #%11110111
            sta     $FF23
            
            inc     PauseState
            
            com     CipherTXT
            
            ldx     #othertxt1          ; get title text memory index
            stx     StringLoc           ; store in string location var
            ldx     #VID_START+$0F02    ; location to print on screen
            stx     PrintAtLoc          ; store location to print at
            jsr     PrintAtGr           ; Go print text
            
            ldx     #othertxt2          ; get title text memory index
            stx     StringLoc           ; store in string location var
            ldx     #VID_START+$1083    ; location to print on screen
            stx     PrintAtLoc          ; store location to print at
            jsr     PrintAtGr           ; Go print text
            
            com     CipherTXT
            
            jsr     WaitForInput
            clr     PauseState
            
            ldx     #blank              ; get title text memory index
            stx     StringLoc           ; store in string location var
            ldx     #VID_START+$0F00    ; location to print on screen
            stx     PrintAtLoc          ; store location to print at
            jsr     PrintAtGr           ; Go print text
            
            ldx     #VID_START+$1080    ; location to print on screen
            stx     PrintAtLoc          ; store location to print at
            jsr     PrintAtGr           ; Go print text
            
            lda     MusicFlag
            bne     DoneOtherP
            
            lda     $FF23
            ora     #%00001000
            sta     $FF23
DoneOtherP            
            rts
;}


;*******************************************************************************
;*                                                                             *
;*          Other Keys (POLCAT with debounce                                   *
;*                                                                             *
;*******************************************************************************
;{          OtherKeys
OtherKeys
            lda     KeyFlag
            sta     TempByte
            
            clr     KeyFlag
            jsr     [POLCAT]        ; grab another keystroke
            beq     DoneOther       ; nothing in buffer - let's bail
            clr     DinoBot
            sta     KeyFlag         ; set keystroke status
            cmpa    #$20            ; <space> press?
            beq     CheckMkey
            
            ldb     cipher          ; hmmmmmm
            rolb
            eorb    cipher
            eora    cipher+1
            std     cipher
            ldx     cipher
            cmpx    #HASH_VALUE
            beq     otherPause
            cmpx    #DINO_GOD
            bne     NextKey
            com     DinoIsGod
            inc     cheatenable
            bra     ShowCheat
NextKey     
            cmpx    #DINO_BOT
            bne     CheckKeys
            inc     cheatenable
            com     DinoBot
ShowCheat
            ldx     #MOON_POS+2
            lda     #$FF
            sta     ,x
            ldx     #MOON_POS+800
            sta     ,x
FlashScreen
            lda     #$F8
            sta     $FF22
            ldx     #$AFF
FlashLoop   
            leax    -1,x
            bne     FlashLoop
            lda     #$F0
            sta     $FF22
CheckKeys            
            lda     KeyFlag
CheckMkey
            cmpa    #77             ; 'M' keystroke
            bne     CheckPkey
            com     MusicFlag
            lda     $FF23
            eora    #%00001000
            sta     $FF23
            rts
CheckPkey            
            cmpa    #80             ; 'P' keystroke
            beq     doPause
CheckRArr   
            cmpa    #09             ; 'Right-Arrow' keystroke
            bne     DoneOther
            jsr     GetTune
            rts
DoneOther            
            lda     TempByte
            sta     KeyFlag
            
            rts
;}

            
;*******************************************************************************
;*                                                                             *
;*          Pause Game                                                         *
;*                                                                             *
;*******************************************************************************
;{          doPause
doPause
            lda     $FF23
            anda    #%11110111
            sta     $FF23
            
            inc     PauseState
            
            ldx     #gamepaused         ; get title text memory index
            stx     StringLoc           ; store in string location var
            ldx     #VID_START+$0F0A    ; location to print on screen
            stx     PrintAtLoc          ; store location to print at
            jsr     PrintAtGr           ; Go print text
            
            jsr     WaitForInput
            clr     PauseState
            
            ldx     #blank              ; get title text memory index
            stx     StringLoc           ; store in string location var
            ldx     #VID_START+$0F00    ; location to print on screen
            stx     PrintAtLoc          ; store location to print at
            jsr     PrintAtGr           ; Go print text
            
            lda     MusicFlag
            bne     DonePause
            
            lda     $FF23
            ora     #%00001000
            sta     $FF23
DonePause            
            rts
;}


;*******************************************************************************
;*                                                                             *
;*          Time Handler                                                       *
;*                                                                             *
;*******************************************************************************
;{          HandleTime
HandleTime
            ldx     Timer
            leax    1,x
            stx     Timer
            rts
;}            


;*******************************************************************************
;*                                                                             *
;*          Check Input (Joystick or Keyboard)                                 *
;*                                                                             *
;*******************************************************************************
;{          CheckInput
CheckInput
            clr     InputFlag
            clr     KeyFlag
            inc     PauseState
            jsr     ChckButton
            clr     PauseState
            lda     ButtonFlag
            bne     SetInput
            jsr     [POLCAT]
            sta     KeyFlag
            beq     DoneInput
SetInput
            inc     InputFlag
            clr     ButtonFlag
            ;clr     JumpState
            clr     DuckState
DoneInput            
            rts
;}
            

;*******************************************************************************
;*                                                                             *
;*          Wait For Input                                                     *
;*                                                                             *
;*******************************************************************************
;{          WaitForInput
WaitForInput
            lda     PauseState
            bne     GetInput
            inc     PauseState
GetInput            
            jsr     HandleTime
            jsr     GetEntropy
            jsr     CheckInput
            lda     InputFlag
            beq     WaitForInput
DoneWait    
            lda     #04             ; need to clear ani-frame above duck
            sta     duckframe
            clr     ButtonFlag
            clr     PauseState
            clr     InputFlag
            rts
;}

           
;*******************************************************************************
;*                                                                             *
;*          Score Handler - using a decade counter method                      *
;*                                                                             *
;*******************************************************************************
;{          ScoreHandle
ScoreHandle
            dec     cyclescore      ; check if we're ready
            bne     ScoreChk
            lda     #SCOR_CYCLE
            sta     cyclescore
            ldb     #1
            ldx     TotDist
            abx
            stx     TotDist
CountScore            
            inc     ScrUnit         ; handle units place
            ldb     ScrUnit
            stb     ScoreTemp
            lda     #$0A
            bsr     ScoreChange
            ldb     ScrUnit
            cmpb    #$0A
            bne     ScoreChk
            clr     ScrUnit

            inc     ScrTen          ; handle tens place
            ldb     ScrTen
            stb     ScoreTemp
            lda     #$09
            bsr     ScoreChange
            ldb     ScrTen
            cmpb    #$0A
            bne     ScoreChk
            clr     ScrTen

            inc     ScrHund         ; handle hundreds place
            ldb     ScrHund
            stb     ScoreTemp
            lda     #$08
            bsr     ScoreChange
            ldb     ScrHund
            cmpb    #$0A
            bne     ScoreChk
            clr     ScrHund

            inc     ScrThou         ; handle thousandths place
            ldb     ScrThou
            stb     ScoreTemp
            lda     #$07
            bsr     ScoreChange
            ldb     ScrThou
            cmpb    #$0A
            bne     ScoreChk
            clr     ScrThou

            inc     ScrTenTh        ; handle ten-thousandths place
            ldb     ScrTenTh
            stb     ScoreTemp
            lda     #$06
            bsr     ScoreChange
            ldb     ScrTenTh
            cmpb    #$0A
            bne     ScoreChk
            clr     ScrTenTh
ScoreChk                            ; done with scoreboard update
            bsr     HandleLevel
            rts                     
;}

;*******************************************************************************
;*                                                                             *
;*          Score Change - update scoreboard                                   *
;*           Input  : a (digit to update, offset from SCORE_START)             *
;*           Output : none                                                     *
;*           Used   : a,b,d,x,u                                                *
;*                                                                             *
;*******************************************************************************
;{          ScoreChange
ScoreChange 
            ldu     #SCORE_START    ; get start of scoreboard
            leau    a,u             ; offset scoreboard position
            ldb     ScoreTemp       ; get temp score value
            cmpb    #$0A            ; are we at '10'?
            bne     ScoreCont       ; go do the digit
            clrb                    ; reset to zero
ScoreCont   
            lda     #8              ; 8-bytes per char
            mul                     ; font x8-bytes
            ldx     #numbers        ; get numbers font location
            leax    d,x             ; store offset location
            lda     #8
MoreFont    
            ldb     ,x+
            stb     ,u
            leau    32,u
            deca
            bne     MoreFont
            rts
;}



;*******************************************************************************
;*                                                                             *
;*          Reset Score                                                        *
;*                                                                             *
;*******************************************************************************
;{          ResetScore
ResetScore     
            clr     ScrUnit
            clr     ScrTen
            clr     ScrHund
            clr     ScrThou
            clr     ScrTenTh
            ldx     #SCORE_START
            ldu     #scoreword
bigScore    ldb     #06
loopScore   lda     ,u+
            sta     ,x+
            decb
            bne     loopScore
            leax    26,x
            cmpx    #SCORE_START+$100
            blt     bigScore
            
            clr     ScoreTemp
ClearScore  
            lda     #$05
            adda    scoredigits
            bsr     ScoreChange
            dec     scoredigits
            bne     ClearScore
            
            lda     #$05
            sta     scoredigits
doneScore            
            rts
;}


;*******************************************************************************
;*                                                                             *
;*          Level Handler                                                      *
;*                                                                             *
;*******************************************************************************
;{          HandleLevel
HandleLevel
            ldx     TotDist

            lda     GameLevel
            cmpa    #07
            beq     doneScore
            cmpa    #06
            beq     Check7
            cmpa    #05
            beq     Check6
            cmpa    #04
            beq     Check5
            cmpa    #03
            beq     Check4
            cmpa    #02
            beq     Check3
            cmpa    #01
            beq     Check2
Check1
            cmpx    #LEVEL_1
            blo     DoneLevel
            inc     GameLevel
Handle1
            lda     #30             ; newobheight
            ;sta     newobheight
            ldb     #11             ; newmntspeed
            ;sta     newmntspeed
            std     newobheight
            ;lda     #00
            ;sta     obstaclechk
Check2            
            cmpx    #LEVEL_2
            blo     DoneLevel
            inc     GameLevel
Handle2
            lda     #28             ; newobheight
            ;sta     newobheight
            ldb     #10             ; newmntspeed
            ;sta     newmntspeed
            std     newobheight
            lda     #4
            sta     obstaclechk
            rts
Check3
            cmpx    #LEVEL_3
            blo     DoneLevel
            inc     GameLevel
Handle3
            lda     #26             ; newobheight
            ;sta     newobheight
            ldb     #9              ; newmntspeed
            ;sta     newmntspeed
            std     newobheight
            lda     #8
            sta     obstaclechk
            rts
Check4
            cmpx    #LEVEL_4
            blo     DoneLevel
            inc     GameLevel
Handle4
            lda     #24             ; newobheight
            ;sta     newobheight
            ldb     #8              ; newmntspeed
            ;sta     newmntspeed
            std     newobheight
            ;lda     #8
            ;sta     obstaclechk
            rts
Check5
            cmpx    #LEVEL_5
            blo     DoneLevel
            inc     GameLevel
Handle5
            lda     #24             ; newobheight
            ;sta     newobheight
            ldb     #7              ; newmntspeed
            ;sta     newmntspeed
            std     newobheight
            lda     #4
            sta     obstaclechk
            rts
Check6
            cmpx    #LEVEL_6
            blo     DoneLevel
            inc     GameLevel
Handle6
            lda     #20             ; newobheight
            ;sta     newobheight
            ldb     #6              ; newmntspeed
            ;sta     newmntspeed
            std     newobheight
            ;lda     #4
            ;sta     obstaclechk
            rts             
Check7
            cmpx    #LEVEL_7
            blo     DoneLevel
            inc     GameLevel
Handle7
            lda     #16             ; newobheight
            ;sta     newobheight
            ldb     #4              ; newmntspeed
            ;sta     newmntspeed
            std     newobheight
            lda     #12
            sta     obstaclechk
DoneLevel
            rts           
;}


;*******************************************************************************
;*                                                                             *
;*          Handle High Score                                                  *
;*                                                                             *
;*******************************************************************************
;{          HandleHigh
HandleHigh
            lda     ScrTenTh
            suba    HScrTenTh
            blo     DoneHScore
            bne     NewHigh
            
            lda     ScrThou
            suba    HScrThou
            blo     DoneHScore
            bne     NewHigh
            
            lda     ScrHund
            suba    HScrHund
            blo     DoneHScore
            bne     NewHigh
            
            lda     ScrTen
            suba    HScrTen
            blo     DoneHScore
            bne     NewHigh
            
            lda     ScrUnit
            suba    HScrUnit
            blo     DoneHScore
NewHigh     
            lda     ScrTenTh
            sta     HScrTenTh
            lda     ScrThou
            sta     HScrThou
            lda     ScrHund
            sta     HScrHund
            lda     ScrTen
            sta     HScrTen
            lda     ScrUnit
            sta     HScrUnit
            jsr     ShowHigh
DoneHScore
            rts
;}


;*******************************************************************************
;*                                                                             *
;*          Show High Score                                                    *
;*                                                                             *
;*******************************************************************************
;{          HighScore
ShowHigh
            ldx     #highscore          ; get title text memory index
            stx     StringLoc           ; store in string location var
            ldx     #HIGH_SCORE         ; location to print on screen
            stx     PrintAtLoc          ; store location to print at
            jsr     PrintAtGr           ; Go print text
   
            lda     #03
            ldb     HScrTenTh
            jsr     HScoreChange
            
            lda     #04
            ldb     HScrThou
            jsr     HScoreChange
            
            lda     #05
            ldb     HScrHund
            jsr     HScoreChange
            
            lda     #06
            ldb     HScrTen
            jsr     HScoreChange
            
            lda     #07
            ldb     HScrUnit
            jsr     HScoreChange
doneHigh             
            rts
            
;*******************************************************************************
;*                                                                             *
;*          High Score Change - update high scoreboard                         *
;*                                                                             *
;*******************************************************************************
;{          HScoreChange
HScoreChange 
            ldu     #HIGH_SCORE     ; get start of scoreboard
            leau    a,u             ; offset scoreboard position
HScoreCont   
            lda     #8              ; 8-bytes per char
            mul                     ; font x8-bytes
            ldx     #numbers        ; get numbers font location
            leax    d,x             ; store offset location
            lda     #8
HMoreFont    
            ldb     ,x+
            stb     ,u
            leau    32,u
            deca
            bne     HMoreFont
            rts
;}


;*******************************************************************************
;*                                                                             *
;*          Handle Title Page                                                  *
;*                                                                             *
;*******************************************************************************
;{          HandleTitle
HandleTitle
            jsr     TitlePage

            clr     DemoMode            ; make sure demo is clear
            clr     Timer               ; reset timer for timeout
            inc     DemoMode            ; get ready for demo mode
            jsr     InitVars
            
CycleInput  jsr     CheckInput
            jsr     HandleTime
            lda     Timer
            cmpa    #$48
            blo     ChckInput
            jmp     doDemo
ChckInput            
            lda     InputFlag
            beq     CycleInput
            
            clr     DemoMode
            
            jsr     InitVars
            jmp     NewGame

            rts
;}
 
;*******************************************************************************
;*                                                                             *
;*          Title Page                                                         *
;*                                                                             *
;*******************************************************************************
;{          Title Page
TitlePage   
            jsr     ClearGraphics       ; clear screen first
            ldb     #4			        ; GFX FADE SPEED (FRAMES)
            stb     wvs+1
            jsr     TitleGraphic        ; do title graphic
            
            ldb     #45			        ; TEXT PLOT SPEED (FRAMES)
            stb     wvs+1
            jsr     wvs                 ; Go print text

            ldx     #titletext          ; get title text memory index
            stx     StringLoc           ; store in string location var
            ldx     #VID_START+$0A0A    ; location to print on screen
            stx     PrintAtLoc          ; store location to print at
            jsr     PrintAtGr           ; Go print text
            jsr     wvs                 ; Go print text

            ldx     #title1             ; get title text memory index
            stx     StringLoc           ; store in string location var
            ldx     #VID_START+$0C0F    ; location to print on screen
            stx     PrintAtLoc          ; store location to print at
            jsr     PrintAtGr           ; Go print text
            jsr     wvs                 ; Go print text
            
            ;ldx     #title2             ; get title text memory index
            ldx     pfcredits
            stx     StringLoc           ; store in string location var
            ldx     #VID_START+$0E08    ; location to print on screen
            stx     PrintAtLoc          ; store location to print at
            ;jsr     PrintAtGr           ; Go print text
            jsr     pfWord
            jsr     wvs                 ; Go print text
            
            ldx     #title3             ; get title text memory index
            stx     StringLoc           ; store in string location var
            ldx     #VID_START+$1106    ; location to print on screen
            stx     PrintAtLoc          ; store location to print at
            jsr     PrintAtGr           ; Go print text
            jsr     wvs                 ; Go print text
            
            ;ldx     #title4             ; get title text memory index
            ldx     andcredits
            stx     StringLoc           ; store in string location var
            ldx     #VID_START+$124E    ; location to print on screen
            stx     PrintAtLoc          ; store location to print at
            ;jsr     PrintAtGr           ; Go print text
            jsr     andWord
            jsr     wvs                 ; Go print text
            
            ldx     #title5             ; get title text memory index
            stx     StringLoc           ; store in string location var
            ldx     #VID_START+$1347    ; location to print on screen
            stx     PrintAtLoc          ; store location to print at
            jsr     PrintAtGr           ; Go print text
            jsr     wvs                 ; Go print text
            
            ldx     #title6             ; get title text memory index
            stx     StringLoc           ; store in string location var
            ldx     #VID_START+$1509    ; location to print on screen
            stx     PrintAtLoc          ; store location to print at
            jsr     PrintAtGr           ; Go print text
            
            ;jsr     WaitForInput        ; Wait for keystroke
            ;jsr     ClearGraphics       ; Clear graphics page
DoneTitle
            rts
;}


;*******************************************************************************
;*                                                                             *
;*          Title Graphic                                                      *
;*                                                                             *
;*******************************************************************************
;{          TitleGraphic
TitleGraphic
            bsr     wvs
            ldx     #dinopic
            ldu     #VID_START+$0100
TitleLoop   ldd     ,x++
            ora     xx
            orb     xx

            std     ,u++
            cmpx    #enddinopic
            blo     TitleLoop
            asl     xx
            bcs     TitleGraphic
            com     xx
            ldb     #4
            stb     wvs+1
            rts

xx          fcb     %11111111
;}


;*******************************************************************************
;                                                                              *
;*          WAIT FOR SOME VSYNCS                                               *
;*                                                                             *
;*******************************************************************************
;{
wvs         
            ldb     #4
vs          lda     $ff03
            bpl     vs
            lda     $ff02
            decb
            bne     vs
            rts
;}

;*******************************************************************************
;*                                                                             *
;*          Print Routine - Graphics Screen                                    *
;*                                                                             *
;*******************************************************************************
;{          PrintAtGr
PrintAtGr   
            ldx     PrintAtLoc      ; grab screen location from memory variable
            ldy     StringLoc       ; grab string location from memory variable
PrintLoop            
            lda     ,y+             ; grab first byte of string
            beq     DonePrint       ; done with string, go to DonePrint
            inc     lettercount
DoChar                  
            anda    #%00111111      ; subtract 64 from ASCII value
            ldb     CipherTXT       
            beq     DoText
            suba    #$0D
DoText              
            ldb     #08             ; 8-bytes per character
            mul                     ; get our character index offset
            ldu     #letters        ; memory index of font
            leau    d,u             ; index font location
            ldb     #08             ; 8-bytes per character
DoBytes
            lda     ,u+             ; get character byte
            sta     ,x              ; put byte on screen
            leax    32,x            ; index 32-bytes on page (next line)
            decb                    ; decrement byte counter
            bne     DoBytes         ; go do more bytes
            leax    -255,x          ; move screen index next char
            bra     PrintLoop       ; go get another character
DonePrint
            rts

;}
lettercount zmb     1



;*******************************************************************************
;*                                                                             *
;*          PF Title Word (hack for centering text)                            *
;*                                                                             *
;*******************************************************************************
;{          pfWord
pfWord
            ldx     PrintAtLoc
            ;ldu     StringLoc
            ldu     #pfcredits
bigPF       ldb     #16
littlePF    lda     ,u+
            beq     DoneLetters
            sta     ,x+
            decb
            bne     littlePF
            leax    16,x
            bra     bigPF
DoneLetters
            rts
;}


;*******************************************************************************
;*                                                                             *
;*          AND Title Word (hack for centering text)                           *
;*                                                                             *
;*******************************************************************************
;{          andWord
andWord
            ldx     PrintAtLoc
            ;ldu     StringLoc
            ldu     #andcredits
bigAND      ldb     #4
littleAND   lda     ,u+
            beq     DoneANDLet
            sta     ,x+
            decb
            bne     littleAND
            leax    28,x
            bra     bigAND
DoneANDLet
            rts
;}


;*******************************************************************************
;*                                                                             *
;*          Scroll Obstacles                                                   *
;*                                                                             *
;*******************************************************************************
;{          ScrollObst
ScrollObst  dec     cyclescroll
            bne     DonePrint       ; go to nearest rts - save lbne
            lda     #SCRL_CYCLE
            sta     cyclescroll
            ;dec     cactusdist
            ;dec     pterodist
ObstLoop    
            ldx     #OBST_ROW
            leax    767,x
            dec     obstaclespd
            lbeq    ObstDone
DoObstBand  
            orcc    #$01
            rol     TROL_OFFSET+3,x
            rol     TROL_OFFSET+2,x
            rol     TROL_OFFSET+1,x
            rol     ,x
            rol     -1,x
            rol     -2,x
            rol     -3,x
            rol     -4,x
            rol     -5,x
            rol     -6,x
            rol     -7,x
            rol     -8,x
            rol     -9,x
            rol     -10,x
            rol     -11,x
            rol     -12,x
            rol     -13,x
            rol     -14,x
            rol     -15,x
            rol     -16,x
            rol     -17,x
            rol     -18,x
            rol     -19,x
            rol     -20,x
            rol     -21,x
            rol     -22,x
            rol     -23,x
            rol     SCRL_OFFSET,x
            rol     SCRL_OFFSET-1,x
            rol     SCRL_OFFSET-2,x
            rol     -27,x
            rol     -28,x
            rol     -29,x
            rol     -30,x
            rol     -31,x
            
            lda     SCRL_OFFSET,x
            coma
            sta     OBST_TEMPOF+8,x
            ora     -24+DINO_TEMPOF,x
            coma
            sta     -24,x
            
            lda     SCRL_OFFSET-1,x
            coma
            sta     OBST_TEMPOF+7,x
            ora     -25+DINO_TEMPOF,x
            coma
            sta     -25,x
            
            lda     SCRL_OFFSET-2,x
            coma
            sta     OBST_TEMPOF+6,x
            ora     -26+DINO_TEMPOF,x
            coma
            sta     -26,x            

            dec     obstclrows
            beq     BandDone
            leax    -32,x           
            jmp     DoObstBand

BandDone                
            jsr     CheckObst
            lda     newobheight
            sta     obstclrows
            jmp     ObstLoop
ObstDone    
            lda     #OBST_SPEED
            sta     obstaclespd
            rts	
            
            ldx     #PTERO_ROW
            leax    1023,x
CopyObst    
            dec     obstclrows
            beq     CopyDone
            leax    -32,x
            bra     CopyObst
CopyDone    
            lda     #OBST_HEIGHT
            sta     obstclrows
ScrollDone  
            rts
;}


;*******************************************************************************
;*                                                                             *
;*          Check Obstacles - Animation Handler                                *
;*                                                                             *
;*******************************************************************************
;{          Check Obstacles
CheckObst
            ldx     TotDist
            cmpx    #100
            blo     ObCheck
            
            lda     DemoMode
            bne     ObCheck
            lda     DinoBot
            beq     CheckPtero
ObCheck
            lda     curobst1
            beq     Chck2
            dec     curobst1
Chck2       
            lda     curobst2
            beq     Chck3
            dec     curobst2
Chck3       
            lda     curobst3
            beq     Chck4
            dec     curobst3            
Chck4       
            lda     curobst4
            beq     CheckPtero
            dec     curobst4
CheckPtero            
            lda     PteroFlag
            beq     DoneObChck
            dec     PteroHPos
            bne     FlapPtero
            clr     PteroFlag
            rts
FlapPtero
            lda     PteroHPos
            cmpa    #$F0            ; Ptero still off screen?
            beq     DoneObChck
            anda    #%00001111      ; Even 2-byte boundary?
            bne     DoneObChck
            ldb     PteroHPos
            rorb                    
            rorb
            rorb
            ldx     #PTERO_ROW-32
            abx
            
            lda     PteroVPos
            ldb     #32
            mul
            leax    d,x
            
            com     PteroFlap
            bne     Flap2
Flap1 
            ldy     #pterodactyl1
            bra     loopPtero2
Flap2       
            ldy     #pterodactyl2
loopPtero2  
            lda     ,y+
            beq     DoneObChck
            sta     ,x+
            lda     ,y+
            sta     ,x+
            lda     ,y+
            sta     ,x
            leax    30,x
            bra     loopPtero2
DoneObChck  
            rts


;*******************************************************************************
;*                                                                             *
;*          Get Entropy - attempt randomness                                   *
;*                                                                             *
;*******************************************************************************
;{          GetEntropy
GetEntropy
            lda     Timer+1
            sta     $0113
            jsr     InitRandom
            rts
;}            
            
;*******************************************************************************
;*                                                                             *
;*          InitRandom                                                         *
;*           Input  : none                                                     *
;*           Output : none                                                     *
;*           Used   : a                                                        *
;*                                                                             *
;*******************************************************************************
;{          InitRandom
InitRandom  lda     $113            ;grab RNG seed (BASIC TIMER)
            bne     store_rng
            inca
store_rng   sta     rndx+1
            rts
;}

;*******************************************************************************
;*                                                                             *
;*          GetRandom                                                          *
;*           Pseudo-Random Number Generator                                    * 
;*           ------------------------------------------------                  *
;*           Input  : none                                                     *
;*           Output : a (8bit rnd)                                             *
;*                                                                             *
;*******************************************************************************
;{          GetRandom
GetRandom
rndx		lda     #01
            inca
            sta     rndx+1
rnda		eora    #00
rndc		eora    #00
            sta     rnda+1
rndb        adda    #00
            sta     rndb+1
            lsra
            adda    rndc+1
            eora    rnda+1
            sta     rndc+1
            sta     rndx+1
            rts
;}  


;*******************************************************************************
;*                                                                             *
;*          Variables which do not need to reside in DP                        *
;*                                                                             *
;*******************************************************************************
;{          
CipherTXT   zmb     1               ; Cipher char
HScrUnit    zmb     1               ; High Scoreboard - units value
HScrTen     zmb     1               ; High Scoreboard - tens value
HScrHund    zmb     1               ; High Scoreboard - hundreds value
HScrThou    zmb     1               ; High Scoreboard - thousandths value
HScrTenTh   zmb     1               ; High Scoreboard - ten-thousandths value
PrintAtLoc  zmb     2               ; Print  Location
StringLoc   zmb     2               ; String location in memory (Print-At)

nointernet  fcn     'NO INTERNET'            
gameover    fcn     'GAME OVER'
gamepaused  fcn     'GAME PAUSED'
blank       fcn     '                                '
highscore   fcn     'HI:00000'
titletext   fcn     'RUN DINO RUN'
title1      fcn     'BY'
title2      fcn     'PAUL FISCARELLI'
title3      fcn     '3-VOICE MUSIC PLAYER'
title4      fcn     ' AND'
title5      fcn     'ADVISOR OF MADNESS'
title6      fcn     'SIMON JONASSEN'
othertxt1   fcn     '**************************'
othertxt2   fcn     '************************'


            include	    ".\include\dinorun\dinofont.asm"
            include	    ".\include\dinorun\dinosprites.asm"
            
            align   $100
            
pic         includebin  ".\include\dinorun\dinomnt.raw"
endpic      equ     *

dinopic     includebin  ".\include\dinorun\dinorun.raw"
enddinopic  equ     *

;*******************************************************************************
;*                                                                             *
;*          12 note per octave frequency table 8.4Khz                          *
;*                                                                             *
;*******************************************************************************
;{          freqtab
freqtab     align   $100

            fdb     0,70,75,79,83,88,94,99,105,111,118,125
            fdb     133,141,149,158,167,177,188,199,211,223,237,251
            fdb     266,282,298,316,335,355,376,398,422,447,474,502
            fdb     532,563,597,632,670,710,752,796,844,894,947,1003
            fdb     1063,1126,1193,1264,1339,1419,1503,1593,1688,1788,1894,2007
            fdb     2126,2253,2387,2529,2679,2838,3007,3186,3375,3576,3789,4014
            fdb     4252,4505,4773,5057,5358,5676,6014,6371,6750,7152,7577,8028
            fdb     8505,9011,9546,10114,10716,11353,12028,12743,13501,14303,15154,16055
            fdb     17010,18021,19093,20228,21431,22705,24056,25486,27001,28607,30308,32110
;}


dinotune1
            include	    ".\include\dinorun\dinotun1.asm"
dinotune2            
            include	    ".\include\dinorun\dinotun2.asm"
dinotune3            
            include	    ".\include\dinorun\dinotun3.asm"            
            
version     fcn     'v1.1 08-24-19'
            
            end     Start
