# CMake Ray Tracer

A simple ray tracer written in pure CMake. Inspired by [raytracer.hpp](https://github.com/tcbrindle/raytracer.hpp).

## Configuration

The width, height and number of worker subprocesses (effectively the number of CPU cores used for the render) spawned by the ray tracer is controlled by the first few lines of the `CMakeLists.txt`:

```cmake
set(image_width "128")
set(image_height "128")
set(num_procs 4)
```

For now, you should keep all of these as powers of 2, otherwise the image may not be fully formed, but these bugs can be fixed.

## Usage

The ray tracer writes its output to `stderr`, so you can use it with:

```
cmake . -Wno-dev 2> image.ppm
```

Which writes the output to `image.ppm`. Then use an image viewer capable of opening PPM files (or [this](http://www.cs.rhodes.edu/welshc/COMP141_F16/ppmReader.html)) to view.
