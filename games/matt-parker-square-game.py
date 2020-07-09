#!/usr/bin/env python3

"""
Solve Matt Parker's puzzle from:
https://www.think-maths.co.uk/avoidthesquare
"""


import pytest
import random
import argparse


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
                for square in range(1, self.size-max(x,y),1):
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

def main():
    parser = argparse.ArgumentParser(description="Parker Squares?!")
    parser.add_argument(
        "board_size",
        nargs="?",
        action="store",
        type=int,
        default=5,
    )
    args = parser.parse_args()

    board = Board(size=args.board_size)
    while True:
        board.random_play()
        if board.draw():
            print(board)
            break

### Tests

def test_board_creation():
    board = Board(5)
    assert board.size == 5, "Board size check"
    assert all(board.board[x][y] is None for x in range(5) for y in range(5)), (
        "Board default state check"
    )

def test_board_shuffle():
    board = Board(5)
    board.random_play()
    assert all(board.board[x][y] is not None for x in range(5) for y in range(5)), (
        "Board shuffle non-default state check"
    )

@pytest.mark.parametrize(
    'sample_board, size, result', (
        # Just a square
        ([
            [0,0],
            [0,0]], 2, False),
        # Draw
        ([
            [1,0],
            [1,0]], 2, True),
        # Square in corners and 45-degree turn edges
        ([
            [1,0,1],
            [0,0,0],
            [1,0,1]], 3, False),
        # Just edges
        ([
            [1,0,0],
            [0,1,0],
            [1,0,1]], 3, False),
    )
)
def test_board_draw(sample_board, size, result):
    board = Board(size)
    board.board = sample_board
    # Note that board as printed is x/y swapped from what's shown above
    assert board.draw() is result, (
        f"Sample board {board} expects draw is {result!r}"
    )


if __name__ == '__main__':
    main()
