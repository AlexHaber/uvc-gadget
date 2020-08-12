#!/bin/bash

GADGETS_DIR="rpi"
USB_VID="0x1d6b"
USB_PID="0x0104"
SERIAL_NUMBER="100000000d2386db"
MANUFACTURER="AlexHaber"
PRODUCT="RPiZ Cam"

USE_RNDIS=true
USE_ECM=true
USE_UVC=true

cd /sys/kernel/config/usb_gadget
mkdir -p $GADGETS_DIR
cd $GADGETS_DIR

# configure gadget details
# =========================
echo $USB_VID > idVendor  # Set Vendor ID
echo $USB_PID > idProduct # Set Product ID
echo 0x0100 > bcdDevice   # Set Device Version 1.0.0
echo 0x0200 > bcdUSB      # Set USB mode to USB 2.0
    
# Composite class / subclass / proto (needs single configuration)
echo 0xEF > bDeviceClass
echo 0x02 > bDeviceSubClass
echo 0x01 > bDeviceProtocol

# set device descriptions
mkdir -p strings/0x409 # English language strings
echo $SERIAL_NUMBER > strings/0x409/serialnumber # Set Serial
echo $MANUFACTURER > strings/0x409/manufacturer  # Set Manufacturer
echo $PRODUCT > strings/0x409/product            # Set Product

# Create Configuration Instance
# ================================================================================================================================
mkdir -p configs/c.1/strings/0x409
echo "UVC, RNDIS, ECM Config" > configs/c.1/strings/0x409/configuration
echo 500 > configs/c.1/MaxPower
#echo 0xC0 > configs/c.1/bmAttributes # self powered device

# Create RNDIS function
# =======================================================
if $USE_RNDIS; then
    mkdir -p functions/rndis.usb0
    echo "42:63:65:13:34:56" > functions/rndis.usb0/host_addr # set up mac address of remote device
    echo "42:63:65:66:43:21" > functions/rndis.usb0/dev_addr  # set up local mac address
fi

# Create CDC ECM function
# =======================================================
if $USE_ECM; then
    mkdir -p functions/ecm.usb1
    echo "42:63:65:12:34:56" > functions/ecm.usb1/host_addr # set up mac address of remote device
    echo "42:63:65:65:43:21" > functions/ecm.usb1/dev_addr  # set up local mac address
fi

# Create UVC function
# =======================================================
if $USE_UVC; then
    mkdir -p functions/uvc.usb0
    mkdir -p functions/uvc.usb0/control/header/h
    ln -s functions/uvc.usb0/control/header/h functions/uvc.usb0/control/class/fs
    mkdir -p functions/uvc.usb0/streaming/mjpeg/m/1080p

    # Set Settings
    cat <<- EOF > functions/uvc.usb0/streaming/mjpeg/m/1080p/dwFrameInterval
    333333
    666666
    1000000
    5000000
    EOF
    cat 1920 > functions/uvc.usb0/streaming/mjpeg/m/1080p/wWidth
    cat 1080 > functions/uvc.usb0/streaming/mjpeg/m/1080p/wHeight
    cat 10000000 > functions/uvc.usb0/streaming/mjpeg/m/1080p/dwMinBitRate
    cat 100000000 > functions/uvc.usb0/streaming/mjpeg/m/1080p/dwMaxBitRate
    cat 7372800 > functions/uvc.usb0/streaming/mjpeg/m/1080p/dwMaxVideoFrameBufferSize
    
    mkdir functions/uvc.usb0/streaming/header/h
    ln -s functions/uvc.1/streaming/mjpeg/m functions/uvc.1/streaming/header/h
    ln -s functions/uvc.1/streaming/header/h functions/uvc.1/streaming/class/fs
    ln -s functions/uvc.1/streaming/header/h functions/uvc.1/streaming/class/hs
fi

# add OS specific device descriptors to force Windows to load RNDIS drivers
# =============================================================================
# Witout this additional descriptors, most Windows system detect the RNDIS interface as "Serial COM port"
# To prevent this, the Microsoft specific OS descriptors are added in here
# !! Important:
#   If the device already has been connected to the Windows System without providing the
#   OS descriptor, Windows never asks again for them and thus never installs the RNDIS driver
#   This behavior is driven by creation of an registry hive, the first time a device without 
#   OS descriptors is attached. The key is build like this:
#
#   HKLM\SYSTEM\CurrentControlSet\Control\usbflags\[USB_VID+USB_PID+bcdRelease\osvc
#
#   To allow Windows to read the OS descriptors again, the according registry hive has to be
#   deleted manually or USB descriptor values have to be changed (e.g. USB_PID).
if $USE_RNDIS; then
    mkdir -p os_desc
    echo 1 > os_desc/use
    echo 0xbc > os_desc/b_vendor_code
    echo MSFT100 > os_desc/qw_sign

    mkdir -p functions/rndis.usb0/os_desc/interface.rndis
    echo RNDIS > functions/rndis.usb0/os_desc/interface.rndis/compatible_id
    echo 5162001 > functions/rndis.usb0/os_desc/interface.rndis/sub_compatible_id
fi

# bind function instances to respective configuration
# ====================================================

if $USE_RNDIS; then
    ln -s functions/rndis.usb0 configs/c.1/ # RNDIS has to be the first interface on Composite device
fi

if $USE_UVC; then 
    ln -s functions/uvc.usb0 configs/c.1/
fi

if $USE_ECM; then
    ln -s functions/ecm.usb1 configs/c.1/
fi

if $USE_RNDIS; then
    ln -s configs/c.1/ os_desc # add config 1 to OS descriptors
fi

udevadm settle -t 5 || :

# check for first available UDC driver
UDC_DRIVER=$(ls /sys/class/udc | cut -f1 | head -n 1)
# bind USB gadget to this UDC driver
echo $UDC_DRIVER > UDC
