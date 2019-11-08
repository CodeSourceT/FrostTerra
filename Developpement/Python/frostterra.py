# -*- coding: utf-8 -*-
"""
Created on Wed Nov  6 19:11:36 2019

@author: Bedino-Tom
"""

from tkinter import *
import math

class FTObject:
    def __init__(self, name):
        self.name = name;
        
    def getName(self):
        return self.name
    
class FTWindows(FTObject):
    def __init__(self, title, w, h, resize):
        FTObject.__init__(self,"FTWINDOWS" + title)
        self.tk = Tk()
        self.tk.title(title)
        self.tk.geometry(str(w)+"x"+str(h))
        self.size_win=FTRect(w=w,h=h)
        if resize:
            self.tk.resizable(True,True)
        else:
            self.tk.resizable(False,False)
            
    def addGraphicRender(self,call,call2):
        self.render=FTRender(self.tk,self.size_win.w,self.size_win.h,call,call2)
        
    def loop(self):
        self.tk.mainloop()
        
class FTRender(FTObject):
    def __init__(self, tk, w, h, function_draw, function_loop):
        FTObject.__init__(self,"FTRENDER"+str(w+h))
        self.root=tk
        self.canvas = Canvas(tk, width = w, height = h)
        self.canvas.pack()
        self.callback_draw=function_draw
        self.canvas.after(50, self.dispatchDraw)
        self.callbakc_loop = function_loop
        
    def dispatchDraw(self):
        paint = FTPaint(self.canvas)
        self.callback_draw(paint)
        self.canvas.after(50, self.dispatchLoop)
        
    def dispatchLoop(self):
        paint = FTPaint(self.canvas)
        self.callbakc_loop(paint)
        self.canvas.after(50, self.dispatchLoop)
        
class FTPaint(FTObject):
    def __init__(self, canvas):
        FTObject.__init__(self,"FTPAINT")
        self.canvas=canvas
        self.matrix_color=FTColor()
        
    def draw_rect(self, pos_s):
        i = self.canvas.create_rectangle(pos_s.x,pos_s.y,(pos_s.x+pos_s.w),(pos_s.y+pos_s.h), fill=self.matrix_color.getStrColor())
        return FTGObject(pos_s,FTIQuaternion(),i)
        
    def draw_oval(self,pos_s):
        i = self.canvas.create_oval(pos_s.x,pos_s.y,(pos_s.x+pos_s.w),(pos_s.y+pos_s.h), fill=self.matrix_color.getStrColor())
        return FTGObject(pos_s,FTIQuaternion(),i)
    
    def draw_object(self,obj):
        deltax=0
        deltay=0
        if obj.pos.bmove:
            deltax=(obj.pos.x-obj.pos.ax)
            deltay=(obj.pos.y-obj.pos.ay)
            obj.pos.bmove=False
        self.canvas.move(obj.ido,deltax,deltay)
        return obj
          
class FTGObject(FTObject):
    def __init__(self,rect,rot,id):
        self.pos=rect
        self.rot=rot
        self.ido=id
               
class FTRect(FTObject):
    def __init__(self,x=0,y=0,w=0,h=0):
        FTObject.__init__(self,"FTRECT" + str(x+y+h+w))
        self.x=x
        self.y=y
        self.w=w
        self.h=h
        self.ax=0
        self.ay=0
        self.bmove=False
        
    def move(self,x=0,y=0):
        self.ax=self.x
        self.ay=self.y
        self.x=self.x+x
        self.y=self.y+y
        self.bmove=True
        
class FTIQuaternion(FTObject):
    def __init__(self,system="radian",x=0,y=0):
        FTObject.__init__(self,"FTRECT" + str(y+y))
        if system == "degree":
            self.x=math.radians(x)
            self.y=math.radians(y)
        else:
            self.x=x
            self.y=y
    
    def getSwapSystem(self):
        return FTIQuaternion(x=self.x,y=self.y)
        
class FTColor(FTObject):
    def __init__(self,r=0,g=0,b=0,a=0):
        FTObject.__init__(self,"FTCOLOR" + str(r+g+b+a))
        self.r=r
        self.g=g
        self.b=b
    def getStrColor(self):
        if self.r==0 and self.g==0 and self.b==0:
            return "black"
        if self.r==255 and self.g==255 and self.b==255:
            return "white"
        if self.r==255 and self.g==0 and self.b==0:
            return "red"
        if self.r==0 and self.g==255 and self.b==0:
            return "green"
        if self.r==0 and self.g==0 and self.b==255:
            return "blue"