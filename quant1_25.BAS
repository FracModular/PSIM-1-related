'---------------------------------------------
'PUBLIC DOMAIN
'---------------------------------------------
'
'*****************************************************************
' Module: PSIM-1 REV1b
' Processor Type: Basic Micro - Basic Atom Pro24M
' Description: Quad 25 Step quantizer
' For 0-5 volt input - great for Fat Controller!
' Easily altered for 0-10 volt input (see line #122)
' Choose your own 25 notes for each output (see line #126)
' Chords can be generated by using multiple outputs
' Instructions: Press START
' IN 1 = Raw voltage input
' OUT 1-4 = One of 25 voltages from chosen note set
'
' Developed by Oozitron aka Andrew Scheidler
' Email: oozitron (at) gmail.com
' Special Thanks to Paul Perry for the Fat Controller
' Revision Date: 2005/3/15 11:07 PM
'*****************************************************************

' Basic Micro Atom Pro-24M Configuration
'
' (Note: P0 is I/O 0 and NOT pin 0 on the microprocessor.)
'
' P0 - Analog IN-1 (0-5 VDC)
' P1 - Analog IN-2 (0-5 VDC)
' P2 - Analog IN-3 (0-5 VDC)
' P3 - Analog IN-4 (0-5 VDC)
' P4 - START Button (Momentary Normally Open Switch)
' P5 - STOP Button (Momentary Normally Open Switch)
' P6 - I2C/SDA (Reserved) - J3 Pin 1
' P7 - I2C/SDL (Reserved) - J3 Pin 2
' P8 - AUX (Digital I/O - NO BUFFERING)
' P9 - STOP LED
' P10 - RUN LED
' P11 - DAC - LOADDACS
' P12 - DAC - SERDATA
' P13 - DAC - CLOCK
' P14 - RXD (Reserved) - J5 Pin 1
' P15 - TXD (Reserved) - J5 Pin 2

'********************************************************************* ***
'Define Variables

LOADDACS CON 11 ' Pin OUT to DAC LOADDACS
SERDATA CON 12 ' Pin OUT Serial Data to DAC (16-bit)
CLOCK CON 13 ' Pin OUT to Clock DAC
STOPLED CON 9 ' Red LED
RUNLED CON 10 ' Green LED
BSTART CON 5 ' Start Button
BSTOP CON 4 ' Stop Button
AUX CON 8
ADC1 CON 0
ADC2 CON 1
ADC3 CON 2
ADC4 CON 3
MINFREQ CON 0 ' DAC - Sets to 0 VDC
MAXFREQ CON 4095 ' Maximum value for 12-bit DAC is 4096 (or 0 TO 4095)


RAWDAC1 VAR WORD ' RAW DAC DATA 1
RAWDAC2 VAR WORD ' RAW DAC DATA 2
RAWDAC3 VAR WORD ' RAW DAC DATA 3
RAWDAC4 VAR WORD ' RAW DAC DATA 4
DAC1V VAR WORD ' DAC Value to be Sent to DAC Channel
DAC2V VAR WORD ' DAC Value to be Sent to DAC Channel
DAC3V VAR WORD ' DAC Value to be Sent to DAC Channel
DAC4V VAR WORD ' DAC Value to be Sent to DAC Channel
ADC1V VAR WORD ' Value of Analog IN-1
ADC2V VAR WORD ' Value of Analog IN-2
ADC3V VAR WORD ' Value of Analog IN-3
ADC4V VAR WORD ' Value of Analog IN-4
I VAR WORD ' Misc counting variable
TEMPO VAR WORD ' TEMPO=1 Is Equal to 0.5ms ??? (Value 0 to 254)
BPM VAR BYTE ' Beats Per Minute (Value 0 to 254)
TONE VAR WORD ' Frequency in Hertz
FREQ VAR WORD ' Temporary Frequency Counter
WORK VAR BYTE ' Workspace for BUTTON instruction.
INDEX VAR BYTE

' My Variables
ADC1VHOLD VAR WORD ' Holds last unchanged value of Analog IN-1
I1 VAR WORD ' Note number for IN-1
I2 VAR WORD ' Note number for IN-2
I3 VAR WORD ' Note number for IN-3
I4 VAR WORD ' Note number for IN-4

'********************************************************************* ***
'Initialize Module

