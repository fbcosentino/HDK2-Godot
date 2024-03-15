import pywinusb.hid as hid
from time import sleep
from struct import pack, unpack
import math

# HID\VID_1532&PID_0B00&REV_0100&MI_02
vendor_id = 0x1532
product_id = 0x0b00

devices = hid.HidDeviceFilter(vendor_id=vendor_id, product_id=product_id).get_devices()


"""
https://github.com/OSVR/OSVR-Docs/blob/master/Developing/OSVRhdk.md

HID packet:

0:
   Bits 0:3 : Report version number, currently 3
   Version 3 only: bit 4: "1" if video is detected and "0" if not.
   Version 3 only: bit 5: "1" if portrait mode (1080x1920 video) is detected and "0" if landscape (1920x1080).
1: message sequence number (8 bit)
2: Unit quaternion i component LSB
3: Unit quaternion i component MSB
4: Unit quaternion j component LSB
5: Unit quaternion j component MSB
6: Unit quaternion k component LSB
7: Unit quaternion k component MSB
8: Unit quaternion real component LSB
9: Unit quaternion real component MSB

10-11: Gyroscope X axis velocity in radians/seconds
12-13: Gyroscope Y axis velocity in radians/seconds
14-15: Gyroscope Z axis velocity in radians/seconds
16-31: reserved for future use or not transmitted
"""

def euler_from_quaternion(x, y, z, w):
        """
        Convert a quaternion into euler angles (roll, pitch, yaw)
        roll is rotation around x in radians (counterclockwise)
        pitch is rotation around y in radians (counterclockwise)
        yaw is rotation around z in radians (counterclockwise)
        """
        t0 = +2.0 * (w * x + y * z)
        t1 = +1.0 - 2.0 * (x * x + y * y)
        roll_x = math.atan2(t0, t1)
     
        t2 = +2.0 * (w * y - z * x)
        t2 = +1.0 if t2 > +1.0 else t2
        t2 = -1.0 if t2 < -1.0 else t2
        pitch_y = math.asin(t2)
     
        t3 = +2.0 * (w * z + x * y)
        t4 = +1.0 - 2.0 * (y * y + z * z)
        yaw_z = math.atan2(t3, t4)
     
        return roll_x, pitch_y, yaw_z # in radians

def make_int_from_2bytes(byte1, byte2):
    b = bytes((byte1,byte2))
    src_i = int.from_bytes(b, byteorder='little', signed=True)
    f = (src_i & 0b11111111111111)/16384.0
    i = src_i >> 14
    return i + f

last_euler = None
def hdk2_decode(data):
    global last_euler
    
    # data[2] -> sequence number. For now we just ignore
    
    i = (make_int_from_2bytes(data[3], data[4]))
    j = (make_int_from_2bytes(data[5], data[6]))
    k = (make_int_from_2bytes(data[7], data[8]))
    r = (make_int_from_2bytes(data[9], data[10]))
    
    euler = euler_from_quaternion(i, j, k, r)
    
    # euler[0] -> pitch
    # euler[1] -> roll
    # euler[2] -> yaw
    
    last_euler = euler


def sample_handler(data):
    hdk2_decode(data)
    #print("Raw data: {0}".format(data))

if devices:
    device = devices[0]
    print("success")

    device.open()
    device.set_raw_data_handler(sample_handler)

    
    while device.is_plugged():
        if last_euler is not None:
            print("Pitch: "+str(last_euler[0])+"    Yaw:  "+str(last_euler[2])+"    Roll: "+str(last_euler[1]))
            sleep(0.01) # 100 Hz
