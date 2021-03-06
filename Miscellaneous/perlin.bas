'OPEN SOURCE FOREVER
'====================================================
' PSIM-1 (Programmable Synthesizer Interface Module)
'
' Module: PSIM-1 REV1.0B
' Processor Type: Basic Micro - Basic Atom Pro24M
'
'
' Woody Wall 10 Mar 2004
' woody_wall@hotmail.com
'
'
'****************************************************
'                    perlin.bas 
'****************************************************
'
'
' DESCRIPTION:
'   Generates perlin noise. Higher numbered output have
'   higher weighting of high frequencies.
'   IN-1 controls the frequency.
'
'----------------------------------------------------

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
'-------------------------------------------------------
	'Define Variables
	
	LOADDACS	CON 11  ' Pin OUT to DAC LOADDACS
	SERDATA		CON 12  ' Pin OUT Serial Data to DAC (16-bit)
	CLOCK		CON 13  ' Pin OUT to Clock DAC
	STOPLED		CON 9   ' Red LED
	RUNLED		CON 10  ' Green LED
	BSTART		CON 4   ' Start Button
	BSTOP		CON 5   ' Stop  Button
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

	octaves		con 8
	t1			var word
	t2			var word
	t3			var word
	t4			var word
	divisor		var	word
	i			var word
	n			var long
	rand		var long
	intx		var word
	fracx		var word
	v1			var	long
	v2			var long
	incr		var long(octaves)
	x			var long
	inse		var long
	freq		var long(octaves)
	
'**********************************************************************
'Initialize Module

 DIRS = %1111110000000000 ' Configure Pins    1=input  0=output
 OUTS = %1111111111111111 ' Configure State   1=low    0=high

	 
'*****************************************************
' MAIN

low stopled
low runled
for i = 0 to (octaves - 1)
	freq(i) = 0
next


main:
	gosub scanadc
	incr(0) = adc1v / octaves
	if incr(0) = 0 then
		incr(0) = 1
	endif
	for i = 1 to (octaves - 1)
		incr(i) = incr(i - 1) * 2
	next
	t1 = 0
	t2 = 0
	t3 = 0
	t4 = 0
	divisor = 1

	for i = 0 to (octaves - 1)
		debug [dec i, 13]
		x = freq(i)
		gosub inoise
		freq(i) = freq(i) + incr(i)		;Increment pointers
		t1 = t1 + inse / divisor
		t2 = t2 + inse / (i + 1)
		t3 = t3 + inse
		t4 = t4 + inse / (octaves - i)
		divisor = divisor * 2
	next
	dac1v = t1 / octaves
	dac2v = t2 / octaves
	dac3v = t3 / octaves
	dac4v = t4 / octaves
	gosub loadalldacs
	goto main
	
end


inoise:
	intx = x / 0x0400
	fracx = x & 0x03ff
	n = (intx * intx) & 0x03ff
	gosub rng
	v1 = rand
	intx = intx + 1
	n = (intx * intx) & 0x03ff
	gosub rng
	v2 = rand
	inse = (v1 * (0x03ff - fracx) + v2 * fracx) / 0x03ff
	return

rng:
	rand = (1485 * n + 865) & 0x0fff
	return
	
'*******************************************************************
'************************** SUBROUTINES ****************************
' by Grant Richter of Wiard Synthesizer Company as of 17 Jan 2004
'                 ALL FOUR channels are touched 
'*******************************************************************

LOADALLDACS:
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
 	
SCANADC:
	'load buffers with actual a/d values
	ADIN ADC1, ADC1V
	ADIN ADC2, ADC2V
	ADIN ADC3, ADC3V
	ADIN ADC4, ADC4V
	RETURN
