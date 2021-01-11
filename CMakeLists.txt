cmake_minimum_required(VERSION 3.18) # cmake_language command requires 3.18
project(cmake-raytracer LANGUAGES NONE)

if(NOT DEFINED image_width)
    set(image_width 64)
endif()
if(NOT DEFINED image_height)
    set(image_height 64)
endif()
if(NOT DEFINED num_procs)
    set(num_procs 2)
endif()

if(NOT DEFINED worker_index)
    message(STATUS "Launching ray tracer with ${num_procs} processes, ${image_width}x${image_height} image...")

    set(exec_command "execute_process(\n")
    foreach(worker_index RANGE 1 ${num_procs})
        set(exec_command "${exec_command}COMMAND ${CMAKE_COMMAND} . -Wno-dev -Dworker_index=${worker_index} -Dimage_width=${image_width} -Dimage_height=${image_height} -Dnum_procs=${num_procs}\n")
    endforeach()
    set(exec_command "${exec_command} )")

    # Begin the worker processes
    cmake_language(EVAL CODE ${exec_command})

    message(STATUS "Finished ray tracing, gathering results...")

    # Output PPM
    set(image_contents "P3 ${image_width} ${image_height}\n255\n\n")

    foreach(worker_index RANGE 1 ${num_procs})
        file(READ "worker-${worker_index}.txt" file_contents)
        set(image_contents "${image_contents}${file_contents}")
    endforeach()

    message("${image_contents}")

    return()
elseif(${worker_index} LESS_EQUAL 0 OR ${worker_index} GREATER ${num_procs})
    message(FATAL_ERROR "worker index ${worker_index} out of bounds")
else()
    # We're in a worker process
    math(EXPR image_min_y "(${worker_index} - 1) * ${image_height} / ${num_procs}")
    math(EXPR image_max_y "${worker_index} * ${image_height} / ${num_procs} - 1")

    math(EXPR image_max_x "${image_width} - 1")
endif()

set(scale "100000000")
string(LENGTH ${scale} frac_digits)
math(EXPR frac_digits "${frac_digits} - 1")

function(add a b res)
    math(EXPR tmp "(${a}) + (${b})")
    set("${res}" "${tmp}" PARENT_SCOPE)
endfunction()

function(sub a b res)
    math(EXPR tmp "(${a}) - (${b})")
    set("${res}" "${tmp}" PARENT_SCOPE)
endfunction()

function(mul a b res)
    math(EXPR tmp "((${a}) * (${b})) / ${scale}")
    set("${res}" "${tmp}" PARENT_SCOPE)
endfunction()

function(div a b res)
    math(EXPR tmp "((${a}) * (${scale})) / ${b}")
    set("${res}" "${tmp}" PARENT_SCOPE)
endfunction()

function(fract x res)
    math(EXPR tmp "${x} % ${scale}")
    set(${res} ${tmp} PARENT_SCOPE)
endfunction()

# TODO: Is a regex quicker here?
function(div_by_10 x res)
    string(LENGTH ${x} len)
    math(EXPR len "${len} - 1")
    string(SUBSTRING ${x} 0 "${len}" tmp)
    set("${res}" "${tmp}" PARENT_SCOPE)
endfunction()

function(div_by_2 x res)
    math(EXPR tmp "${x} >> 1")
    set("${res}" "${tmp}" PARENT_SCOPE)
endfunction()

function(mul_by_2 x res)
    math(EXPR tmp "${x} << 1")
    set("${res}" "${tmp}" PARENT_SCOPE)
endfunction()

function(truncate x res)
    math(EXPR tmp "${x} / ${scale}")
    set("${res}" "${tmp}" PARENT_SCOPE)
endfunction()

function(sqrt x res)
    if(${x} LESS 0)
        message(FATAL_ERROR "arg passed to square root ${x} was negative")
    endif()
    
    div_by_2(${x} guess)

    foreach(counter RANGE 5)
        if(${guess} EQUAL 0)
            set("${res}" 0 PARENT_SCOPE)
            return()
        endif()

        div(${x} ${guess} tmp)
        add(${tmp} ${guess} tmp)
        div_by_2(${tmp} guess)
    endforeach()

    set("${res}" "${guess}" PARENT_SCOPE)
endfunction()

