#!/bin/bash
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
echo "RPi USB Device" > /sys/kernel/config/usb_gadget/rpi/strings/0x409/product
mkdir /sys/kernel/config/usb_gadget/rpi/configs/c.1
mkdir /sys/kernel/config/usb_gadget/rpi/configs/c.1/strings/0x409
echo 500 > /sys/kernel/config/usb_gadget/rpi/configs/c.1/MaxPower
echo "UVC" > /sys/kernel/config/usb_gadget/rpi/configs/c.1/strings/0x409/configuration

mkdir /sys/kernel/config/usb_gadget/rpi/functions/uvc.usb0
mkdir /sys/kernel/config/usb_gadget/rpi/functions/ecm.usb0

mkdir -p /sys/kernel/config/usb_gadget/rpi/functions/uvc.usb0/control/header/h
ln -s /sys/kernel/config/usb_gadget/rpi/functions/uvc.usb0/control/header/h /sys/kernel/config/usb_gadget/rpi/functions/uvc.usb0/control/class/fs

mkdir -p /sys/kernel/config/usb_gadget/rpi/functions/uvc.usb0/streaming/mjpeg/m/1080p
cat <<EOF > /sys/kernel/config/usb_gadget/rpi/functions/uvc.usb0/streaming/mjpeg/m/1080p/dwFrameInterval
333333
666666
1000000
5000000
EOF
cat <<EOF > /sys/kernel/config/usb_gadget/rpi/functions/uvc.usb0/streaming/mjpeg/m/1080p/wWidth
1920
EOF
cat <<EOF > /sys/kernel/config/usb_gadget/rpi/functions/uvc.usb0/streaming/mjpeg/m/1080p/wHeight
1080
EOF
cat <<EOF > /sys/kernel/config/usb_gadget/rpi/functions/uvc.usb0/streaming/mjpeg/m/1080p/dwMinBitRate
10000000
EOF
cat <<EOF > /sys/kernel/config/usb_gadget/rpi/functions/uvc.usb0/streaming/mjpeg/m/1080p/dwMaxBitRate
100000000
EOF
cat <<EOF > /sys/kernel/config/usb_gadget/rpi/functions/uvc.usb0/streaming/mjpeg/m/1080p/dwMaxVideoFrameBufferSize
7372800
EOF

mkdir /sys/kernel/config/usb_gadget/rpi/functions/uvc.usb0/streaming/header/h
cd /sys/kernel/config/usb_gadget/rpi/functions/uvc.usb0/streaming/header/h
ln -s ../../mjpeg/m
cd ../../class/fs
ln -s ../../header/h
cd ../../class/hs
ln -s ../../header/h
cd ../../../../..

ln -s /sys/kernel/config/usb_gadget/rpi/functions/uvc.usb0 /sys/kernel/config/usb_gadget/rpi/configs/c.1/uvc.usb0
ln -s /sys/kernel/config/usb_gadget/rpi/functions/ecm.usb0 /sys/kernel/config/usb_gadget/rpi/configs/c.1/ecm.usb0
udevadm settle -t 5 || :
ls /sys/class/udc > /sys/kernel/config/usb_gadget/rpi/UDC

