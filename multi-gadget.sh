#!/bin/bash

# Configure the gadget

mkdir /sys/kernel/config/usb_gadget/rpi

echo 0x1d6b > /sys/kernel/config/usb_gadget/rpi/idVendor
echo 0x0104 > /sys/kernel/config/usb_gadget/rpi/idProduct
echo 0x0100 > /sys/kernel/config/usb_gadget/rpi/bcdDevice
echo 0x0200 > /sys/kernel/config/usb_gadget/rpi/bcdUSB

echo 0xEF > /sys/kernel/config/usb_gadget/rpi/bDeviceClass
echo 0x02 > /sys/kernel/config/usb_gadget/rpi/bDeviceSubClass
echo 0x01 > /sys/kernel/config/usb_gadget/rpi/bDeviceProtocol

mkdir /sys/kernel/config/usb_gadget/rpi/strings/0x409
echo 100000000d2386db > /sys/kernel/config/usb_gadget/rpi/strings/0x409/serialnumber
echo "Ikestrom" > /sys/kernel/config/usb_gadget/rpi/strings/0x409/manufacturer
echo "RPiZ Cam" > /sys/kernel/config/usb_gadget/rpi/strings/0x409/product

# Configure the Ethernet

mkdir /sys/kernel/config/usb_gadget/rpi/functions/ecm.1

echo "02:23:45:67:89:ab" > /sys/kernel/config/usb_gadget/rpi/functions/ecm.1/dev_addr
echo "12:23:45:67:89:ab" > /sys/kernel/config/usb_gadget/rpi/functions/ecm.1/host_addr

# Configure the Webcam

mkdir /sys/kernel/config/usb_gadget/rpi/functions/uvc.1

mkdir -p /sys/kernel/config/usb_gadget/rpi/functions/uvc.1/control/header/h
ln -s /sys/kernel/config/usb_gadget/rpi/functions/uvc.1/control/header/h /sys/kernel/config/usb_gadget/rpi/functions/uvc.1/control/class/fs

mkdir -p /sys/kernel/config/usb_gadget/rpi/functions/uvc.1/streaming/mjpeg/m/1080p
cat <<EOF > /sys/kernel/config/usb_gadget/rpi/functions/uvc.1/streaming/mjpeg/m/1080p/dwFrameInterval
333333
666666
1000000
5000000
EOF
cat <<EOF > /sys/kernel/config/usb_gadget/rpi/functions/uvc.1/streaming/mjpeg/m/1080p/wWidth
1920
EOF
cat <<EOF > /sys/kernel/config/usb_gadget/rpi/functions/uvc.1/streaming/mjpeg/m/1080p/wHeight
1080
EOF
cat <<EOF > /sys/kernel/config/usb_gadget/rpi/functions/uvc.1/streaming/mjpeg/m/1080p/dwMinBitRate
10000000
EOF
cat <<EOF > /sys/kernel/config/usb_gadget/rpi/functions/uvc.1/streaming/mjpeg/m/1080p/dwMaxBitRate
100000000
EOF
cat <<EOF > /sys/kernel/config/usb_gadget/rpi/functions/uvc.1/streaming/mjpeg/m/1080p/dwMaxVideoFrameBufferSize
7372800
EOF

mkdir /sys/kernel/config/usb_gadget/rpi/functions/uvc.1/streaming/header/h
cd /sys/kernel/config/usb_gadget/rpi/functions/uvc.1/streaming/header/h
ln -s ../../mjpeg/m
cd ../../class/fs
ln -s ../../header/h
cd ../../class/hs
ln -s ../../header/h
cd ../../../../..

# Create the configs

mkdir /sys/kernel/config/usb_gadget/rpi/configs/c.1
mkdir /sys/kernel/config/usb_gadget/rpi/configs/c.1/strings/0x409
echo 500 > /sys/kernel/config/usb_gadget/rpi/configs/c.1/MaxPower
echo "UVC and ECM Config" > /sys/kernel/config/usb_gadget/rpi/configs/c.1/strings/0x409/configuration

# Link the functions

ln -s /sys/kernel/config/usb_gadget/rpi/functions/uvc.1 /sys/kernel/config/usb_gadget/rpi/configs/c.1/uvc.1
#ln -s /sys/kernel/config/usb_gadget/rpi/functions/ecm.1 /sys/kernel/config/usb_gadget/rpi/configs/c.1/ecm.1

# Bind the driver

udevadm settle -t 5 || :

ls /sys/class/udc > /sys/kernel/config/usb_gadget/rpi/UDC
