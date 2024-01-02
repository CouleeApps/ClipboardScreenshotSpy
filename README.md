# ClipboardScreenshotSpy
_Make Ctrl+Cmd+Shift+4 save files to my Desktop too_

## What It Does

When taking screenshots while holding Ctrl, they are now saved to both
your clipboard and your specified screenshots directory. That way you
both get the convenience of a screenshot on your clipboard, and the
historical value of a screenshots folder with 1000s of pictures that
you can look back upon and reminisce.

## Why You Would Want This

If you want to have a nice history of all of the screenshots you've
ever taken, but also want to be lazy and use Cmd+Shift+4 and have them
copied directly to the clipboard, then you may want this. It's also an
extremely minimal implementation, not trying to be a whole screenshot
app replacement or something fancy like an image uploader.

Realistically, I made this for myself because this was a thing I
wanted, and now it's uploaded in case anyone else wants it too.

## How It Does This

Every second, this app scans your clipboard for images with a comment
of `Screenshot`. If one is detected, it checks its hash against the
previously saved image, and if the hash is different, saves a copy to
your chosen screenshot location (via screenshot preferences).

## License

MIT License.
