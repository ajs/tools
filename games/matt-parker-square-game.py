#!/usr/bin/env python3

import random

class Board:
    def __init__(self, size):
        self.size = size
        self.board = [[None for _ in range(size)] for __ in range(size)]

    def random_play(self):
        locs = [(x,y) for x in range(self.size) for y in range(self.size)]
        random.shuffle(locs)
        for x, y in locs[0:len(locs)//2]:
            self.board[x][y] = 0
        for x, y in locs[len(locs)//2:]:
            self.board[x][y] = 1

    def draw(self):
        for x in range(self.size-1):
            for y in range(self.size-1):
                for square in range(1, self.size-max(x,y)-1,1):
                    if (
                        self.board[x][y] == self.board[x+square][y+square] ==
                        self.board[x+square][y] == self.board[x][y+square]
                    ):
                        return False
                    mid = square//2
                    if (
                        mid == (square/2.0) and (
                            self.board[x][y+mid] ==
                            self.board[x+mid][y] ==
                            self.board[x+square][y+mid] ==
                            self.board[x+mid][y+square]
                        )
                    ):
                        return False
        return True

    def __str__(self):
        dims = f"{self.size}x{self.size}"
        board = "\n".join(
            " ".join(
                str(self.board[x][y]) for x in range(self.size)
            ) for y in range(self.size)
        )
        return f"{dims}\n{board}"

board_size = 5

board = Board(size=board_size)
while True:
    board.random_play()
    if board.draw():
        print(board)
        break
