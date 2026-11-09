#!/usr/bin/env python3
"""Small local Marionette client; messages and storage never go to the network."""
import json
import socket


class Marionette:
    def __init__(self, port=2828):
        self.socket = socket.create_connection(("127.0.0.1", port), timeout=60)
        self.sequence = 0
        self.hello = self.receive()

    def receive(self):
        size = b""
        while True:
            c = self.socket.recv(1)
            if not c:
                raise EOFError("Firefox disconnected")
            if c == b":":
                break
            size += c
        remaining = int(size)
        payload = bytearray()
        while remaining:
            chunk = self.socket.recv(remaining)
            if not chunk:
                raise EOFError("Incomplete Marionette message")
            payload.extend(chunk)
            remaining -= len(chunk)
        return json.loads(payload)

    def command(self, name, **params):
        self.sequence += 1
        data = json.dumps([0, self.sequence, name, params]).encode()
        self.socket.sendall(str(len(data)).encode() + b":" + data)
        result = self.receive()
        if result[2]:
            raise RuntimeError(json.dumps(result[2]))
        return result[3]

    def start(self):
        self.command("WebDriver:NewSession", capabilities={"alwaysMatch": {}})
        self.command("Marionette:SetContext", value="chrome")

    def execute(self, script, args=None, asynchronous=False):
        name = "WebDriver:ExecuteAsyncScript" if asynchronous else "WebDriver:ExecuteScript"
        result = self.command(name, script=script, args=args or [], newSandbox=True,
                              sandbox="system", scriptTimeout=120000)
        return result.get("value", result) if isinstance(result, dict) else result

    def quit(self):
        try:
            self.command("Marionette:Quit", flags=["eAttemptQuit"])
        finally:
            self.socket.close()