DIRS = %1111110000000000 ' Configure Pins 1=input 0=output
OUTS = %1111111111111111 ' Configure State 1=low 0=high

WORK=0
TONE=440 ' Change this to frequency in Hz. to output from the AUX jack.
' This can be used as a tuning frequency to beat your VCO's
' against.

'BPM=300 ' Change this to how ever many Beats Per Minute you want.
'TEMPO=60000/BPM ' Do not change

GOSUB INIT

'********************************************************************* ***

LOW STOPLED
LOW RUNLED

ADC1VHOLD = 0

RUN:
GOSUB SCANADC

' this ignores very slight changes to stop jitter
IF ABS(ADC1VHOLD-ADC1V) > 3 THEN
ADC1VHOLD = ADC1V
ENDIF

' for 0-5v use "/ 21" for 0-10v use "/ 42"
I1 = ADC1VHOLD / 21

' choose your output notes (voltages) by altering the numbers in the brackets (32 = half step)
' notes do not have to be ascending and can be repeated as desired
LOOKUP I1,[288,384,448,224,448,512,288,512,608,672,768,832,832,896,896,992,10 56,1152,1216,1216,1280,1280,1376,1440,3968],DAC1V
LOOKUP I1,[288,384,448,224,448,512,288,512,608,672,768,832,832,896,896,992,10 56,1152,1216,1216,1280,1280,1376,1440,3968],DAC2V
LOOKUP I1,[288,384,448,224,448,512,288,512,608,672,768,832,832,896,896,992,10 56,1152,1216,1216,1280,1280,1376,1440,3968],DAC3V
LOOKUP I1,[128,192,256,320,384,448,512,576,640,704,768,832,896,960,1024,1088, 1152,1216,1280,1344,1408,1472,1536,1600,1664],DAC4V

GOSUB LOADALLDACS
GOTO RUN

'********************************************************************* ***
' SUBROUTINES - DO NOT MODIFY!
'********************************************************************* ***

INIT:' by Brice D. Hornback - http://www.SynthModules.com
' Resets DAC values, flashes LEDs, then waits for Start button.
LOW RUNLED
GOSUB RESETDAC

FOR I=1 TO 12
TOGGLE RUNLED
PAUSE 50
TOGGLE STOPLED
PAUSE 50
NEXT
LOOP1:
TOGGLE STOPLED
PAUSE 100
IF IN4 = 1 THEN RUN
IF IN5 = 1 THEN ENDLOOP1
GOTO LOOP1
ENDLOOP1:
RETURN


RESETDAC:' by Brice D. Hornback - http://www.SynthModules.com
'Sets all DAC channels to 0V and refreshes all four DAC channels.
DAC1V=0
DAC2V=0
DAC3V=0
DAC4V=0
GOSUB LOADALLDACS
RETURN

LOADALLDACS: ' by Grant Richter of Wiard Synthesizer Company as of 17 Jan 2004
'Add addresses to values no speed improve with OR over +
RAWDAC1=DAC1V+49152
RAWDAC2=DAC2V+32768
RAWDAC3=DAC3V+16384
RAWDAC4=DAC4V
'shift out 16 bits mode 4 gotta bang loaddacs pin for each channel
'skew from ch. 1 to 4 = 400 usecs. Aprox 1 msec execution time for sub.
SHIFTOUT SERDATA,CLOCK,4,[RAWDAC1\16]
PULSOUT LOADDACS,1
SHIFTOUT SERDATA,CLOCK,4,[RAWDAC2\16]
PULSOUT LOADDACS,1
SHIFTOUT SERDATA,CLOCK,4,[RAWDAC3\16]
PULSOUT LOADDACS,1
SHIFTOUT SERDATA,CLOCK,4,[RAWDAC4\16]
PULSOUT LOADDACS,1
RETURN

SCANADC:' by Grant Richter of Wiard Synthesizer Company as of 17 Jan 2004
'load buffers with actual a/d values
ADIN ADC1, ADC1V
ADIN ADC2, ADC2V
ADIN ADC3, ADC3V
ADIN ADC4, ADC4V
RETURN

ENDPROGRAM: ' by Brice D. Hornback - http://www.SynthModules.com
' Resets all four DAC channels to 0V and runs INIT subroutine
LOW RUNLED
HIGH STOPLED
GOSUB RESETDAC
GOTO INIT
