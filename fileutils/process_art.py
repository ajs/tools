# A very simple script that finds images that are consecutive with masks in a directory,
# applies the mask and puts the image on an appropriate background, scaling it to fit inside
# a 512x512 (or other size given by the -s flag) frame

import argparse
import dataclasses
import os.path
import pathlib
import sys
import textwrap

import pytest
from PIL import Image

DEFAULT_OUTDIR = pathlib.Path("training_images")
DEFAULT_SIZE = 512


@dataclasses.dataclass
class ImageInfo:
    file_path: os.PathLike
    image: Image
    is_mask: bool = False

    @classmethod
    def get_image_info(cls, img_path: os.PathLike):
        """Read info about an image"""

        img_obj = Image.open(os.fspath(img_path))

        return cls(
            file_path=img_path,
            image=img_obj,
        )

    @property
    def width(self):
        return self.image.width

    @property
    def height(self):
        return self.image.height

    @property
    def is_color(self):
        return 'L' not in self.image.mode and '1' not in self.image.mode

    def masked_by(self, other: "ImageInfo"):
        """
        Compare two ImageInfos and determine if they 'go together' in a PDF
        That is, is `other` a black and white or grayscale mask for this image?
        """

        return(
            self.height == other.height and
            self.width == other.width and
            self.is_color and not other.is_color
        )

    def convert_rgb(self):
        """Turn this image into RGB mode"""
        assert not self.is_mask, f"Cannot convert a mask ({self.file_path}) to RGB!"
        self.image = self.image.convert('RGB')


class FuzzyImageRecall:
    """
    A tracking class used to keep a record of the images we've seen with
    enough fuzziness that most simple duplication will be caught, but we won't
    have to waste much memory on the tracking.

    This is accomplished by scaling the image down to a very small size,
    cropping out any white border, converting it to grayscale and then
    converting its pixels to a 100-tuple that we hash by storing them in
    a set.

    This is a trivial matching function that can be easily "defeated" but we
    don't really care. All we want is to identify simple duplication and some
    very trivial transformations.
    """
    def __init__(self):
        self.seen = set()

    def __contains__(self, image: Image):
        """Allow the `in` operator to work on this class to test membership of an image"""
        return self._to_tuple(image) in self.seen

    def _to_tuple(self, image: Image):
        """Convert an image into a 100-tuple by scaling to 10x10 and grayscaling"""
        return tuple(self._autocrop(image).resize((10, 10), Image.ANTIALIAS).convert("L").getdata())

    def _autocrop(self, image: Image):
        """Find the largest sub-image that does not have an all-white border on any side"""
        upper_left_x = 0
        upper_left_y = 0
        lower_right_x = image.width - 1
        lower_right_y = image.height - 1
        white = (255, 255, 255)
        done = False
        for x in range(upper_left_x, lower_right_x):
            for y in range(upper_left_y, lower_right_y):
                if image.getpixel((x, y)) != white:
                    upper_left_x = x
                    done = True
                    break
            if done:
                break
        if not done:
            return image
        done = False
        for x in reversed(range(upper_left_x, lower_right_x)):
            for y in range(upper_left_y, lower_right_y):
                if image.getpixel((x, y)) != white:
                    lower_right_x = x
                    done = True
                    break
            if done:
                break
        for y in range(upper_left_y, lower_right_y):
            for x in range(upper_left_x, lower_right_x):
                if image.getpixel((x, y)) != white:
                    upper_left_y = y
                    done = True
                    break
            if done:
                break
        for y in reversed(range(upper_left_y, lower_right_y)):
            for x in range(upper_left_x, lower_right_x):
                if image.getpixel((x, y)) != white:
                    lower_right_y = y
                    done = True
                    break
            if done:
                break
        rect = (upper_left_x, upper_left_y, lower_right_x, lower_right_y)
        try:
            return image.crop(rect)
        except IndexError:
            raise RuntimeError(f"Unable to crop image {image.width}x{image.height} to: {rect!r}")

    def add(self, image: Image):
        """Add the given image to our tracking"""
        self.seen.add(self._to_tuple(image))


def target_size(image: Image, boundary_size: int):
    """Return the size to scale to such that image fits inside the boundary_size"""

    def scale_dim(source: int, other_dim: int):
        return int(source * (float(boundary_size) / other_dim))

    if image.width > image.height:
        return boundary_size, scale_dim(image.height, image.width)
    return scale_dim(image.width, image.height), boundary_size