function(vec3_add x y res)
    list(GET ${x} 0 x_0)
    list(GET ${x} 1 x_1)
    list(GET ${x} 2 x_2)
    list(GET ${y} 0 y_0)
    list(GET ${y} 1 y_1)
    list(GET ${y} 2 y_2)
    add(${x_0} ${y_0} z_0)
    add(${x_1} ${y_1} z_1)
    add(${x_2} ${y_2} z_2)
    set("${res}" ${z_0} ${z_1} ${z_2} PARENT_SCOPE)
endfunction()

function(vec3_sub x y res)
    list(GET ${x} 0 x_0)
    list(GET ${x} 1 x_1)
    list(GET ${x} 2 x_2)
    list(GET ${y} 0 y_0)
    list(GET ${y} 1 y_1)
    list(GET ${y} 2 y_2)
    sub(${x_0} ${y_0} z_0)
    sub(${x_1} ${y_1} z_1)
    sub(${x_2} ${y_2} z_2)
    set("${res}" ${z_0} ${z_1} ${z_2} PARENT_SCOPE)
endfunction()

function(vec3_mul x y res)
    list(GET ${x} 0 x_0)
    list(GET ${x} 1 x_1)
    list(GET ${x} 2 x_2)
    list(GET ${y} 0 y_0)
    list(GET ${y} 1 y_1)
    list(GET ${y} 2 y_2)
    mul(${x_0} ${y_0} z_0)
    mul(${x_1} ${y_1} z_1)
    mul(${x_2} ${y_2} z_2)
    set("${res}" ${z_0} ${z_1} ${z_2} PARENT_SCOPE)
endfunction()

function(vec3_mulf x y res)
    list(GET ${x} 0 x_0)
    list(GET ${x} 1 x_1)
    list(GET ${x} 2 x_2)
    mul(${x_0} ${y} z_0)
    mul(${x_1} ${y} z_1)
    mul(${x_2} ${y} z_2)
    set("${res}" ${z_0} ${z_1} ${z_2} PARENT_SCOPE)
endfunction()

function(vec3_divf x y res)
    list(GET ${x} 0 x_0)
    list(GET ${x} 1 x_1)
    list(GET ${x} 2 x_2)
    div(${x_0} ${y} z_0)
    div(${x_1} ${y} z_1)
    div(${x_2} ${y} z_2)
    set("${res}" ${z_0} ${z_1} ${z_2} PARENT_SCOPE)
endfunction()

function(vec3_dot x y res)
    list(GET ${x} 0 x_0)
    list(GET ${x} 1 x_1)
    list(GET ${x} 2 x_2)
    list(GET ${y} 0 y_0)
    list(GET ${y} 1 y_1)
    list(GET ${y} 2 y_2)
    mul(${x_0} ${y_0} z_0)
    mul(${x_1} ${y_1} z_1)
    mul(${x_2} ${y_2} z_2)
    add(${z_0} ${z_1} tmp)
    add(${tmp} ${z_2} tmp)
    set("${res}" ${tmp} PARENT_SCOPE)
endfunction()

function(vec3_truncate x res)
    list(GET ${x} 0 x_0)
    list(GET ${x} 1 x_1)
    list(GET ${x} 2 x_2)
    truncate(${x_0} z_0)
    truncate(${x_1} z_1)
    truncate(${x_2} z_2)
    set("${res}" ${z_0} ${z_1} ${z_2} PARENT_SCOPE)
endfunction()

function(vec3_sqrt x res)
    list(GET ${x} 0 x_0)
    list(GET ${x} 1 x_1)
    list(GET ${x} 2 x_2)
    sqrt(${x_0} z_0)
    sqrt(${x_1} z_1)
    sqrt(${x_2} z_2)
    set("${res}" ${z_0} ${z_1} ${z_2} PARENT_SCOPE)
endfunction()

function(vec3_normalize x res)
    vec3_dot(${x} ${x} x_2)
    rsqrt(${x_2} one_over_length)
    vec3_mulf(${x} ${one_over_length} tmp)
    set("${res}" ${tmp} PARENT_SCOPE)
endfunction()

# Convert a number to fixed point representation
function(to_fp x res)
    # Basic idea: split into integer and fractional parts,
    # multiply both by scale and combine.
    string(REPLACE "." ";" both_parts "${x};0")
    list(GET both_parts 0 int_part)
    list(GET both_parts 1 frac_part)
    string(SUBSTRING ${int_part} 0 1 sign)

    string(SUBSTRING ${frac_part} 0 6 frac_part)
    string(LENGTH ${frac_part} frac_length)
    math(EXPR pad_length "${frac_digits} - ${frac_length}")
    string(REPEAT "0" "${pad_length}" padding)

    if(${sign} STREQUAL "-")
        math(EXPR tmp "${int_part} * ${scale} - ${frac_part}${padding}")
    else()
        math(EXPR tmp "${int_part} * ${scale} + ${frac_part}${padding}")
    endif()

    set("${res}" "${tmp}" PARENT_SCOPE)
