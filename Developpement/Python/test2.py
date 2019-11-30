# -*- coding: utf-8 -*-
"""
Created on Sat Nov 23 20:22:28 2019

@author: Bedino-Tom
"""

import pygame

def _quit():
    pygame.quit()
    
def draw_play(screen,tab_sq,nbr_c,size_c):
    for i in range(0,len(tab_sq)):
        for e in range(0,len(tab_sq[i])):
            pygame.draw.rect(screen, pygame.Color('black'), ((e*size_c),(i*size_c),size_c,size_c), 1)
            if tab_sq[i][e]:
                pygame.draw.rect(screen, pygame.Color('white'), (((e*size_c)+1),((i*size_c)+1),(size_c-1),(size_c-1)))
            else:
                pygame.draw.rect(screen, pygame.Color('black'), (((e*size_c)+1),((i*size_c)+1),(size_c-1),(size_c-1)))

def init_tab(t,n):
    for i in range(0,n):
        p = []
        for x in range(0,n):
            p.append(True)
        t.append(p)
    return t

def reverse_boolean(b):
    if b:
        return False
    else:
        return True

def change_tab_color(tab,x,y,nbr_c):
    tab[y][x] = reverse_boolean(tab[y][x])
    if (x-1)>=0:
        tab[y][x-1] = reverse_boolean(tab[y][x-1])
    if (y-1)>=0:
        tab[y-1][x] = reverse_boolean(tab[y-1][x])
    if (x+1)<nbr_c:
        tab[y][x+1] = reverse_boolean(tab[y][x+1])
    if (y+1)<nbr_c:
        tab[y+1][x] = reverse_boolean(tab[y+1][x])
    return tab

def event_mouse(tab, mouse_position, cote_c, nbr_c):
    mx = mouse_position[0]
    my = mouse_position[1]
    for y in range(0,len(tab)):
        for x in range(0,len(tab[y])):
            if mx > (x*cote_c) and my > (y*cote_c) and mx < ((x*cote_c)+cote_c) and my < ((y*cote_c)+cote_c):
                tab = change_tab_color(tab,x,y,nbr_c)
    return tab

def search_win(tab_sq, nbr_c):
    n=0
    for i in range(0,len(tab_sq)):
        for e in range(0,len(tab_sq[i])):
            if tab_sq[i][e] == False:
                n=n+1
    if n==(nbr_c*nbr_c):
        return True
    return False

def main():
    pygame.init()
    pygame.display.set_caption("Black Case")
     
    screen = pygame.display.set_mode((400,400))
     
    running = True
    
    nbr_c = 4
    size_c = int(400/nbr_c)
    tab_sq = []
    tab_sq = init_tab(tab_sq, nbr_c)
    
    while running:
        for event in pygame.event.get():
            if event.type == pygame.MOUSEBUTTONDOWN:
               tab_sq = event_mouse(tab_sq,pygame.mouse.get_pos(),size_c,nbr_c)
            if event.type == pygame.KEYDOWN and event.key == pygame.K_r:
               tab_sq = []
               tab_sq = init_tab(tab_sq, nbr_c)
            if event.type == pygame.QUIT:
                running = False
        draw_play(screen,tab_sq,nbr_c,size_c)
        if search_win(tab_sq,nbr_c):
            nbr_c = nbr_c + 2
            size_c = int(400/nbr_c)
            tab_sq = []
            tab_sq = init_tab(tab_sq, nbr_c)
        pygame.display.update()
    _quit()

if __name__=="__main__":
    main()