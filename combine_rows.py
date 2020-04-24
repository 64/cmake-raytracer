import os, subprocess

#message("P3\n${image_width} ${image_height}\n255")

def run_cmake(n):
    build_dir = "./build/" + str(n)
    with open(build_dir + "/image.pix", "w") as out_file:
        return subprocess.Popen(["cmake", "."], cwd = build_dir, stderr = out_file)
    raise Exception

width = 100
height = 50
y_start = 0
y_end = height
n = 4
make_ppm = True

with open("CMakeLists.txt", "r") as f:
    source = f.read()
    source = "set(image_width \"" + str(width) + "\")\n\n" + source
    source = "set(image_height \"" + str(height) + "\")\n" + source
    delta_y = int((y_end - y_start) / n)
    subprocs = []

    for i in range(n):
        tmp_source = "set(image_start_y \"" + str(y_start + i * delta_y) + "\")\n" + source
        tmp_source = "set(image_end_y \"" + str(y_start + (i + 1) * delta_y - 1) + "\")\n" + tmp_source
        os.makedirs("build/" + str(i), exist_ok = True)

        with open("build/" + str(i) + "/CMakeLists.txt", "w") as out:
            out.write(tmp_source)

        subprocs.append(run_cmake(i))

    for proc in subprocs:
        proc.wait()
        if proc.returncode != 0:
            print("process failed")
    
    ppm_data = ""
    if make_ppm:
        ppm_data = "P3 " + str(width) + " " + str(height) + "\n255\n"
    
    for i in range(n):
        with open("build/" + str(i) + "/image.pix", "r") as image:
            ppm_data += image.read() + "\n"

    out_file = "image.pix"
    if make_ppm:
        out_file = "image.ppm"

    with open(out_file, "w") as ppm:
        ppm.write(ppm_data)