endfunction()

# Converts from fixed point to normal representation
# Doesn't really need to be fast as we only use it for debugging
function(from_fp x res)
    math(EXPR int_part "(${x}) / ${scale}")
    if(${int_part} EQUAL 0)
        if(${x} GREATER_EQUAL 0)
            math(EXPR x "${x} + ${scale}")
        else()
            set(int_part "-0")
            math(EXPR x "${x} - ${scale}")
        endif()
    endif()

    # Can't just do x % scale, because this does not preserve leading zeroes
    string(LENGTH ${x} x_length)
    math(EXPR decimal_point_pos "${x_length} - ${frac_digits}")
    string(SUBSTRING "${x}" ${decimal_point_pos} ${frac_digits} fract_part)

    set("${res}" "${int_part}.${fract_part}" PARENT_SCOPE)
endfunction()

to_fp(1.5 three_halves)

function(rsqrt x res)
    if(${x} LESS 0)
        message(FATAL_ERROR "arg to inverse square root ${x} was negative")
    endif()
    
    div_by_2(${x} x2)
    div(${scale} ${x} guess) # guess = 1/x

    foreach(counter RANGE 5)
        mul(${guess} ${guess} tmp)
        mul(${tmp} ${x2} tmp)
        sub(${three_halves} ${tmp} tmp)
        mul(${tmp} ${guess} guess)
    endforeach()

    set("${res}" "${guess}" PARENT_SCOPE)
endfunction()

function(vec3_to_fp x y z res)
    to_fp(${x} x)
    to_fp(${y} y)
    to_fp(${z} z)
    set("${res}" ${x} ${y} ${z} PARENT_SCOPE)
endfunction()

function(vec3_print v)
    list(GET ${v} 0 v_0)
    list(GET ${v} 1 v_1)
    list(GET ${v} 2 v_2)
    from_fp(${v_0} v_0)
    from_fp(${v_1} v_1)
    from_fp(${v_2} v_2)
    message("{ ${v_0}, ${v_1}, ${v_2} }")
endfunction()

function(print x)
    from_fp("${x}" tmp)
    message(${tmp})
endfunction()

function(abs x res)
    if(${x} LESS 0)
        math(EXPR tmp "-${x}")
        set(${res} ${tmp} PARENT_SCOPE)
    else()
        set(${res} ${x} PARENT_SCOPE)
    endif()
endfunction()

function(clamp_0_1 x res)
    if(${x} GREATER ${scale})
        set("${res}" ${scale} PARENT_SCOPE)
    elseif(${x} LESS 0)
        set("${res}" 0 PARENT_SCOPE)
    else()
        set("${res}" ${x} PARENT_SCOPE)
    endif()
endfunction()

function(vec3_clamp_0_1 x res)
    list(GET ${x} 0 x_0)
    list(GET ${x} 1 x_1)
    list(GET ${x} 2 x_2)
    clamp_0_1(${x_0} z_0)
    clamp_0_1(${x_1} z_1)
    clamp_0_1(${x_2} z_2)
    set("${res}" ${z_0} ${z_1} ${z_2} PARENT_SCOPE)
endfunction()

