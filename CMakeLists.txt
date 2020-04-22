cmake_minimum_required(VERSION 3.10)
set(scale "100000000")
set(scale_log10 8)

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

    # Divide the quotient by 10
    string(LENGTH ${quo} quo_length)
    math(EXPR quo_length "${quo_length} - 1")
    string(SUBSTRING ${quo} 0 "${quo_length}" quo)

    set("${res}" "${quo}" PARENT_SCOPE)
endfunction()

function(to_fp x res)
    string(REPLACE "." ";" both_parts "${x};0")
    list(GET both_parts 0 int_part)
    list(GET both_parts 1 frac_part)
    string(SUBSTRING ${frac_part} 0 6 frac_part)

    math(EXPR tmp "(${int_part}) * ${scale} + ${frac_part}")
    set("${res}" "${tmp}" PARENT_SCOPE)
endfunction()

function(from_fp x res)
    math(EXPR int_part "(${x}) / ${scale}")

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

message("BEGIN_OUTPUT")

to_fp(122 a)
to_fp(11 b)
div(${a} ${b} c)
from_fp(${c} c)
message("122 / 11 = ${c}")

message("END_OUTPUT")
