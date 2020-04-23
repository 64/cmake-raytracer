cmake_minimum_required(VERSION 3.10)

set(scale "100000000")
string(LENGTH ${scale} frac_digits)
math(EXPR frac_digits "${frac_digits} - 1")

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
    math(EXPR b "${frac_digits} + 1")
    
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
    div_by_10(${quo} quo)
    set("${res}" "${quo}" PARENT_SCOPE)
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

function(truncate x res)
    math(EXPR tmp "${x} / ${scale}")
    set("${res}" "${tmp}" PARENT_SCOPE)
endfunction()

function(sqrt x res)
    if(${x} LESS 0)
        message(FATAL_ERROR "argument passed to square root ${x} was negative")
    endif()
    
    div_by_2(${x} guess)

    foreach(counter RANGE 5)
        div(${x} ${guess} tmp)
        add(${tmp} ${guess} tmp)
        div_by_2(${tmp} guess)
    endforeach()

    set("${res}" "${guess}" PARENT_SCOPE)
endfunction()

function(to_fp x res)
    string(REPLACE "." ";" both_parts "${x};0")
    list(GET both_parts 0 int_part)
    list(GET both_parts 1 frac_part)

    string(SUBSTRING ${frac_part} 0 6 frac_part)
    string(LENGTH ${frac_part} frac_length)
    math(EXPR pad_length "${frac_digits} - ${frac_length}")
    string(REPEAT "0" "${pad_length}" padding)

    if(${int_part} GREATER_EQUAL 0)
        math(EXPR tmp "(${int_part} * ${scale}) + ${frac_part}${padding}")
    else()
        math(EXPR tmp "(${int_part} * ${scale}) - ${frac_part}${padding}")
    endif()

    set("${res}" "${tmp}" PARENT_SCOPE)
endfunction()

function(from_fp x res)
    math(EXPR int_part "(${x}) / ${scale}")
    if(${int_part} EQUAL 0)
        math(EXPR x "${x} + ${scale}")
    endif()

    # Can't just do x % scale, because this does not preserve leading zeroes
    string(LENGTH ${x} x_length)
    math(EXPR decimal_point_pos "${x_length} - ${frac_digits}")
    string(SUBSTRING "${x}" ${decimal_point_pos} ${frac_digits} fract_part)

    set("${res}" "${int_part}.${fract_part}" PARENT_SCOPE)
endfunction()

function(print x)
    from_fp("${x}" tmp)
    message(${tmp})
endfunction()

sqrt(${a} b)
print(${b})

#mul(${x} ${y} z)
#print(${z})

#to_fp(255.99 rgb_scaling)
#to_fp(0.2 b)
#to_fp(${image_width} image_width_fp)
#to_fp(${image_height} image_height_fp)

#message("P3\n${image_width} ${image_height}\n255")

#foreach(y RANGE ${image_max_y})
    #set(row "")
    #to_fp(${y} y_fp)

    #foreach(x RANGE ${image_max_x})
        #to_fp(${x} x_fp)

        #div(${x_fp} ${image_width_fp} r)
        #div(${y_fp} ${image_height_fp} g)

        #mul(${r} ${rgb_scaling} r)
        #mul(${g} ${rgb_scaling} g)
        #mul(${b} ${rgb_scaling} b)

        #truncate(${r} r)
        #truncate(${g} g)
        #truncate(${b} b)

        #set(row "${row} ${r} ${g} ${b}")
    #endforeach()

    #message("${row}")
#endforeach()