function(sphere_intersect ray_origin ray_dir hit_t hit_point hit_normal)
    vec3_sub(${ray_origin} sphere_center oc)
    vec3_dot(${ray_dir} ${ray_dir} a)
    vec3_dot(oc ${ray_dir} half_b)
    vec3_dot(oc oc oc_2)
    mul(${sphere_radius} ${sphere_radius} radius_2)
    sub(${oc_2} ${radius_2} c)

    mul(${half_b} ${half_b} half_b_2)
    mul(${a} ${c} ac)
    sub(${half_b_2} ${ac} discrim)

    if(${discrim} GREATER 0)
        sqrt(${discrim} root)
        sub(0 ${half_b} minus_half_b)

        sub(${minus_half_b} ${root} t)
        div(${t} ${a} t)
        if(${t} GREATER 0)
            # p = o + t * d
            vec3_mulf(${ray_dir} ${t} tv)
            vec3_add(${ray_origin} tv point)
            vec3_sub(point sphere_center normal)
            vec3_divf(normal ${sphere_radius} unit_normal)
            set(${hit_point} ${point} PARENT_SCOPE)
            set(${hit_normal} ${unit_normal} PARENT_SCOPE)
            set(${hit_t} ${t} PARENT_SCOPE)
            return()
        endif()

        add(${minus_half_b} ${root} t)
        div(${t} ${a} t)
        if (${t} GREATER 0)
            # p = o + t * d
            vec3_mulf(${ray_dir} ${t} tv)
            vec3_add(${ray_origin} tv point)
            vec3_sub(point sphere_center normal)
            vec3_divf(normal ${sphere_radius} unit_normal)
            set(${hit_point} ${point} PARENT_SCOPE)
            set(${hit_normal} ${unit_normal} PARENT_SCOPE)
            set(${hit_t} ${t} PARENT_SCOPE)
            return()
        endif()
    endif()

    set(${hit_t} -1 PARENT_SCOPE)
endfunction()

function(plane_intersect ray_origin ray_dir hit_t hit_point hit_normal)
    list(GET ${ray_dir} 1 ray_d_y)
    if(${ray_d_y} EQUAL 0)
        set(${hit_t} -1 PARENT_SCOPE)
    else()
        # t = (c - o.y) / d.y
        list(GET ${ray_origin} 1 ray_o_y)
        sub(${plane_y} ${ray_o_y} ray_y_dist)
        div(${ray_y_dist} ${ray_d_y} t) 
        if(${t} GREATER 0 AND ${t} LESS 2000000000)
            vec3_mulf(${ray_dir} ${t} ray_scaled_d)
            vec3_add(${ray_origin} ray_scaled_d point)
            set(${hit_t} ${t} PARENT_SCOPE)
            set(${hit_point} ${point} PARENT_SCOPE)
            set(${hit_normal} 0 ${scale} 0 PARENT_SCOPE)
        else()
            set(${hit_t} -1 PARENT_SCOPE)
        endif()
    endif()
endfunction()

function(offset_origin ray_origin hit_norm out_origin)
    vec3_mulf(${hit_norm} ${ray_epsilon} scaled_norm)
    vec3_add(scaled_norm ${ray_origin} origin)
    set(${out_origin} ${origin} PARENT_SCOPE)
endfunction()

# Doesn't account for shadowing, this is faked
function(light_contrib point norm light_pos light_col out_col)
    vec3_sub(${light_pos} ${point} l)
    vec3_normalize(l lnorm)
    vec3_dot(${norm} lnorm ndotl)

    if(${ndotl} LESS 0)
        set(${out_col} 0 0 0 PARENT_SCOPE)
    else()
        vec3_mulf(${light_col} ${ndotl} unscaled_out)
        vec3_dot(l l l2)
        vec3_divf(unscaled_out ${l2} out)
        set(${out_col} ${out} PARENT_SCOPE)
    endif()
endfunction()

