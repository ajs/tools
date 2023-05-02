# A very simple script that finds images that are consecutive with masks in a directory,
# applies the mask and puts the image on an appropriate background, scaling it to fit inside
# a 512x512 (or other size given by the -s flag) frame

# This program is distributed under the terms of the MIT License, which you can
# find here: https://opensource.org/license/mit/ as well as in this repository's root
# directory.

import argparse
import dataclasses
import functools
import io
import os.path
import pathlib
import re
import textwrap
from typing import Union, Optional, Literal, Tuple, Dict, Any, Type, List

import numpy as numpy
import pytest
from PIL import Image, ImageCms, ImageOps, ImageFilter, UnidentifiedImageError

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

    def _to_tuple(self, image: Image, blur_radius: int = 3):
        """Convert an image into a 100-tuple by scaling to 10x10 and grayscaling"""
        # Note that we don't respect aspect ratio. This is by design and allows us to
        # detect some stretching between copies.
        blurred_10x10 = self._autocrop(image).convert("L").filter(
            ImageFilter.GaussianBlur(radius=blur_radius)).resize((10, 10), Image.LANCZOS)
        simplified = blurred_10x10.quantize(colors=32)
        return tuple(simplified.getdata())

    @staticmethod
    def _autocrop(image: Image):
        """Find the largest sub-image that does not have an all-white border on any side"""
        upper_left_x = 0
        upper_left_y = 0
        lower_right_x = image.width - 1
        lower_right_y = image.height - 1
        white = white_pixel(image.mode)
        np_image = numpy.asarray(image)

        def first_column(from_end=False):
            cols = range(upper_left_x, lower_right_x)
            if from_end:
                cols = reversed(cols)
            for x in cols:
                if numpy.any(np_image[:, x] != white):
                    return x
            return None

        def first_row(from_end=False):
            rows = range(upper_left_y, lower_right_y)
            if from_end:
                rows = reversed(rows)
            for y in rows:
                if numpy.any(np_image[y, :] != white):
                    return y
            return None

        upper_left_x = first_column()
        if upper_left_x is None:
            return image
        lower_right_x = first_column(from_end=True)
        upper_left_y = first_row()
        if upper_left_y is None:
            return image
        lower_right_y = first_row(from_end=True)

        rect = (upper_left_x, upper_left_y, lower_right_x+1, lower_right_y+1)
        try:
            return image.crop(rect)
        except IndexError:
            raise RuntimeError(f"Unable to crop image {image.width}x{image.height} to: {rect!r}")

    def add(self, image: Image):
        """Add the given image to our tracking"""
        self.seen.add(self._to_tuple(image))


# Would be nice if we could just:
#  return ImageColor.getcolor('white', mode)
# but ImageColor only works with a select few modes :-(
def convert_bw_to_mode(mode: str, black: bool = False):
    """Convert a black or white pixel to the given mode"""
    return Image.new("1", (1, 1), 0 if black else 1).convert(mode).getpixel((0, 0))


@functools.cache
def white_pixel(mode: str):
    """Return a white pixel value in Image mode given"""
    return convert_bw_to_mode(mode, black=False)


@functools.cache
def black_pixel(mode: str):
    """Return a black pixel value in Image mode given"""
    return convert_bw_to_mode(mode, black=True)


