#!/usr/bin/env python3

"""
Solve Matt Parker's puzzle from:
https://www.think-maths.co.uk/avoidthesquare
"""


import pytest
import random
import argparse


class Board:
    """
    An nxn board of possible positions.
    This board can play a game randomly and assess win vs. draw.
    """

    def __init__(self, size):
        self.size = size
        self.reset_board()

    def reset_board(self):
        """Set board to starting state"""

        self.board = [[None for _ in range(self.size)] for __ in range(self.size)]

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
    args = parser.parse_args()

    board = Board(size=args.board_size)
    while True:
        board.random_play()
        if board.draw():
            print(board)
            break

### Tests

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