# Ray dir must be normalized
function(trace ray_origin ray_dir depth color)
    if(${depth} GREATER_EQUAL 3)
        return()
    else()
        math(EXPR depth "${depth} + 1")
    endif()

    sphere_intersect(${ray_origin} ${ray_dir} hit_t_1 hit_point_1 hit_normal_1)
    plane_intersect(${ray_origin} ${ray_dir} hit_t_2 hit_point_2 hit_normal_2)
    if(${hit_t_1} GREATER ${ray_epsilon})
        # specular reflection
        offset_origin(hit_point_1 hit_normal_1 new_origin)

        # reflect
        vec3_dot(hit_normal_1 ${ray_dir} scalar)
        mul_by_2(${scalar} scalar)
        vec3_mulf(hit_normal_1 ${scalar} refl_a)
        vec3_sub(${ray_dir} refl_a new_dir)

        trace(new_origin new_dir ${depth} traced_col)

        set(col 0 0 0)
        light_contrib(hit_point_1 hit_normal_1 light1_pos light1_col out_col1)
        light_contrib(hit_point_1 hit_normal_1 light2_pos light2_col out_col2)
        vec3_add(col out_col1 col)
        vec3_add(col out_col2 col)
        vec3_add(col traced_col col)

        set(base_col ${sphere_color})
        vec3_mul(base_col col col)

    elseif(${hit_t_2} GREATER ${ray_epsilon})
        set(light_col 0 0 0)

        list(GET hit_point_2 0 hit_p_x)
        list(GET hit_point_2 2 hit_p_z)

        # Use equation of a circle to fake shadow
        sub(${hit_p_z} ${shadow_center} shadow_offset_z)
        mul(${hit_p_x} ${hit_p_x} shadow_offset_x_2)
        mul(${shadow_offset_z} ${shadow_offset_z} shadow_offset_z_2)
        add(${shadow_offset_x_2} ${shadow_offset_z_2} hit_dist_2)

        light_contrib(hit_point_2 hit_normal_2 light1_pos light1_col out_col1)
        light_contrib(hit_point_2 hit_normal_2 light2_pos light2_col out_col2)
        vec3_add(light_col out_col1 light_col)
        vec3_add(light_col out_col2 light_col)
        if((${hit_dist_2} LESS ${shadow_radius2}) AND (${depth} LESS 2))
          vec3_mulf(light_col ${tenth} light_col)
        endif()

        # Calculate checkerboard pattern
        # TODO: Is there a better way?
        math(EXPR half "${scale} / 2")
        math(EXPR hit_p_x "${hit_p_x} % ${scale}")
        math(EXPR hit_p_z "${hit_p_z} % ${scale}")

        # CMake modulo yields negative values for negative arguments, fortunately it is easy to fix.
        if(${hit_p_x} LESS 0)
            add(${hit_p_x} ${scale} hit_p_x)
        endif()
        if(${hit_p_z} LESS 0)
            add(${hit_p_z} ${scale} hit_p_z)
        endif()

        if((${hit_p_x} GREATER ${half}) AND (${hit_p_z} GREATER ${half}))
            set(base_col ${plane_color_1})
        elseif((${hit_p_x} LESS ${half}) AND (${hit_p_z} LESS ${half}))
            set(base_col ${plane_color_1})
        else()
            set(base_col ${plane_color_2})
        endif()

        vec3_mul(light_col base_col col)
    else()
        set(col 0 0 0)
    endif()

    set("${color}" ${col} PARENT_SCOPE)
endfunction()

to_fp(255.99 rgb_scaling)
to_fp(0.5 half)
to_fp(0.1 tenth)
to_fp(${image_width} image_width_fp)
to_fp(${image_height} image_height_fp)
to_fp(0.01 ray_epsilon)

to_fp(2 sphere_radius)
vec3_to_fp(0.0 0.0 3.0 sphere_center)
vec3_to_fp(0.3 0.3 0.3 sphere_color)

to_fp(3.0 shadow_center)
to_fp(4 shadow_radius2)

to_fp(-2 plane_y)
vec3_to_fp(0.6 0.6 0.6 plane_color_1)
vec3_to_fp(0.1 0.1 0.1 plane_color_2)

vec3_to_fp(-2 4 1 light1_pos)
vec3_to_fp(20 3 3 light1_col)

vec3_to_fp(2 4 1 light2_pos)
vec3_to_fp(3 20 3 light2_col)

file(REMOVE "worker-${worker_index}.txt")

foreach(y RANGE ${image_min_y} ${image_max_y})
    set(row "")
    to_fp(${y} y_fp)
    div(${y_fp} ${image_height_fp} v)

    mul_by_2(${v} v2)
    sub(${scale} ${v2} ray_dir_y)

    foreach(x RANGE ${image_max_x})
        to_fp(${x} x_fp)
        set(rgb 0 0 0)

        div(${x_fp} ${image_width_fp} u)

        mul_by_2(${u} u2)
        sub(${u2} ${scale} ray_dir_x)

        set(ray_dir ${ray_dir_x} ${ray_dir_y} ${scale})
        set(d ${ray_dir})

        set(o 0 0 0)
        trace(o d 0 rgb)

        vec3_clamp_0_1(rgb rgb)

        vec3_sqrt(rgb rgb) # approx gamma correction (1/2 \approx 1/2.2)
        vec3_mulf(rgb ${rgb_scaling} rgb)
        vec3_truncate(rgb rgb) # shitty tonemap

        list(GET rgb 0 r)
        list(GET rgb 1 g)
        list(GET rgb 2 b)
        set(row "${row} ${r} ${g} ${b}")
    endforeach()

    file(APPEND "worker-${worker_index}.txt" "${row}\n")
endforeach()

