## ============================================================
## TERRA SENSE - WORKER SAFETY BAND
## DIGILENT ARTY A7-100T
##
## FPGA:
##     XC7A100TCSG324-1
##
## OLED:
##     Digilent Pmod OLEDrgb
##     SSD1331 - 96x64 RGB OLED
##     Connected to JB
## ============================================================


## ============================================================
## FPGA CONFIGURATION
## ============================================================

set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]


## ============================================================
## SYSTEM CLOCK
##
## Arty A7 100 MHz oscillator
## FPGA pin: E3
## ============================================================

set_property -dict {
    PACKAGE_PIN E3
    IOSTANDARD LVCMOS33
} [get_ports {clk100mhz}]

create_clock -add \
    -name sys_clk_100MHz \
    -period 10.00 \
    -waveform {0 5} \
    [get_ports {clk100mhz}]


## ============================================================
## SYSTEM RESET
##
## Arty A7 button
## FPGA pin: C9
## ============================================================

set_property -dict {
    PACKAGE_PIN C9
    IOSTANDARD LVCMOS33
} [get_ports {rst}]


## ============================================================
## LOCAL SOS BUTTON
##
## Arty A7 button
## FPGA pin: D9
## ============================================================

set_property -dict {
    PACKAGE_PIN D9
    IOSTANDARD LVCMOS33
} [get_ports {sos_btn}]


## ============================================================
## ESP32 UART RX
##
## ESP32 GPIO17 / TX2
##        |
##        v
## FPGA JA1 / G13
## ============================================================

set_property -dict {
    PACKAGE_PIN G13
    IOSTANDARD LVCMOS33
} [get_ports {uart_rx}]


## ============================================================
## ESP32 UART TX
##
## FPGA JA2 / B11
##        |
##        v
## ESP32 GPIO16 / RX2
## ============================================================

set_property -dict {
    PACKAGE_PIN B11
    IOSTANDARD LVCMOS33
} [get_ports {uart_tx}]


## ============================================================
## EXTERNAL BUZZER
##
## FPGA JA3
## FPGA pin: A11
## ============================================================

set_property -dict {
    PACKAGE_PIN A11
    IOSTANDARD LVCMOS33
} [get_ports {buzzer}]


## ============================================================
## ARGB LED
##
## Arty RGB LED
##
## RED   = G6
## GREEN = F6
## BLUE  = E1
##
## Driven HIGH for ON
## ============================================================

set_property -dict {
    PACKAGE_PIN G6
    IOSTANDARD LVCMOS33
} [get_ports {led_r}]

set_property -dict {
    PACKAGE_PIN F6
    IOSTANDARD LVCMOS33
} [get_ports {led_g}]

set_property -dict {
    PACKAGE_PIN E1
    IOSTANDARD LVCMOS33
} [get_ports {led_b}]


## ============================================================
## DIGILENT PMOD OLED RGB
##
## Pmod OLEDrgb
## SSD1331
## 96 x 64 RGB OLED
##
## Connected to:
##     Arty A7 JB
##
## ------------------------------------------------------------
## Pmod pin     Signal       Arty JB       FPGA pin
## ------------------------------------------------------------
##
##    1         CS           JB1           E15
##    2         MOSI         JB2           E16
##    3         NC           JB3           D15
##    4         SCK          JB4           C15
##    5         GND
##    6         VCC
##    7         D/C          JB7           J17
##    8         RES          JB8           J18
##    9         VCCEN        JB9           K15
##   10         PMODEN       JB10          J15
##   11         GND
##   12         VCC
##
## ============================================================


## ------------------------------------------------------------
## OLED CHIP SELECT
##
## Pmod pin 1
## JB1
## FPGA pin E15
## ------------------------------------------------------------

set_property -dict {
    PACKAGE_PIN E15
    IOSTANDARD LVCMOS33
} [get_ports {oled_cs}]


## ------------------------------------------------------------
## OLED MOSI
##
## Pmod pin 2
## JB2
## FPGA pin E16
## ------------------------------------------------------------

set_property -dict {
    PACKAGE_PIN E16
    IOSTANDARD LVCMOS33
} [get_ports {oled_mosi}]


## ------------------------------------------------------------
## Pmod pin 3
##
## NC
## JB3 = D15
##
## No FPGA signal required.
## ------------------------------------------------------------


## ------------------------------------------------------------
## OLED SPI CLOCK
##
## Pmod pin 4
## JB4
## FPGA pin C15
## ------------------------------------------------------------

set_property -dict {
    PACKAGE_PIN C15
    IOSTANDARD LVCMOS33
} [get_ports {oled_sck}]


## ------------------------------------------------------------
## Pmod pin 5
##
## GND
## ------------------------------------------------------------


## ------------------------------------------------------------
## Pmod pin 6
##
## VCC
## 3.3 V
## ------------------------------------------------------------


## ------------------------------------------------------------
## OLED DATA / COMMAND
##
## Pmod pin 7
## JB7
## FPGA pin J17
## ------------------------------------------------------------

set_property -dict {
    PACKAGE_PIN J17
    IOSTANDARD LVCMOS33
} [get_ports {oled_dc}]


## ------------------------------------------------------------
## OLED RESET
##
## Pmod pin 8
## JB8
## FPGA pin J18
## ------------------------------------------------------------

set_property -dict {
    PACKAGE_PIN J18
    IOSTANDARD LVCMOS33
} [get_ports {oled_res}]


## ------------------------------------------------------------
## OLED VCC ENABLE
##
## Pmod pin 9
## JB9
## FPGA pin K15
## ------------------------------------------------------------

set_property -dict {
    PACKAGE_PIN K15
    IOSTANDARD LVCMOS33
} [get_ports {oled_vccen}]


## ------------------------------------------------------------
## OLED PMOD ENABLE
##
## Pmod pin 10
## JB10
## FPGA pin J15
## ------------------------------------------------------------

set_property -dict {
    PACKAGE_PIN J15
    IOSTANDARD LVCMOS33
} [get_ports {oled_pmoden}]


## ------------------------------------------------------------
## Pmod pin 11
##
## GND
## ------------------------------------------------------------


## ------------------------------------------------------------
## Pmod pin 12
##
## VCC
## 3.3 V
## ------------------------------------------------------------


## ============================================================
## END OF XDC
## ============================================================