def make_image_corners(mode, *corners):
    """Used for testing, make an Image with the given mode and corner pixel values"""
    corner_lookup = {
        'L': {
            'white': white_pixel("L"),
            'black': black_pixel("L"),
        },
        'RGB': {
            'white': white_pixel("RGB"),
            'black': black_pixel("RGB"),
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
        image_extension: str = 'png',
        find_duplicates: bool = False,
        save_params: Optional[Dict[str, str]] = None,
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
    :param image_extension: The filename extension (without ".") for image writing
    :param find_duplicates: Identify duplicates but do not process otherwise
    :param save_params: a dictionary of parameters to the save encoder.
      see https://pillow.readthedocs.io/en/stable/handbook/image-file-formats.html
      for details.
    :return: filename written (or existing if keep is True)
    """

    assert output_size, "Must have non-zero output size."

    ext_file = ".".join([os.fspath(filename).rsplit(".", 1)[0], image_extension])
    outfile = pathlib.Path(os.path.join(output_dir, os.path.basename(ext_file)))

    if image in img_hash:
        return {'status': 'duplicate', 'outfile': outfile}
    img_hash.add(image)
    if find_duplicates:
        return {'status': 'normal', 'outfile': outfile}

    if keep and outfile.exists():
        return {'status': 'skipped', 'outfile': outfile}

    if 0 in image.size or 1 in image.size:
        return {'status': 'small', 'outfile': outfile}

    img_scaled = ImageOps.contain(image, size=(output_size, output_size))
    if img_scaled.width == img_scaled.height:
        save_image = img_scaled
    else:
        border_color = guess_border(img_scaled)
        if not ImageInfo.is_color(img_scaled):
            border_color = (border_color, border_color, border_color)
        mode: Literal['RGBA', 'RGB'] = 'RGB'
        if trans_background:
            mode = 'RGBA'
            border_color = border_color[0:3] + (0,)
        save_image = Image.new(mode, (output_size, output_size), border_color)
        if img_scaled.width > img_scaled.height:
            y_offset = (output_size - img_scaled.height) // 2
            save_image.paste(img_scaled, (0, y_offset))
        else:
            x_offset = (output_size - img_scaled.width) // 2
            save_image.paste(img_scaled, (x_offset, 0))
    save_image.save(outfile, **(save_params or {}))
    return {'status': 'normal', 'outfile': outfile}


def safe_process_final_image(*args, **kwargs):
    """A safe wrapper for process_final_image"""
    try:
        return process_final_image(*args, **kwargs)
    except OSError as err:
        print(f"  Error processing image data: {err!r}")
        return None


def mask_image(image: Image, mask: Image, background: tuple):
    """Return the input image masked by `mask` with background defined by `background`"""
    mode = 'RGBA' if len(background) > 3 else 'RGB'
    img_base = Image.new(mode, image.size, background)
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


def summarize_status(status: Dict[str, int]):
    """Summarize image processing status info"""

    status_info = {
        'unknown': 'Unknown file types',
        'unsupported': 'Known, but unsupported files',
        'small': 'Images that were too small',
        'cmyk': 'CMYK color space images converted',
        'masked': 'Masked images composited',
        'skipped': 'Skipped',
        'duplicate': 'Duplicate image',
        'failed': 'Processing failed',
        'normal': 'Images with no mask processed',
        'total': 'Total number of processed images',
    }

    for reason in sorted(list(status.keys()) + ['total']):
        label = status_info.get(reason, reason)
        if reason == 'total':
            count = status.get('masked', 0) + status.get('normal', 0)
        else:
            count = status[reason]
        print(f"{label}: {count}")


def process_img_dir(
        img_dir: os.PathLike,
        outdir: os.PathLike = DEFAULT_OUTDIR,
        output_size: int = DEFAULT_SIZE,
        minimum_quality: float = DEFAULT_QUALITY,
        all_images: bool = False,
        unmasked: bool = False,
        keep: bool = False,
        trans_background: bool = False,
        image_extension: str = 'png',
        save_params: Optional[Dict[str, str]] = None,
        history: Optional[FuzzyImageRecall] = None,
        find_duplicates: bool = False,
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
    :param image_extension: The image file extension to save as
    :param save_params: Optional parameters to the PIL Image save formatter
    :param history: The history tracking FuzzyImageRecall state
    :param find_duplicates: Just detect duplicates
    :param srgb_profile: profile or file path to the profile to use in converting CMYK
    :param cmyk_profile: profile or file path to the profile to use for CMYK files with none
    :return: nothing
    """

    stats = {}

    def bump(status: str):
        stats[status] = stats.get(status, 0) + 1

    def img_report(img_status: Optional[Dict[str, Any]]):
        if not img_status:
            bump('failed')
        else:
            status_type = img_status['status']
            bump(status_type)
            if find_duplicates:
                if status_type == 'duplicate':
                    print(img_status['outfile'])
            else:
                print(f"  image processing {status_type}, outfile: {img_status['outfile']}")

    small_image = output_size * minimum_quality
    previous = None
    history = history or FuzzyImageRecall()
    process_args = dict(
        output_size=output_size,
        output_dir=outdir,
        keep=keep,
        trans_background=trans_background,
        img_hash=history,
        image_extension=image_extension,
        save_params=save_params,
        find_duplicates=find_duplicates,
    )
    print(f"Starting on {img_dir} -> {outdir}")
    img_dir = pathlib.Path(img_dir)  # ensure that it's not a string
    all_files = (pathlib.Path(f) for f in img_dir.glob(os.path.join('**', '*.*')) if os.path.isfile(f))
    for img_file in sorted(all_files, key=get_filename_key):
        if not find_duplicates:
            print(f" input file: {img_file}")
        if "." not in str(img_file):
            if not find_duplicates:
                print(f"  skipping unknown file type for {img_file}")
            bump('unknown')
            continue
        img_extension = str(img_file).lower().rsplit(".", 1)[-1]
        if img_extension == "ccitt":
            bump('unsupported')
            if not find_duplicates:
                print(f"  skipping {img_file} as we don't support CCITT format TIFF compression")
            continue
        elif img_extension == "params":
            bump('unsupported')
            if not find_duplicates:
                print(f"  skipping {img_file} as we don't support PARAMS files")
            continue
        try:
            info = ImageInfo.get_image_info(img_file)
        except UnidentifiedImageError as err:
            bump('unsupported')
            if not find_duplicates:
                print(f"  skipping {img_file}: {err!r}")
            continue
        if max(info.width, info.height) <= small_image:
            bump('small')
            if not find_duplicates:
                print(f"  skipping small image")
            continue
        if previous and not previous.is_mask:
            filename = os.path.join(outdir, os.path.basename(previous.file_path))
            if previous.image.mode == 'CMYK':
                bump('cmyk')
                previous.from_cmyk_to_rgb(srgb_profile, cmyk_profile)
            if previous.masked_by(info):
                info.is_mask = True
                if not unmasked:
                    white_color = white_pixel(previous.image.mode)
                    if len(white_color) == 3 and trans_background:
                        white_color = white_color + (0,)
                    img_masked = mask_image(previous.image, info.image, background=white_color)
                    img_report(safe_process_final_image(img_masked, filename=filename, **process_args))
            elif all_images or unmasked:
                img_report(safe_process_final_image(previous.image, filename=filename, **process_args))
        previous = info
    if previous and not previous.is_mask and (unmasked or all_images):
        filename = os.path.join(outdir, os.path.basename(previous.file_path))
        img_report(safe_process_final_image(previous.image, filename=filename, **process_args))
    print(f"\n{img_dir} processing complete.")
    summarize_status(stats)


def per_format_save_params(image_format: str, save_params: Dict[str, Any]):
    """
    Fix known parameter types based on image format.

    :param image_format: string such as 'png' or 'jpg'
    :param save_params: dict of parameters to Image.save
    """

    def known_params(params: List[Tuple[str, Type]]):
        for param, param_type in params:
            if param in save_params:
                save_params[param] = param_type(save_params[param])
        if diff := set(save_params.keys()).difference({p[0] for p in params}):
            print(f"WARNING: unrecognized image format parameters: {', '.join(sorted(diff))}")

    if image_format in ('jpg', 'jpeg'):
        known_params([('quality', int), ('optimize', bool), ('progressive', bool), ('comment', str)])

    if image_format == 'png':
        known_params([('optimize', bool), ('compress_level', int)])


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
            
            In these examples, the files to process are located in a directory called
            "images" and you're writing the output to the default "training_images"
            directory. These need to exist already.
            
            Process all images, rendering transparent backgrounds and saving as 720x720:
            
                process-art -a -t -s 720 tbd
            
            Process only non-masked images that are at least 75% of the target 512x512 size:
            
                process-art -u -q 0.75 tbd
            
            Convert CMYK (print-ready color format) images using a standard color
            space profile downloaded from Adobe
            (at https://www.adobe.com/support/downloads/iccprofiles/iccprofiles_win.html)
            
                process-art -a -C USWebCoatedSWOP.icc tbd
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
        'save-params': (
            "A comma-separated string of name=value pairs to pass to the image save formatter"
            " see https://pillow.readthedocs.io/en/stable/handbook/image-file-formats.html"),
        'save-format': "The image format (extension) to save as",
        'find-duplicates': "Do not run the conversion at all, just identify duplicates",
    }

    def param_arg(short_flag: str, flag: str, *args, **kwargs):
        base_flag = flag.replace('--', '', 1)
        parser.add_argument(short_flag, flag, *args, action='store', help=help_text[base_flag], **kwargs)

    def state_arg(short_flag: str, flag: str, *args, **kwargs):
        base_flag = flag.replace('--', '', 1)
        parser.add_argument(short_flag, flag, *args, action='store_true', help=help_text[base_flag], **kwargs)

    state_arg('-a', '--all')
    param_arg('-f', '--save-format', default='png')
    state_arg('-k', '--keep')
    param_arg('-o', '--output-dir', metavar='PATH', default=DEFAULT_OUTDIR, type=pathlib.Path)
    param_arg('-q', '--quality', metavar='VALUE', default=DEFAULT_QUALITY, type=float)
    param_arg('-s', '--output-size', type=int, default=DEFAULT_SIZE)
    state_arg('-t', '--transparent')
    state_arg('-u', '--unmasked')
    param_arg('-C', '--cmyk-color-profile', metavar='ICC_FILE', type=pathlib.Path)
    state_arg('-F', '--find-duplicates')
    param_arg('-S', '--srgb-color-profile', metavar='ICC_FILE', type=pathlib.Path)
    param_arg('-P', '--save-params', metavar='VALUES')

    parser.add_argument(
        'image_dirs',
        action='store', metavar='DIR', nargs='+', type=pathlib.Path, help=help_text['image_dirs']
    )

    options = parser.parse_args()

    if options.unmasked and options.all:
        raise RuntimeError(f"Cannot combine --all and --unmasked, choose one.")

    save_format = options.save_format.lower() if options.save_format else 'png'

    if options.save_params:
        save_params = dict(p.strip().split("=", 1) for p in options.save_params.split(","))
        per_format_save_params(save_format, save_params)
    else:
        save_params = None

    if options.transparent and options.save_format.lower() != 'png':
        raise RuntimeError(f"--transparent only supported for 'png' images")

    if options.cmyk_color_profile and not options.cmyk_color_profile.exists():
        raise RuntimeError(f"CMYK color profile file does not exist: {options.cmyk_color_profile}")
    if options.srgb_color_profile and not options.srgb_color_profile.exists():
        raise RuntimeError(f"sRGB color profile file does not exist: {options.srgb_color_profile}")

    history = FuzzyImageRecall()

    for img_dir in options.image_dirs:
        img_dir = img_dir.absolute()
        print(f"Processing from {img_dir}")
        process_img_dir(
            img_dir,
            output_size=options.output_size,
            minimum_quality=options.quality,
            outdir=options.output_dir,
            all_images=(options.unmasked or options.all),
            unmasked=options.unmasked,
            keep=options.keep,
            trans_background=options.transparent,
            image_extension=save_format,
            save_params=save_params,
            history=history,
            find_duplicates=options.find_duplicates,
            srgb_profile=options.srgb_color_profile,
            cmyk_profile=options.cmyk_color_profile,
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
    'mode',
    ('1', 'L', 'RGB', 'RGBA', 'CMYK'),
)
def test_autocrop(mode):
    white = white_pixel(mode)
    black = black_pixel(mode)
    image = Image.new(mode, (3, 3), white)
    assert image.getpixel((0, 0)) == white, "Image should have white pixels"
    cropped = FuzzyImageRecall._autocrop(image)
    assert cropped.size == (3, 3), "Autocrop white image should make no change"
    image.putpixel((1, 1), black)
    cropped = FuzzyImageRecall._autocrop(image)
    assert cropped.size == (1, 1), "Autocrop expected to return 1x1"
    image.putpixel((0, 0), black)
    cropped = FuzzyImageRecall._autocrop(image)
    assert cropped.size == (2, 2), "Autocrop expected to return 2x2"
    assert cropped.getpixel((0, 0)) == black, "Expect returned image to contain black in upper left"
    assert cropped.getpixel((1, 0)) == white, "Expect returned image to contain black in upper left"


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
