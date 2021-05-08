# test_packet-vmt.lua
# Test message generator for 'Virtual Motion Tracker' packet dissection
#
# Copyright (c) 2021, A.Shiomaneki <a.shiomaneki@gmail.com>
#
# This program is released under the MIT License.
# http://opensource.org/licenses/mit-license.php

import sys
from abc import ABC, abstractmethod
from pythonosc import osc_message_builder
from pythonosc import udp_client

class Vmt(ABC):
    addressPrefix = "/VMT"
    @abstractmethod
    def getOscMessage(self):
        pass

class TrackerControl(Vmt):
    def getArgs(self):
        return {
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

    def __init__(self, firstPath="", secondPath=""):
        self.firstPath = firstPath
        self.secondPath = secondPath

    def getAddress(self):
        return (self.addressPrefix +"/{0}/{1}").format(self.firstPath, self.secondPath)

    def getOscMessage(self):
        address = self.getAddress()
        message = osc_message_builder.OscMessageBuilder(address = address)
        for val in self.getArgs().values():
            message.add_arg(val)
        return message.build()

class TrackerControlOnAnother(TrackerControl):
    def getArgs(self):
        args = super().getArgs()
        args["serial"] = "VMT_001"
        return args

class InputOperation(Vmt):
    def __init__(self, inputType):
        self.address = self.addressPrefix + "/" + inputType
    
    def getAddress(self):
        return self.address

    def getOscMessage(self):
        address = self.getAddress()
        message = osc_message_builder.OscMessageBuilder(address = address)
        for val in self.getArgs().values():
            message.add_arg(val)
        return message.build()

class InputButton(InputOperation):
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
        message = osc_message_builder.OscMessageBuilder(address = address)
        return message.build()

class SetRoomMatrix(DriverControl):
    def getRoomMatrix(self):
        json = {"RoomMatrix": [1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0]}
        return json["RoomMatrix"]

    def getOscMessage(self):
        address = self.getAddress()
        message = osc_message_builder.OscMessageBuilder(address = address)
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
        message = osc_message_builder.OscMessageBuilder(address = address)
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
    firstPaths = ["Room", "Raw", "Joint", "Follow"]
    secondPaths = ["Unity", "Driver"]
    for f in firstPaths:
        for s in secondPaths:
            if f == "Joint" or f == "Follow":
                msg = TrackerControlOnAnother(
                    firstPath=f, secondPath=s).getOscMessage()
                messages.append(msg)
            else:
                msg = TrackerControl(firstPath=f, secondPath=s).getOscMessage()
                messages.append(msg)
    return messages

def getInputControlTestMessages():
    messages = []
    objs = [InputButton("Input/Button"), InputTrigger("Input/Trigger"),
            InputJoystick("Input/Joystick")]
    message = [obj.getOscMessage() for obj in objs]
    return messages

def getDriverControlTestMessages():
    messages = []

    orders = ["Reset", "LoadSetting"]
    for ord in orders:
        msg = DriverControl(order = ord).getOscMessage()
        messages.append(msg)

    setRoomMatrixOrders = ["SetRoomMatrix", "SetRoomMatrix/Temporary"]
    for ord in setRoomMatrixOrders:
        msg = SetRoomMatrix(order = ord).getOscMessage()
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

    tasks = [(toDriverUDPClient, getTestMessagesToDriver()), (fromDriverUDPClient, getTestMessagesFromDriver())]
    for udpClient, messages in tasks:
        for msg in messages:
            udpClient.send(msg)

if __name__ == "__main__":
    main()
