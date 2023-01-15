# test_packet-vmt.py
# Test message generator for 'Virtual Motion Tracker' packet dissection
#
# Copyright (c) 2021, A.Shiomaneki <a.shiomaneki@gmail.com>
#
# This program is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

import sys
from abc import ABC, abstractmethod
from enum import Enum, auto
import numpy as np
import quaternion
from pythonosc import osc_message_builder
from pythonosc import udp_client


class PosTypes(Enum):
    Room = auto()
    Raw = auto()
    Joint = auto()
    Follow = auto()


class AngleTypes(Enum):
    Unity = auto()
    UEuler = auto()
    Driver = auto()


class BoneSetIndexes(Enum):
    RootAndWrist = 0
    Thumb = 1
    Index = 2
    Middle = 3
    Ring = 4
    Pinky = 5


class BoneIndexes(Enum):
    Root = 0
    Wrist = 1
    Thumb0_ThumbProximal = 2
    Thumb1_ThumbIntermediate = 3
    Thumb2_ThumbDistal = 4
    Thumb3_ThumbEnd = 5
    IndexFinger0_IndexProximal = 6
    IndexFinger1_IndexIntermediate = 7
    IndexFinger2_IndexDistal = 8
    IndexFinger3_IndexDistal2 = 9
    IndexFinger4_IndexEnd = 10
    MiddleFinger0_MiddleProximal = 11
    MiddleFinger1_MiddleIntermediate = 12
    MiddleFinger2_MiddleDistal = 13
    MiddleFinger3_MiddleDistal2 = 14
    MiddleFinger4_MiddleEnd = 15
    RingFinger0_RingProximal = 16
    RingFinger1_RingIntermediate = 17
    RingFinger2_RingDistal = 18
    RingFinger3_RingDistal2 = 19
    RingFinger4_RingEnd = 20
    PinkyFinger0_LittleProximal = 21
    PinkyFinger1_LittleIntermediate = 22
    PinkyFinger2_LittleDistal = 23
    PinkyFinger3_LittleDistal2 = 24
    PinkyFinger4_LittleEnd = 25
    Aux_Thumb_ThumbHelper = 26
    Aux_IndexFinger_IndexHelper = 27
    Aux_MiddleFinger_MiddleHelper = 28
    Aux_RingFinger_RingHelper = 29
    Aux_PinkyFinger_LittleHelper = 30


class InputTypes(Enum):
    Button = auto()
    Trigger = auto()
    Joystick = auto()


class TouchClickTypes(Enum):
    Touch = auto()
    Click = auto()


class DriverControlTypes(Enum):
    Reset = auto()
    LoadSetting = auto()
    SettRoomMatrix = auto()
    Set = auto()
    SetAutoPoseUpdate = auto()
    Get = auto()
    Subscribe = auto()
    Unsubscribe = auto()
    RequestResttart = auto()
    SetDiagLog = auto()
    Config = auto()
    Debug = auto()


class DriverResponnse(Enum):
    Out = auto()


class Vmt(ABC):
    addressPrefix = "/VMT"

    @abstractmethod
    def getOscMessage(self):
        pass


class TrackerControl(Vmt):
    _args = {
        "index": 0,
        "enable": 1,
        "timeoffset": 0.0,
        "x": 1.1,
        "y": 1.2,
        "z": 1.3,
        "qx": 2.1,
        "qy": 2.2,
        "qz": 2.3,
        "qw": 2.4,
    }

    def getArgs(self):
        if self.angle is AngleTypes.UEuler:
            quat = np.quaternion(
                self._args["qx"],
                self._args["qy"],
                self._args["qz"],
                self._args["qw"],
            )
            euler = quaternion.as_euler_angles(quat)
            args = {
                "index": self._args["index"],
                "enable": self._args["enable"],
                "timeoffset": self._args["timeoffset"],
                "x": self._args["x"],
                "y": self._args["y"],
                "z": self._args["z"],
                "rx": euler[0],
                "ry": euler[1],
                "rz": euler[2],
            }
            return args
        else:
            return self._args

    pos: PosTypes
    angle: AngleTypes

    def __init__(self, pos: PosTypes, angle: AngleTypes):
        self.pos = pos
        self.angle = angle

    def getAddress(self):
        return (self.addressPrefix + "/{0}/{1}").format(self.pos.name, self.angle.name)

    def getOscMessage(self):
        address = self.getAddress()
        message = osc_message_builder.OscMessageBuilder(address=address)
        for val in self.getArgs().values():
            message.add_arg(val)
        return message.build()


class TrackerControlOnAnother(TrackerControl):
    def getArgs(self):
        args = super().getArgs()
        args["serial"] = "VMT_001"
        return args


class InputOperation(Vmt):
    input: InputTypes
    touchClick: TouchClickTypes

    def __init__(self, input: InputTypes, touchClick: TouchClickTypes = None):
        self.input = input
        self.touchClick = touchClick

    def getAddress(self):
        address = self.addressPrefix + "/" + self.input.name + \
            "" if self.touchClick is None else "/" + self.touchClick.name
        return address

    def getOscMessage(self):
        address = self.getAddress()
        message = osc_message_builder.OscMessageBuilder(address=address)
        for val in self.getArgs().values():
            message.add_arg(val)
        return message.build()


class InputButton(InputOperation):
    def __init__(self, touchClick: TouchClickTypes = None):
        super().__init__(input=InputTypes.Button, touchClick=touchClick)

    def getArgs(self):
        args = {
            "index": 0,
            "buttonindex": 1,
            "timeoffset": 0.0,
            "value": 1,
        }
        assert type(args["value"]) == int
        return args


