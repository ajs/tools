#!/usr/bin/env python3

"""
Solve Matt Parker's puzzle from:
https://www.think-maths.co.uk/avoidthesquare
"""


import sys
import math
import random
import argparse

import pytest


class Board:
    """
    An nxn board of possible positions.
    This board can play a game randomly and assess win vs. draw.
    """

    def __init__(self, size, default=None):
        self.size = size
        self.default = default
        self.reset_board()

    def reset_board(self):
        """Set board to starting state"""

        self.board = [[None for _ in range(self.size)] for __ in range(self.size)]
        if self.default:
            dsize = min(self.default.size, self.size)
            for x, y in ((x,y) for x in range(dsize) for y in range(dsize)):
                self.board[x][y] = self.default.board[x][y]

    def random_play(self):
        """
        Play a random game, leaving the board in the correct final state.

        Sets the board end-state, but also returns a 2-tuple of the moves
        made by the 0-player and the 1-player. Each list of moves is a list
        of 2-tuples of x, y coordinates.
        """

        # List of all board locations
        locs = [(x,y) for x in range(self.size) for y in range(self.size)]
        # Shuffling gives us a move sequence for our random game,
        # first all of 0's moves and then all of 1's moves
        random.shuffle(locs)
        # Because we're doing integer division with the flooring operator,
        # 1 will get the extra move on boards with a non-even number of
        # squares, effectively meaning 1 goes first.
        zero_moves = locs[0:len(locs)//2]
        one_moves = locs[len(locs)//2:]
        for x, y in zero_moves:
            # Half the moves place a 0
            self.board[x][y] = 0
        for x, y in one_moves:
            # Half the moves place a 1
            self.board[x][y] = 1

        return (zero_moves, one_moves)

    def winner(self, moves):
        """
        Who won the game? Returns 0 or 1 representing the player's
        piece on the board.
        The loser is the first player to form a square.

        Returns None if there is no winner (note that this calls draw() for
        every board state along the way, so it is much faster to
        call draw on the final board state if that's all you want.
        """

        zero_moves, one_moves = moves
        if len(one_moves) > len(zero_moves):
            # Even out the move list
            zero_moves = list(zero_moves) + [None]
        for zero_move, one_move in zip(zero_moves, one_moves):
            # Note that 1 always goes first
            self.board[one_move[0]][one_move[1]] = 1
            if not self.draw():
                return 0
            if zero_move:
                self.board[zero_move[0]][zero_move[1]] = 0
                if not self.draw():
                    return 1
        return None

    def draw(self):
        """Return True if the game was a draw (no squares present)"""

        def _is_square(corners):
            """Check a given square has all the same pieces in corners"""

            pieces = [self.board[x][y] for x, y in corners]
            # If no piece placed in a corner, it's not a square
            if None not in pieces and len(set(pieces)) == 1:
                # All the same
                return True
            return False

        # Check for squares in every sub-set of the board that could
        # fit one...
        for x in range(self.size-1):
            for y in range(self.size-1):
                for square in range(1, self.size-max(x,y),1):
                    # Detect squares in the obvious way where
                    # each corner is on the same row as one other corner
                    # and the same column as another.
                    corners = (
                        (x,y),
                        (x+square,y+square),
                        (x+square,y),
                        (x,y+square),
                    )
                    if _is_square(corners):
                        return False

                    # Detect squares in the 45 degree rotational case where
                    # each corner is at the mid-point of an edge of a larger
                    # square of the type, above.
                    mid = square//2
                    if mid != (square/2.0):
                        # Not an odd-size square, so rotated square
                        # does not fit.
                        continue
                    corners = (
                        (x,y+mid),
                        (x+mid,y),
                        (x+square,y+mid),
                        (x+mid,y+square),
                    )
                    if _is_square(corners):
                        return False
        return True

    def make_move(self, player, randomize=False):
        """
        Given a player 0 or 1, make a move on the current board state

        Returns the move made or None if no moves were available.
        """

        losing_move = None
        moves = [(x,y) for x in range(self.size) for y in range(self.size)]
        if randomize:
            random.shuffle(moves)
        for move_x, move_y in moves:
            if self.board[move_x][move_y] is None:
                self.board[move_x][move_y] = player
                if self.draw():
                    return (move_x, move_y)
                else:
                    losing_move = (move_x, move_y)
                    self.board[move_x][move_y] = None
        if losing_move:
            # Forced to make losing move
            self.board[losing_move[0]][losing_move[1]] = player
            return losing_move

        return None

    def __str__(self):
        """Represent board as multi-line string"""

        dims = f"{self.size}x{self.size}"
        board = "\n".join(
            " ".join(
                # Spots with no move get "*"
                str(self.board[x][y] if self.board[x][y] is not None else "*")
                for x in range(self.size)
            ) for y in range(self.size)
        )
        return f"{dims}\n{board}"


def play_game(board, silent=False):
    """Play a game and print results"""

    moves = []
    while True:
        for player in (1,0):
            move = board.make_move(player, randomize=True)
            if move:
                moves.append(move)
            summary = f"moves = {moves!r}\nBoard: {board}"
            if move:
                if not board.draw():
                    if not silent:
                        print(f"Player {player} lost at {move!r} after:\n{summary}")
                    return 1-player
            else:
                if not silent:
                    print(f"Draw reached after:\n{summary}")
                return None
    raise RuntimeError("Infinite loop completed!")


def walk_board():
    """Start with board size 2 and keep going, tryig to find draws for each"""

    board = None
    for size in range(2,10000,1):
        #board = Board(size=size, default=board)
        board = Board(size=size)
        count = 0
        while play_game(board, silent=True) is not None:
            board.reset_board()
            count += 1
            if count % 100 == 0:
                sys.stdout.write(".")
                sys.stdout.flush()
        print(board)

def main():
    """Run a simulation"""

    parser = argparse.ArgumentParser(description="Parker Squares?!")
    parser.add_argument(
        "board_size",
        nargs="?",
        action="store",
        type=int,
        default=5,
    )
    parser.add_argument(
        "--play",
        action="store_true",
        help="Play out a random game",
    )
    parser.add_argument(
        "--walk",
        action="store_true",
        help="Walk the board size up, finding a draw for each one...",
    )
    parser.add_argument(
        "--check",
        action="store",
        help="Give a board layout as a 1/0 string, filling the board left-to-right, top-to-bottom and report status of game",
    )
    args = parser.parse_args()

    if args.play:
        board = Board(size=args.board_size)
        play_game(board)
    if args.walk:
        walk_board()
    if args.check:
        board_data = "".join(c for c in args.check if c.isdigit())
        pieces = len(board_data)
        size = math.sqrt(pieces)
        if int(size) != size:
            raise ValueError(f"Board to check is not square (len={pieces})")
        size=int(size)
        board = Board(size=size)
        for i, piece in enumerate(board_data):
            player = int(piece)
            board.board[i%size][i//size] = player
        if board.draw():
            print("Draw: ", board)
        else:
            print("Not draw: ", board)
    else:
        board = Board(size=args.board_size)
        while True:
            board.random_play()
            if board.draw():
                print(board)
                break

### Tests
##
## Run with `pytest <this-file>` or pytest-3 if you have
## python3 installed with suffix names.
##
## Use `pip install pytest` if you do not have pytest.

def test_board_creation():
    """Verify basic board state"""

    board = Board(5)
    assert board.size == 5, "Board size check"
    assert all(board.board[x][y] is None for x in range(5) for y in range(5)), (
        "Board default state check"
    )

def test_board_shuffle():
    """Verify random game fills in board"""

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
        # 3x3 draw
        ([
            [1,0,0],
            [1,0,1],
            [0,1,1]], 3, True),
        # 5x5 draw
        ([
            [1,0,1,1,0],
            [0,1,1,0,0],
            [0,1,0,0,1],
            [0,1,0,1,1],
            [1,0,1,0,1]], 5, True),
    )
)
def test_board_draw(sample_board, size, result):
    """Verify draw detection on various known boards"""

    board = Board(size)
    board.board = sample_board
    # Note that board as printed is x/y swapped from what's shown above
    assert board.draw() is result, (
        f"Sample board {board} expects draw is {result!r}"
    )

@pytest.mark.parametrize('moves, size, winner', (
    (
        (((0,0), (0,1)),
         ((1,0), (1,1))),
        2,
        None
    ),
    (
        # Moves
        (((0,2), (1,2), (2,2)),
         ((0,0), (0,1), (1,1), (1,0))),
        3, # Board size
        0, # Winner
    ),
    (
        # Moves
        (((0,0), (0,1), (1,1), (1,0)),
         ((0,2), (1,2), (2,2), (2,1))),
        3, # Board size
        1, # Winner
    ),
))
def test_board_winner(moves, size, winner):
    """Verify the winner detection for a set of moves"""

    board = Board(size)
    actual_winner = board.winner(moves)
    if winner is None:
        assert actual_winner is None, (
            f"Expect draw from moves: {moves!r} on {board}"
        )
    else:
        assert actual_winner == winner, (
            f"Expect winner {winner} from moves: {moves!r} on {board}"
        )


if __name__ == '__main__':
    main()
