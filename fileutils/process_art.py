# A very simple script that finds images that are consecutive with masks in a directory,
# applies the mask and puts the image on an appropriate background, scaling it to fit inside
# a 512x512 (or other size given by the -s flag) frame

# This program is distributed under the terms of the MIT License, which you can
# find here: https://opensource.org/license/mit/ as well as in this repository's root
# directory.

import argparse
import dataclasses
import io
import os.path
import pathlib
import re
import textwrap
from typing import Union, Optional, Literal, Tuple

import pytest
from PIL import Image, ImageCms

DEFAULT_OUTDIR = pathlib.Path("training_images")
DEFAULT_SIZE = 512
DEFAULT_QUALITY = 1 / 2.0


@dataclasses.dataclass
class ImageInfo:
    """
    A wrapper class for a PIL Image that tracks things we wish to know
    about it, and provides some helper methods
    """
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

    @classmethod
    def is_color(cls, image: Image):
        """
        Is the given image color? This is not a perfect test, but it's good enough for
        our purposes. We don't care about color images that don't contain any saturated
        pixels, we only care about images that are explicitly only *capable* of holding
        grayscale or black and white data.
        If we did care about the contents, we'd have to check each pixel value on
        images that are CMYK, RGB, etc.

        This is a class method so that it can be used in places where we don't have
        an ImageInfo object handy.
        """
        return 'L' not in image.mode and '1' not in image.mode

    def masked_by(self, other: "ImageInfo"):
        """
        Compare two ImageInfos and determine if they 'go together' in a PDF
        That is, is `other` a black and white or grayscale mask for this image?
        """

        # Potential issues:
        #
        # * grayscale and black and white images can be masked as well
        # * we're not taking the actual mask/smask info from the PDF into account
        # * there is another class of image often found before (possibly a drop shadow?)

        return(
            self.height == other.height and
            self.width == other.width and
            self.is_color(self.image) and not other.is_color(other.image)
        )

    def to_rgb(self):
        """Turn this image into RGB mode, without any image profile assistance"""
        assert not self.is_mask, f"Cannot convert a mask ({self.file_path}) to RGB!"
        self.image = self.image.convert('RGB')

    def from_cmyk_to_rgb(
            self,
            srgb_profile: Optional[Union[io.BytesIO, os.PathLike]] = None,
            cmyk_profile: Optional[Union[ImageCms.ImageCmsProfile, os.PathLike]] = None,
    ):
        """
        Convert this image to the given srgb_profile (or the default sRGB profile if none
        is passed)
        :param srgb_profile: sRGB profile (or path) to use
        :param cmyk_profile: Default CMYK profile (or path) to use
        :return: NA
        """

        if not srgb_profile:
            # Use the built in default sRGB color space
            srgb_profile = ImageCms.createProfile('sRGB')

        # Check to see if the image has an embedded profile
        img_profile_data = self.image.info.get('icc_profile')
        if img_profile_data:
            image_profile = ImageCms.ImageCmsProfile(io.BytesIO(img_profile_data))
        else:
            image_profile = cmyk_profile

        tmp_img = ImageCms.profileToProfile(
            self.image,
            inputProfile=image_profile,
            outputProfile=srgb_profile,
            renderingIntent=0,
            outputMode='RGB'
        )
        if tmp_img:
            self.image = tmp_img
        else:
            print("  WARNING: Cannot convert color profile in TIFF image")
            print("  WARNING: ... will try naive conversion")
            self.to_rgb()


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
        return tuple(self._autocrop(image).resize((10, 10), Image.LANCZOS).convert("L").getdata())

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


def process_final_image(
        image: Image,
        img_hash: FuzzyImageRecall,
        filename=None,
        output_dir: os.PathLike = DEFAULT_OUTDIR,
        output_size=DEFAULT_SIZE,
        keep: bool = False,
        trans_background: bool = False,
):
    """
    Write the image out to disk, pending some last checks such as for duplicates.
    :param image: The image to save
    :param img_hash: The history tracking hash
    :param filename: Image filename
    :param output_dir: Directory to save in
    :param output_size: Maximum dimension for the saved image max(width, height)
    :param keep: Whether to keep existing files or overwrite
    :param trans_background: Should background be transparent?
    :return: filename written (or existing if keep is True)
    """
    png_file = ".".join([os.fspath(filename).rsplit(".", 1)[0], "png"])
    outfile = pathlib.Path(os.path.join(output_dir, os.path.basename(png_file)))

    if image in img_hash:
        print(f"  skipping, we've seen it")
        return None
    img_hash.add(image)

    if keep and outfile.exists():
        return outfile

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
        if not ImageInfo.is_color(img_scaled):
            border_color = (border_color, border_color, border_color)
        mode: Literal['RGBA', 'RGB'] = 'RGB'
        if trans_background:
            mode = 'RGBA'
            if len(border_color) < 4:
                border_color = border_color + (0,)
        save_image = Image.new(mode, (output_size, output_size), border_color)
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


def get_filename_key(fname: os.PathLike):
    """Return a filename key that correctly sorts numbered files"""

    # This was necessary because pdfimages has a tendency to output filenames
    # like file-100.png and file-1000.png for the same input PDF, making a
    # string-based sort disorder the input images.

    def replacer(match: re.Match) -> str:
        in_fname = match.group(0)
        file_id = int(match.group(1))
        return f"{in_fname[0:match.pos]}-{file_id:06d}.{in_fname[match.endpos-1:]}"

    path_str = str(fname)
    return re.sub(r'-(\d+)\.', replacer, path_str)


