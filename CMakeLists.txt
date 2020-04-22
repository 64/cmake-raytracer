cmake_minimum_required(VERSION 3.10)

set(scale "100000000")
string(LENGTH ${scale} scale_log10)
math(EXPR scale_log10 "${scale_log10} - 1")

set(image_width "256")
set(image_height "256")

math(EXPR image_max_x "${image_width} - 1")
math(EXPR image_max_y "${image_height} - 1")

function(add a b res)
    math(EXPR tmp "(${a}) + (${b})")
    set("${res}" "${tmp}" PARENT_SCOPE)
endfunction()

function(sub a b res)
    math(EXPR sub "(${a}) - (${b})")
    set("${res}" "${tmp}" PARENT_SCOPE)
endfunction()

function(mul a b res)
    math(EXPR tmp "((${a}) * (${b})) / ${scale}")
    set("${res}" "${tmp}" PARENT_SCOPE)
endfunction()

function(div rem div res)
    set(quo 0)
    math(EXPR b "${scale_log10} + 1")
    
    while((NOT ("${rem}" EQUAL 0)) AND ("${b}" GREATER_EQUAL 0))
        math(EXPR d "${rem} / ${div}")
        math(EXPR rem "${rem} % ${div}")
        string(REPEAT "0" "${b}" zeroes)
        math(EXPR quo "${quo} + (${d} * 1${zeroes})")
        set(rem "${rem}0")
        math(EXPR b "${b} - 1")
    endwhile()

    if("${quo}" EQUAL 0)
        set("${res}" "${quo}" PARENT_SCOPE)
        return()
    endif()

    # Divide the quotient by 10 (remove the last digit)
    # TODO: Is a regex quicker here?
    string(LENGTH ${quo} quo_length)
    math(EXPR quo_length "${quo_length} - 1")
    string(SUBSTRING ${quo} 0 "${quo_length}" quo)

    set("${res}" "${quo}" PARENT_SCOPE)
endfunction()

function(truncate x res)
    math(EXPR tmp "${x} / ${scale}")
    set("${res}" "${tmp}" PARENT_SCOPE)
endfunction()

function(to_fp x res)
    string(REPLACE "." ";" both_parts "${x};0")
    list(GET both_parts 0 int_part)
    list(GET both_parts 1 frac_part)

    string(SUBSTRING ${frac_part} 0 6 frac_part)
    string(LENGTH ${frac_part} frac_length)
    math(EXPR pad_length "${scale_log10} - ${frac_length}")
    string(REPEAT "0" "${pad_length}" padding)

    math(EXPR tmp "(${int_part} * ${scale}) + ${frac_part}${padding}")
    set("${res}" "${tmp}" PARENT_SCOPE)
endfunction()

function(from_fp x res)
    if(${x} EQUAL 0)
        set("${res}" 0 PARENT_SCOPE)
        return()
    endif()

    math(EXPR int_part "(${x}) / ${scale}")
    message(STATUS ${x})
    if(${int_part} EQUAL 0)
        math(EXPR x "${x} + ${scale}")
    endif()

    # Can't just do x % scale, because this does not preserve leading zeroes
    string(LENGTH ${x} x_length)
    math(EXPR decimal_point_pos "${x_length} - ${scale_log10}")
    string(SUBSTRING "${x}" ${decimal_point_pos} ${scale_log10} fract_part)

    set("${res}" "${int_part}.${fract_part}" PARENT_SCOPE)
endfunction()

function(print x)
    from_fp("${x}" tmp)
    message(${tmp})
endfunction()

message("P3\n${image_width} ${image_height}\n255")

to_fp(255.99 rgb_scaling)
to_fp(0.2 b)
to_fp(${image_width} image_width_fp)
to_fp(${image_height} image_height_fp)

foreach(y RANGE ${image_max_y})
    set(row "")
    to_fp(${y} y_fp)

    foreach(x RANGE ${image_max_x})
        to_fp(${x} x_fp)

        div(${x_fp} ${image_width_fp} r)
        div(${y_fp} ${image_height_fp} g)

        mul(${r} ${rgb_scaling} r)
        mul(${g} ${rgb_scaling} g)
        mul(${b} ${rgb_scaling} b)

        truncate(${r} r)
        truncate(${g} g)
        truncate(${b} b)

        set(row "${row} ${r} ${g} ${b}")
    endforeach()

    message("${row}")
endforeach()
