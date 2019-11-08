# -*- coding: utf-8 -*-
"""
Created on Wed Nov  6 21:18:10 2019

@author: Bedino-Tom
"""

from frostterra import *

oval = FTGObject(FTRect(x=50,y=50,w=20,h=20),FTIQuaternion(),0)
rect= FTGObject(FTRect(x=150,y=80,w=20,h=20),FTIQuaternion(),0)
force=4
airfriction=0.01

def calcul_force():
    global force
    global airfriction
    if (oval.pos.y + 20) >= 480:
        force = -force
    else:
        force = force + 1
    force = force - (force * airfriction)

def init_draw(paint):
    global oval
    global rect
    oval = paint.draw_oval(oval.pos)
    rect = paint.draw_rect(rect.pos)
    
    
def loop(paint):
    global oval
    global rect
    calcul_force()
    oval.pos.move(x=0,y=force)
    rect.pos.move(x=0,y=force)
    oval = paint.draw_object(oval)
    rect = paint.draw_object(rect)

win=FTWindows("test",640,480,False)
win.addGraphicRender(init_draw,loop)
win.loop()