def make_image_corners(mode, *corners):
    """Used for testing, make an Image with the given mode and corner pixel values"""
    corner_lookup = {
        'L': {
            'white': 255,
            'black': 0,
        },
        'RGB': {
            'white': (255, 255, 255),
            'black': (0, 0, 0),
        }
    }
    corners = [corner_lookup[mode][corner] for corner in corners]
    base_value = corners[0]
    image = Image.new(mode, (3,3), base_value)
    corner_locs = ((0, 0), (2, 0), (0, 2), (2, 2))
    for loc, value in zip(corner_locs, corners):
        image.putpixel(loc, value)
    return image


def guess_border(image: Image):
    """
    Try to guess what color the image border should be based on corner pixels.
    If there is a color found more than the others, it is chosen (ties are
    resolved by 'lightness').

    TODO: do not prefer lightness, but rather the shade closest to the average
          shade in the image.
    """

    def pixel_order(pixel, frequency):
        if not isinstance(pixel, int):
            pixel = sum(pixel) / len(pixel)
        return frequency + 1.0 / (257 - pixel)

    corners = tuple(
        image.getpixel(loc) for loc in (
            (0, 0), (0, image.height - 1),
            (image.width - 1, 0), (image.width - 1, image.height - 1)
        )
    )
    vote = {}
    for corner in corners:
        vote[corner] = vote.get(corner, 0) + 1
    return sorted(vote.keys(), key=lambda x: pixel_order(x, vote[x]))[-1]


def process_final_image(image: Image, img_hash: FuzzyImageRecall, filename=None, output_dir: os.PathLike = DEFAULT_OUTDIR, output_size=DEFAULT_SIZE, keep: bool = False):
    png_file = ".".join([os.fspath(filename).rsplit(".", 1)[0], "png"])
    outfile = pathlib.Path(os.path.join(output_dir, os.path.basename(png_file)))
    if keep and outfile.exists():
        return outfile

    if image in img_hash:
        print(f"  skipping, we've seen it")
        return None
    img_hash.add(image)
    try:
        img_scaled = image.resize(target_size(image, output_size))
    except ValueError as err:
        # If we try to resize to 0 this fails
        print(f"  skipping bad resize: {err}")
        return None
    if img_scaled.width == img_scaled.height:
        save_image = img_scaled
    else:
        border_color = guess_border(img_scaled)
        if 'L' in img_scaled.mode or '1' in img_scaled.mode:
            border_color = (border_color, border_color, border_color)
        save_image = Image.new('RGB', (output_size, output_size), border_color)
        if img_scaled.width > img_scaled.height:
            y_offset = (output_size - img_scaled.height) // 2
            save_image.paste(img_scaled, (0, y_offset))
        else:
            x_offset = (output_size - img_scaled.width) // 2
            save_image.paste(img_scaled, (x_offset, 0))
    save_image.save(outfile, format="png")
    return outfile


def mask_image(image: Image, mask: Image, background: tuple):
    """Return the input image masked by `mask` with background defined by `background`"""
    img_base = Image.new("RGB", image.size, background)
    img_masked = Image.composite(image, img_base, mask)
    return img_masked


