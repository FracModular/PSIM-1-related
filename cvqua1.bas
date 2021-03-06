'---------------------------------------------
'PUBLIC DOMAIN
'---------------------------------------------

'*******************************************************************
'********************* JIBBER JABBER *******************************
'*******************************************************************

'*****************************************************
' PSIM-1 (Programmable Synthesizer Interface Module)
'
' Module: PSIM-1 REV1b
' Revision Date:  2004/01/17  5:47 AM
' Processor Type: Basic Micro - Basic Atom Pro24M
'
'
' Basic Program Developed by Grant Richter
' modified by dr manbuse 26 Jan 2004
' Special thanks to Brice for his assistance.
'
' Description:
' 4 channel chromatic quantizer
' with Voltage controlled resolution
'
'*****************************************************

' Basic Micro Atom Pro-24M Configuration
'
' (Note: P0 is I/O 0 and NOT pin 0 on the microprocessor.)
'
' P0 -  Analog IN-1 (0-5 VDC)
' P1 -  Analog IN-2 (0-5 VDC)
' P2 -  Analog IN-3 (0-5 VDC)
' P3 -  Analog IN-4 (0-5 VDC)
' P4 -  START Button (Momentary Normally Open Switch)
' P5 -  STOP  Button (Momentary Normally Open Switch)
' P6 -  I2C/SDA (Reserved) - J3 Pin 1
' P7 -  I2C/SDL (Reserved) -  J3 Pin 2
' P8 -  AUX (Digital I/O - NO BUFFERING)
' P9 -  STOP LED
' P10 - RUN LED
' P11 - DAC - LOADDACS
' P12 - DAC - SERDATA
' P13 - DAC - CLOCK
' P14 - RXD (Reserved) - J5 Pin 1 (Midi)
' P15 - TXD (Reserved) - J5 Pin 2 (Midi)
'*****************************************************
	'Define Variables
	
	LOADDACS	CON 11  ' Pin OUT to DAC LOADDACS
	SERDATA		CON 12  ' Pin OUT Serial Data to DAC (16-bit)
	CLOCK		CON 13  ' Pin OUT to Clock DAC
	STOPLED		CON 9   ' Red LED
	RUNLED		CON 10  ' Green LED
	BSTART		CON 5   ' Start Button
	BSTOP		CON 4   ' Stop  Button
	AUX			CON 8	' AUX Jack (unbuffered)

	RAWDAC1  	VAR WORD  ' RAW DAC DATA 1 
	RAWDAC2  	VAR WORD  ' RAW DAC DATA 2 
	RAWDAC3  	VAR WORD  ' RAW DAC DATA 3 
	RAWDAC4  	VAR WORD  ' RAW DAC DATA 4 

	DAC1V  		VAR WORD  ' DAC Value to be Sent to DAC Channel
	DAC2V  		VAR WORD  ' DAC Value to be Sent to DAC Channel
	DAC3V  		VAR WORD  ' DAC Value to be Sent to DAC Channel
	DAC4V  		VAR WORD  ' DAC Value to be Sent to DAC Channel
	
	ADC1		CON 0
	ADC2		CON	1
	ADC3		CON 2
	ADC4		CON 3

	ADC1V		VAR WORD	'INPUT A/D BUFFER CH. 1
	ADC2V		VAR WORD	'INPUT A/D BUFFER CH. 2
	ADC3V		VAR WORD	'INPUT A/D BUFFER CH. 3
	ADC4V		VAR WORD	'INPUT A/D BUFFER CH. 4
	
	DIVISOR     VAR WORD

	'*****************************************************
	'Initialize Module

	 DIRS = %1111110000000000 ' Configure Pins    1=input  0=output
	 OUTS = %1111111111111111 ' Configure State   1=low    0=high
	'*****************************************************

	LOW STOPLED
	HIGH RUNLED

'*******************************************************************
'*************** APPLICATION CODE START ****************************
'*******************************************************************

START:
	ADIN ADC1, ADC1V;get base CV from ch1 in
	ADIN ADC2, ADC2V; get increment value from ch2 in
	DIVISOR = (ADC2V +1 )/64; '+1' precaution againts 0 division, '/64'= increment scaling factor
	RAWDAC1=((ADC1V/DIVISOR)*32)+49152; quantization by divisor
	SHIFTOUT SERDATA,CLOCK,4,[RAWDAC1\16]; send result  to DAC ch1
 	PULSOUT LOADDACS,1; flush the DAC
 GOTO START
	