class InputTrigger(InputOperation):
    def __init__(self, touchClick: TouchClickTypes = None):
        super().__init__(input=InputTypes.Trigger, touchClick=touchClick)

    def getArgs(self):
        args = {
            "index": 0,
            "buttonindex": 1,
            "timeoffset": 0.0,
            "value": 0.6,
        }
        assert type(args["value"]) == float
        return args


class InputJoystick(InputOperation):
    def __init__(self, touchClick: TouchClickTypes = None):
        super().__init__(input=InputTypes.Joystick, touchClick=touchClick)

    def getArgs(self):
        args = {
            "index": 0,
            "buttonindex": 1,
            "timeoffset": 0.0,
            "x": 0.6,
            "y": -0.3
        }
        assert type(args["x"]) == float
        assert type(args["y"]) == float
        return args


class DriverControl(Vmt):
    def __init__(self, order):
        self.address = self.addressPrefix + "/" + order

    def getAddress(self):
        return self.address

    def getOscMessage(self):
        address = self.getAddress()
        message = osc_message_builder.OscMessageBuilder(address=address)
        return message.build()


class SetRoomMatrix(DriverControl):
    def getRoomMatrix(self):
        json = {"RoomMatrix": [1.0, 0.0, 0.0, 0.0,
                               0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0]}
        return json["RoomMatrix"]

    def getOscMessage(self):
        address = self.getAddress()
        message = osc_message_builder.OscMessageBuilder(address=address)
        for val in self.getRoomMatrix():
            message.add_arg(val)
        return message.build()


class DriverResponse(Vmt):
    def __init__(self, responseType):
        self.address = self.addressPrefix + "/" + responseType

    def getAddress(self):
        return self.address

    @abstractmethod
    def getArgs(self):
        pass

    def getOscMessage(self):
        address = self.getAddress()
        message = osc_message_builder.OscMessageBuilder(address=address)
        for val in self.getArgs().values():
            message.add_arg(val)
        return message.build()


class OutLog(DriverResponse):
    def getArgs(self):
        args = {
            # stat(int): 状態(0=info,1=warn,2=err)
            "stat": 1,
            # msg(string): メッセージ
            "msg": "This is a test message.",
        }
        assert type(args["stat"]) == int
        assert type(args["msg"]) == str
        return args


class OutAlive(DriverResponse):
    def getArgs(self):
        args = {
            # version(string): バージョン
            "version": "VMT_005",
            # installpath(string): ドライバのインストールパス
            "installpath": "C:\\Users\\test\\vmt_005\\vmt",
        }
        assert type(args["version"]) == str
        assert type(args["installpath"]) == str
        return args


class OutHaptic (DriverResponse):
    def getArgs(self):
        args = {
            "index": 0,
            # frequency(float): 周波数
            "frequency": 440.0,
            # amplitude(float): 振幅
            "amplitude": 0.8,
            # duration(float): 長さ
            "duration": 1.2
        }
        assert type(args["index"]) == int
        assert type(args["frequency"]) == float
        assert type(args["amplitude"]) == float
        assert type(args["duration"]) == float
        return args


def getTrackerControlTestMessages():
    messages = []
    for pos in PosTypes:
        for angle in AngleTypes:
            if pos is PosTypes.Joint or pos is PosTypes.Follow:
                msg = TrackerControlOnAnother(
                    pos=pos, angle=angle).getOscMessage()
                messages.append(msg)
            else:
                msg = TrackerControl(pos=pos, angle=angle).getOscMessage()
                messages.append(msg)
    return messages


def getInputControlTestMessages():
    messages = []
    objs = [InputButton(),
            InputButton(touchClick=TouchClickTypes.Touch),
            InputButton(touchClick=TouchClickTypes.Click),
            InputTrigger(),
            InputTrigger(touchClick=TouchClickTypes.Touch),
            InputTrigger(touchClick=TouchClickTypes.Click),
            InputJoystick(),
            InputJoystick(touchClick=TouchClickTypes.Touch),
            InputJoystick(touchClick=TouchClickTypes.Click),
            ]
    message = [obj.getOscMessage() for obj in objs]
    return messages


def getDriverControlTestMessages():
    messages = []

    orders = ["Reset", "LoadSetting"]
    for ord in orders:
        msg = DriverControl(order=ord).getOscMessage()
        messages.append(msg)

    setRoomMatrixOrders = ["SetRoomMatrix", "SetRoomMatrix/Temporary"]
    for ord in setRoomMatrixOrders:
        msg = SetRoomMatrix(order=ord).getOscMessage()
        messages.append(msg)

    return messages


def getDriverResponseTestMessage():
    messages = []
    objs = [OutLog("Out/Log"), OutAlive("Out/Alive"), OutHaptic("Out/Haptic")]
    messages = [obj.getOscMessage() for obj in objs]
    return messages


def getTestMessagesToDriver():
    messages = getTrackerControlTestMessages()
    messages += getInputControlTestMessages()
    messages += getDriverControlTestMessages()
    return messages


def getTestMessagesFromDriver():
    messages = getDriverResponseTestMessage()
    return messages


def main():
    ipAddress = sys.argv[1]
    portToDriver = int(sys.argv[2])
    portFromDriver = int(sys.argv[3])

    toDriverUDPClient = udp_client.UDPClient(ipAddress, portToDriver)
    fromDriverUDPClient = udp_client.UDPClient(ipAddress, portFromDriver)

    tasks = [(toDriverUDPClient, getTestMessagesToDriver()),
             (fromDriverUDPClient, getTestMessagesFromDriver())]
    for udpClient, messages in tasks:
        for msg in messages:
            udpClient.send(msg)


if __name__ == "__main__":
    main()