def process_img_dir(
        img_dir: os.PathLike,
        outdir: os.PathLike = DEFAULT_OUTDIR,
        output_size: int = DEFAULT_SIZE,
        all_images: bool = False,
        keep: bool = False,
):
    """
    Find and label all images in `img_dir`
    :param img_dir: the path to a directory containing consectuively numbered image files from a PDF
        (extracted using pdfimages)
    :param outdir: optional directory to store results
    :param output_size: the size (in width and height) of output images
    :param all_images: process images that lack a mask
    :param keep: Keep existing images (defaults to False, overwriting)
    :return: nothing
    """

    small_image = output_size / 2.0
    white_color = (255, 255, 255)
    previous = None
    history = FuzzyImageRecall()
    process_args = dict(
        output_size=output_size,
        output_dir=outdir,
        keep=keep,
        img_hash=history,
    )
    print(f"Starting on {img_dir} -> {outdir}")
    img_dir = pathlib.Path(img_dir)  # ensure that it's not a string
    all_files = (pathlib.Path(f) for f in img_dir.glob(os.path.join('**', '*.*')) if os.path.isfile(f))
    for img_file in sorted(all_files):
        print(f" input file: {img_file}")
        if "." not in str(img_file):
            print(f"  skipping unknown file type for {img_file}")
            continue
        img_extension = str(img_file).lower().rsplit(".", 1)[-1]
        if img_extension == "ccitt":
            print(f"  skipping {img_file} as we don't support CCITT format TIFF compression")
            continue
        elif img_extension == "params":
            print(f"  skipping {img_file} as we don't support PARAMS files")
            continue
        info = ImageInfo.get_image_info(img_file)
        if max(info.width, info.height) <= small_image:
            print(f"  skipping small image")
            continue
        if previous and not previous.is_mask:
            filename = os.path.join(outdir, os.path.basename(previous.file_path))
            if previous.image.mode == 'CMYK':
                # TODO: Handle color space conversions...
                # CMYK_ICC = 'WebCoatedSWOP2006Grade3.icc'
                # RGB_ICC = 'sRGB_v4_ICC_preference.icc'
                # trans = ImageCms.buildTransform(CMYK_ICC, RGB_ICC, 'CMYK', 'RGB')
                # img_color_tmp = ImageCms.applyTransform(img_color, trans)
                print(f"  WARNING: CMYK is poorly supported, will try...")
                previous.convert_rgb()

            if previous.masked_by(info):
                info.is_mask = True
                img_masked = mask_image(previous.image, info.image, background=white_color)
                if outfile := process_final_image(img_masked, filename=filename, **process_args):
                    print(f"  wrote {outfile}")
            elif all_images:
                if outfile := process_final_image(previous.image, filename=filename, **process_args):
                    print(f"  wrote {outfile}")
        previous = info
    if previous and not previous.is_mask and all_images:
        filename = os.path.join(outdir, os.path.basename(previous.file_path))
        if outfile := process_final_image(previous.image, filename=filename, **process_args):
            print(f"  wrote {outfile}")


def main():
    """Use command-line to find images to process"""

    parser = argparse.ArgumentParser(
        'process-art',
        description=textwrap.dedent(
            """
            This script manages files from pdfimages, attempting to assemble images
            used in the document into regular sized and uniformly formatted output
            images.
            """
        ),
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument('-a', '--all', action='store_true', help=(
        "Turn on processing of images that lack a mask (lots of extra images!)"
    ))
    parser.add_argument(
        '-s', '--output-size', action='store', type=int, default=DEFAULT_SIZE,
        help=(
            "Set the width and height of the output images to this size, note that no input images"
            " half this size or smaller will be considered."
        ),
    )
    parser.add_argument('-k', '--keep', action='store_true', help="Keep existing images")
    parser.add_argument(
        'image_dirs',
        action='store', metavar='DIR', nargs='+',
        help="The image directories to read, includes all subdirs"
    )
    args = parser.parse_args()

    if len(sys.argv) > 1:
        for img_dir in args.image_dirs:
            process_img_dir(pathlib.Path(img_dir).absolute(), output_size=args.output_size, all_images=args.all, keep=args.keep)
    else:
        raise RuntimeError("Usage: process_art <imgdir>...")


@pytest.mark.parametrize(
    'image, expected, what_is',
    [
        (make_image_corners("L", 'white', 'white', 'white', 'white'), 255, "Greyscale all white"),
        (make_image_corners("L", 'black', 'black', 'black', 'black'), 0, "Greyscale all black"),
        (make_image_corners("L", 'black', 'black', 'white', 'white'), 255, "Greyscale half and half"),
        (make_image_corners("L", 'black', 'black', 'black', 'white'), 0, "Greyscale one white"),
        (make_image_corners("RGB", 'white', 'white', 'white', 'white'), (255, 255, 255), "Greyscale all white"),
        (make_image_corners("RGB", 'black', 'black', 'black', 'black'), (0, 0, 0), "Greyscale all black"),
        (make_image_corners("RGB", 'black', 'black', 'white', 'white'), (255, 255, 255), "Greyscale half and half"),
        (make_image_corners("RGB", 'black', 'black', 'black', 'white'), (0, 0, 0), "Greyscale one white"),
    ]
)
def test_guess_border(image, expected, what_is):
    assert guess_border(image) == expected, f"Expect return value of {expected!r} for {what_is}"


if __name__ == '__main__':
    main()
