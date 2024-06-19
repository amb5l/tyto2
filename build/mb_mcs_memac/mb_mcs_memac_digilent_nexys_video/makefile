CPU_VARIANT=
DESIGN=mb_mcs_memac
PHY=rtl8211
PHY_IF=rgmii
BOARD=digilent_nexys_video
FPGA=xilinx 7series xc7a200tsbg484-1
# RTL8211 RX delay is disabled so FPGA must output a center aligned TX clock
MEMAC_RGMII_TX_ALIGN="CENTER"
# RTL8211 TX delay is disabled so FPGA must accept an edge aligned RX clock
MEMAC_RGMII_RX_ALIGN="EDGE"
MEMAC_TX_BUF_SIZE=8192
MEMAC_RX_BUF_SIZE=8192
include ../$(DESIGN).mak
