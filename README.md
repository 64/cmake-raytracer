# CMake Ray Tracer

A simple ray tracer written in pure CMake. Inspired by [raytracer.hpp](https://github.com/tcbrindle/raytracer.hpp).

![image](render.png)

## Usage

The ray tracer writes its output to `stderr`, so you can use it with:

```
cmake . -Wno-dev -Dimage_width=64 -Dimage_height=64 -Dnum_procs=4 2> image.ppm
```

Which writes the output to `image.ppm`. Then use an image viewer capable of opening PPM files (or [this](http://www.cs.rhodes.edu/welshc/COMP141_F16/ppmReader.html)) to view.

`num_procs` controls the number of worker processes spawned. It is recommended to set this to a value no greater than the number of cores in your CPU, for maximum performance.

For now, to keep the code simple, you are required to keep `image_width`, `image_height` and `num_procs` as powers of 2, otherwise the image may not be fully formed. If not specified, these arguments default to the values shown above.

## Contributing

All contributions (issue, PRs) are welcome. This project is licensed under the MIT license.