def process_img_dir(
        img_dir: os.PathLike,
        outdir: os.PathLike = DEFAULT_OUTDIR,
        output_size: int = DEFAULT_SIZE,
        minimum_quality: float = DEFAULT_QUALITY,
        all_images: bool = False,
        unmasked: bool = False,
        keep: bool = False,
        trans_background: bool = False,
        srgb_profile: Optional[Union[ImageCms.ImageCmsProfile, os.PathLike]] = None,
        cmyk_profile: Optional[Union[ImageCms.ImageCmsProfile, os.PathLike]] = None,
):
    """
    Find and label all images in `img_dir`
    :param img_dir: the path to a directory containing consectuively numbered image files from a PDF
        (extracted using pdfimages)
    :param outdir: optional directory to store results
    :param output_size: the size (in width and height) of output images
    :param minimum_quality: float representing the lowest fraction of output_size images to keep
    :param all_images: process images that lack a mask
    :param unmasked: only process unmasked images
    :param keep: Keep existing images (defaults to False, overwriting)
    :param trans_background: Make generated images transparent
    :param srgb_profile: profile or file path to the profile to use in converting CMYK
    :param cmyk_profile: profile or file path to the profile to use for CMYK files with none
    :return: nothing
    """

    small_image = output_size * minimum_quality
    white_color = (255, 255, 255)
    previous = None
    history = FuzzyImageRecall()
    process_args = dict(
        output_size=output_size,
        output_dir=outdir,
        keep=keep,
        trans_background=trans_background,
        img_hash=history,
    )
    print(f"Starting on {img_dir} -> {outdir}")
    img_dir = pathlib.Path(img_dir)  # ensure that it's not a string
    all_files = (pathlib.Path(f) for f in img_dir.glob(os.path.join('**', '*.*')) if os.path.isfile(f))
    for img_file in sorted(all_files, key=get_filename_key):
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
                previous.from_cmyk_to_rgb(srgb_profile, cmyk_profile)
            if previous.masked_by(info):
                info.is_mask = True
                if not unmasked:
                    img_masked = mask_image(previous.image, info.image, background=white_color)
                    if outfile := process_final_image(img_masked, filename=filename, **process_args):
                        print(f"  wrote {outfile}")
            elif all_images or unmasked:
                if outfile := process_final_image(previous.image, filename=filename, **process_args):
                    print(f"  wrote {outfile}")
        previous = info
    if previous and not previous.is_mask and (unmasked or all_images):
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
            
            Examples
            
            Process all images, rendering transparent backgrounds and saving as 720x720:
            
                process-art -a -t -s 720
            
            Process only non-masked images that are at least 75% of the target 512x512 size:
            
                process-art -u -q 0.75
            """
        ),
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    help_text = {
        'all': "Turn on processing of images that lack a mask (lots of extra images!)",
        'unmasked': "Only process unmasked images (incompatible with --all)",
        'output-size': (
            "Set the width and height of the output images to this size, note that no input images"
            " half this size or smaller will be considered."),
        'keep': "Keep existing images",
        'transparent': "Make PNG output transparent if the scaled image does not fit in the target dimensions fully",
        'output-dir': "Where to store results",
        'quality': "A value less than 1 that indicates the minimum fraction of the --output-size images to keep",
        'srgb-color-profile': "The path to an ICC color profile for sRGB to convert CMYK images",
        'cmyk-color-profile': "The path to the default ICC profile for CMYK files that have none",
        'image_dirs': "The image directories to read, includes all subdirs",
    }
    parser.add_argument('-a', '--all', action='store_true', help=help_text['all'])
    parser.add_argument('-k', '--keep', action='store_true', help=help_text['keep'])
    parser.add_argument('-o', '--output-dir', action='store', metavar='PATH', default=DEFAULT_OUTDIR, help=help_text['output-dir'])
    parser.add_argument('-q', '--quality', action='store', metavar='VALUE', default=DEFAULT_QUALITY, type=float, help=help_text['quality'])
    parser.add_argument('-s', '--output-size', action='store', type=int, default=DEFAULT_SIZE, help=help_text['output-size'])
    parser.add_argument('-t', '--transparent', action='store_true', help=help_text['transparent'])
    parser.add_argument('-u', '--unmasked', action='store_true', help=help_text['unmasked'])
    parser.add_argument('-C', '--cmyk-color-profile', action='store', metavar='ICC_FILE', help=help_text['cmyk-color-profile'])
    parser.add_argument('-S', '--srgb-color-profile', action='store', metavar='ICC_FILE', help=help_text['srgb-color-profile'])
    parser.add_argument('image_dirs', action='store', metavar='DIR', nargs='+', help=help_text['image_dirs'])

    args = parser.parse_args()

    if args.unmasked and args.all:
        raise RuntimeError(f"Cannot combine --all and --unmasked, choose one.")

    for img_dir in args.image_dirs:
        process_img_dir(
            pathlib.Path(img_dir).absolute(),
            output_size=args.output_size,
            minimum_quality=args.quality,
            outdir=args.output_dir,
            all_images=(args.unmasked or args.all),
            unmasked=args.unmasked,
            keep=args.keep,
            trans_background=args.transparent,
            srgb_profile=args.srgb_color_profile,
            cmyk_profile=args.cmyk_color_profile,
        )


@pytest.mark.parametrize(
    'filename, expect',
    [
        ("x", "x"),
        ("abc-1.png", "abc-000001.png"),
        ("abc-01.png", "abc-000001.png"),
    ]
)
def test_get_filename_key(filename: os.PathLike, expect: str):
    assert get_filename_key(filename) == expect, f"filename key handling: {filename} -> {expect}"


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
def test_guess_border(image: Image, expected: Union[int, Tuple[int, int, int]], what_is: str):
    """Quick test for our border color guessing"""
    assert guess_border(image) == expected, f"Expect return value of {expected!r} for {what_is}"


if __name__ == '__main__':
    main()
