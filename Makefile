all:
	./build.sh

# You probably don't want to run this, I only use it for local usb stick testing
usb:
	sudo umount /media/ianblenke/COS_LIVE || true
	sudo dd if=build/build/kairos.iso of=/dev/sdk bs=4M

