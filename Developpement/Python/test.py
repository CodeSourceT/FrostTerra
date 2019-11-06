# -*- coding: utf-8 -*-
"""
Created on Wed Nov  6 21:18:10 2019

@author: Bedino-Tom
"""

from tkinter import *

## CODE SOURCE MOTEUR 

class FTObject:
    def __init__(self, name):
        self.name = name;
        
    def getName():
        return self.name
    
class FTWindows(FTObject):
    def __init__(self, title, w, h, resize):
        FTObject.__init__(self,"FTWINDOWS" + title)
        self.tk = Tk()
        self.tk.title(title)
        self.tk.geometry(str(w)+"x"+str(h))
        if resize:
            self.tk.resizable(True,True)
        else:
            self.tk.resizable(False,False)
            
    def loop(self):
        self.tk.mainloop()
        
#CODE SOURCE QUE TU ECRITS
        
win=FTWindows("test",640,480,False)
win.loop()