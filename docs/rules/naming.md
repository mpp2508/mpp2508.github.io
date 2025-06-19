---
title: наименование модулей
parent: правила
nav_order: 1
---
Наименование модулей mpp2508
ㅤСостоит из таких частейразделенных нижним подчеркиванием:
- разработчик
- префикс mpp, показывающего принадлежность к номенклатуре mpp2508.
- до трех символов принадлежности к функционалоной группе, согдасно таблице. 
- наименование основного компонента
- дополнительные данные, для выделения данного наименования, если без него, наиминование повторится

|1	|2	|3	|			|
|:--|:--|:--| :-------- |
|b	|xx	|yy	|основа, где xx,yy - размерность с лидирующими нулями						
|m	|	|	|отладочные платы с микроконтроллерами  							
| 	|a	|v	|AVR (Atmel/Microchip)	
| 	|a	|r	|ARM Cortex-M (разработка ARM, производят разные компании)	
| 	|p	|c	|PIC (Microchip)
| 	|5	|1	|8051 (Intel и клоны)	
| 	|r	|v	|RISC-V (открытая архитектура)
| 	|e	|s	|ESP (Espressif Systems)	
| 	|e	|s	|Renesas RX и RL78	
|a	|	|	|(adaptor) переходники  без активных эелементов						
|	|	|	|
|p	|p  |	|(processor) модули разных процессоров 								
|c	|c  |	|communication phy 232 485 usb can ethernet ethercat 3.3v<->5.0v	
|	|	|	|																	
|i	|	|	|ввод даныых														
|-	|m  |	|ручной ввод<br>ручной ввод<br>ручной ввод<br>ручной ввод<br>	
|-	|-	|k  |key, keyboard														
|-	|-	|e  |encoder															
|-	|-	|r  |resistor																	
|-	|a  |	|input analog, discrete, adc 												
|-	|d  |	|input analog, discrete, adc 												
|-	|c  |	|adc (conversion)															
|	|	|	|																			
|o	|	|	|output 															
|	|a	|	|analog output														
|	|d	|	|analog input														
|	|c	|	|dac (conversion)													
|	|g	|	|graphic diplay														
|	|l	|	|n line diplay														
|	|l	|	|n line diplay														
|	|	|	|						