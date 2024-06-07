set(CRC_LOOKUP_TABLE
-771559539 -1526341861 1007455905 1259060791 -714134636 -1570235646 996231864 1281784366
-589731905 -1411492055 852952723 1171273221 -608918618 -1397517520 901431946 1119744540
-810156055 -1196241025 565944005 1455205971 -925352976 -1075901594 651582172 1372678730
-1049724965 -1234614451 794826487 1483155041 -972835902 -1325104300 671994606 1594548856
-378745019 -1637089325 123907689 1885708031 -301921444 -1727644726 1010288 1997036262
-407419017 -1867483167 163128923 2126386893 -522550418 -1747078152 248832578 2043925204
-186917087 -2082672713 450215437 1842515611 -206169288 -2068763730 498629140 1790921346
-100641005 -1928894587 336475711 1661535913 -43150582 -1972722788 325317158 1684325040
-1528910307 -740712821 1255198513 1037565863 -1548523004 -726377838 1304234792 985283518
-1442503121 -587065671 1141589763 856455061 -1385635274 -630205792 1130791706 878818188
-1184252295 -831615249 1466425173 543223747 -1107002784 -922531082 1342839628 655174618
-1213057461 -1061878051 1505515367 784033777 -1327500718 -942095676 1590793086 701932520
-1615819051 -390611389 1908338681 112844655 -1730327860 -270894502 1993550816 30677878
-1855256857 -429115791 2137352139 140662621 -1777941762 -519966104 2013832146 252678980
-2113429839 -184504793 1812594589 453955339 -2056627544 -227710402 1801730948 476252946
-1931733373 -69523947 1657960367 366298937 -1951280486 -55123444 1707062198 314082080
1069182125 1220369467 -776729215 -1498202857 953657524 1339070498 -690370152 -1579222770
828499103 1181144073 -546339405 -1469532891 906764422 1091244048 -670940758 -1358597828
571309257 1426738271 -872210971 -1157354125 627095760 1382516806 -881927684 -1133909654
752284923 1540473965 -1025993257 -1243634367 733688034 1555824756 -977972786 -1296932520
81022053 1943239923 -354800311 -1646453281 62490748 1958656234 -306714288 -1699685946
168805463 2097738945 -469654149 -1828284947 224526414 2053451992 -479436446 -1804905996
425942017 1852075159 -143835859 -2140533317 504272920 1762240654 -268371660 -2029532766
397988915 1623188645 -105466593 -1900968567 282398762 1741824188 -19173114 -1982054000
1231433021 1046551979 -1486337007 -797999993 1309403428 957143474 -1610250232 -687687522
1203610895 817534361 -1447836637 -558566219 1087398166 936857984 -1361182662 -640077652
1422998873 601230799 -1159766923 -841454365 1404893504 616286678 -1112369044 -894064390
1510651243 755860989 -1274751929 -1023154991 1567060338 710951396 -1284960162 -999415608
1913130485 84884835 -1677300519 -352232369 1969605100 40040826 -1687443264 -328427434
2094237127 198489425 -1830951701 -438643587 2076066270 213479752 -1783619342 -491319196
1874795921 414723335 -2119074627 -155825109 1758648712 534112542 -2032355164 -237270990
1633981859 375629109 -1888815985 -127024103 1711886778 286155052 -2012794730 -16777216
)

# Decimal, big-endian
function(to_two_bytes)
    set(ONE_VALUE_ARGS NUMBER OUTPUT)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "" "${ONE_VALUE_ARGS}" "")
    math(EXPR BYTE_1 "${ARG_NUMBER} / 256")
    math(EXPR BYTE_2 "${ARG_NUMBER} % 256")
    set(${ARG_OUTPUT} ${BYTE_1} ${BYTE_2} PARENT_SCOPE)
endfunction()

# Decimal, big-endian
function(to_four_bytes)
    set(ONE_VALUE_ARGS NUMBER OUTPUT)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "" "${ONE_VALUE_ARGS}" "")
    math(EXPR BYTE_1 "(${ARG_NUMBER} & 0xFF000000) >> 24")
    math(EXPR BYTE_2 "(${ARG_NUMBER} & 0x00FF0000) >> 16")
    math(EXPR BYTE_3 "(${ARG_NUMBER} & 0x0000FF00) >> 8")
    math(EXPR BYTE_4 "${ARG_NUMBER} & 0x000000FF")
    set(${ARG_OUTPUT} ${BYTE_1} ${BYTE_2} ${BYTE_3} ${BYTE_4} PARENT_SCOPE)
endfunction()

function(compute_adler32)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "" OUTPUT DATA)
    set(ACCUMULATOR_1 1)
    set(ACCUMULATOR_2 0)
    foreach(ELEMENT IN LISTS ARG_DATA)
        math(EXPR ACCUMULATOR_1 "(${ELEMENT} + ${ACCUMULATOR_1}) % 65521")
        math(EXPR ACCUMULATOR_2 "(${ACCUMULATOR_1} + ${ACCUMULATOR_2}) % 65521")
    endforeach()
    to_two_bytes(NUMBER ${ACCUMULATOR_1} OUTPUT BYTES_1)
    to_two_bytes(NUMBER ${ACCUMULATOR_2} OUTPUT BYTES_2)
    set(${ARG_OUTPUT} ${BYTES_2} ${BYTES_1} PARENT_SCOPE)
endfunction()

function(compute_crc32)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "" OUTPUT DATA)
    set(CRC 0)
    foreach(BYTE IN LISTS ARG_DATA)
        math(EXPR INDEX "(${CRC} & 0xFF) ^ ${BYTE}")
        list(GET CRC_LOOKUP_TABLE ${INDEX} TABLE_VALUE)
        math(EXPR CRC "${TABLE_VALUE} ^ ((${CRC} & 0xFFFFFFFF) >> 8)")
    endforeach()
    to_four_bytes(NUMBER ${CRC} OUTPUT CRC_BYTES)
    set(${ARG_OUTPUT} ${CRC_BYTES} PARENT_SCOPE)
endfunction()

function(encode_deflate_block)
    cmake_parse_arguments(PARSE_ARGV 0 ARG LAST_BLOCK OUTPUT DATA)

    # Start with a DEFLATE block header. From the least significant bit:
    #   BFINAL = 1/0 (last block/not last block)
    #   BTYPE  = 00  (no compression)
    # Other bits in the byte are skipped when compression is disabled.
    if(ARG_LAST_BLOCK)
        set(RESULT 1)
    else()
        set(RESULT 0)
    endif()

    # Next is two bytes for the length of the block, followed by the one's
    # complement of the length. Even though the rest of the PNG uses big
    # endian numbers, deflate uses little endian lengths.
    list(LENGTH ARG_DATA LEN)
    to_two_bytes(NUMBER ${LEN} OUTPUT LEN_BYTES)
    list(REVERSE LEN_BYTES)
    list(APPEND RESULT ${LEN_BYTES})
    foreach(LEN_BYTE IN LISTS LEN_BYTES)
        math(EXPR NLEN_BYTE "~${LEN_BYTE} & 0xFF")
        list(APPEND RESULT ${NLEN_BYTE})
    endforeach()

    # And finally the actual block data itself.
    list(APPEND RESULT ${ARG_DATA})
    set(${ARG_OUTPUT} ${RESULT} PARENT_SCOPE)
endfunction()

function(encode_zlib)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "" OUTPUT DATA)

    # Start with a zlib stream header.
    #   CM     =  8 ("deflate" compression method)
    #   CINFO  =  0 (window size of 256, unused with compression disabled)
    #   FCHECK = 29 (ensures header is a multiple of 31)
    #   FDICT  =  0 (no preset dictionary)
    #   FLEVEL =  0 (compressor used fastest algorithm)
    set(RESULT 8 29)

    # Each DEFLATE block uses two bytes for length, so break up the data into
    # blocks that are at most 2^16-1 bytes long.
    list(LENGTH ARG_DATA LEN)
    math(EXPR LAST_INDEX "${LEN} - 1")
    foreach(START_INDEX RANGE 0 ${LAST_INDEX} 65535)
        list(SUBLIST ARG_DATA ${START_INDEX} 65535 BLOCK_DATA)
        math(EXPR NEXT_INDEX "${START_INDEX} + 65535")
        if(NEXT_INDEX GREATER LAST_INDEX)
            encode_deflate_block(LAST_BLOCK OUTPUT DEFLATE_BLOCK DATA ${BLOCK_DATA})
        else()
            encode_deflate_block(OUTPUT DEFLATE_BLOCK DATA ${BLOCK_DATA})
        endif()
        list(APPEND RESULT ${DEFLATE_BLOCK})
    endforeach()

    # The zlib stream ends with an ADLER32 checksum of the uncompressed data.
    compute_adler32(OUTPUT CHECKSUM DATA ${ARG_DATA})
    list(APPEND RESULT ${CHECKSUM})
    set(${ARG_OUTPUT} ${RESULT} PARENT_SCOPE)
endfunction()

function(encode_png_block)
    set(ONE_VALUE_KEYWORDS OUTPUT NAME)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "" "${ONE_VALUE_KEYWORDS}" DATA)

    # Get the ASCII bytes corresponding to block type name.
    set(RESULT)
    string(HEX ${ARG_NAME} HEX_NAME)
    foreach(INDEX RANGE 0 6 2)
        string(SUBSTRING ${HEX_NAME} ${INDEX} 2 HEX_BYTE)
        string(PREPEND HEX_BYTE "0x")
        math(EXPR HEX_BYTE ${HEX_BYTE})
        list(APPEND RESULT ${HEX_BYTE})
    endforeach()

    # Add the block data.
    list(APPEND RESULT ${ARG_DATA})

    # The CRC-32 checksum includes the block type, but not the block length.
    compute_crc32(OUTPUT CHECKSUM DATA ${RESULT})
    list(APPEND RESULT ${CHECKSUM})

    # Length comes at the beginning of the block.
    list(LENGTH ARG_DATA LEN)
    to_four_bytes(NUMBER ${LEN} OUTPUT LEN_BYTES)
    list(PREPEND RESULT ${LEN_BYTES})
    set(${ARG_OUTPUT} ${RESULT} PARENT_SCOPE)
endfunction()

function(encode_png)
    set(ONE_VALUE_KEYWORDS OUTPUT WIDTH HEIGHT)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "" "${ONE_VALUE_KEYWORDS}" DATA)

    # Magic bytes at the beginning of the PNG format.
    set(RESULT 137 80 78 71 13 10 26 10)

    # The IHDR block starts with width and height.
    set(IHDR_DATA)
    to_four_bytes(NUMBER ${ARG_WIDTH} OUTPUT IHDR_DATA)
    to_four_bytes(NUMBER ${ARG_HEIGHT} OUTPUT HEIGHT_BYTES)
    list(APPEND IHDR_DATA ${HEIGHT_BYTES})

    # Set all the other values to truecolor 8-bit with no interlacing.
    list(APPEND IHDR_DATA 8 2 0 0 0)
    encode_png_block(OUTPUT IHDR_BYTES NAME IHDR DATA ${IHDR_DATA})
    list(APPEND RESULT ${IHDR_BYTES})

    # Prefix every scanline with a filter type of 0 (no compression).
    list(LENGTH ARG_DATA DATA_LEN)
    math(EXPR DATA_LEN "${DATA_LEN} - 1")
    math(EXPR SCANLINE_LEN "${ARG_WIDTH} * 3")
    set(FILTERED_DATA)
    foreach(INDEX RANGE 0 ${DATA_LEN} ${SCANLINE_LEN})
        list(SUBLIST ARG_DATA ${INDEX} ${SCANLINE_LEN} SCANLINE_DATA)
        list(APPEND FILTERED_DATA 0 ${SCANLINE_DATA})
    endforeach()

    # zlib encode the image data before writing the IDAT block.
    encode_zlib(OUTPUT IDAT_DATA DATA ${FILTERED_DATA})
    encode_png_block(OUTPUT IDAT_BYTES NAME IDAT DATA ${IDAT_DATA})
    list(APPEND RESULT ${IDAT_BYTES})

    # The final IEND block has no data.
    encode_png_block(OUTPUT IEND_BYTES NAME IEND)
    list(APPEND RESULT ${IEND_BYTES})
    set(${ARG_OUTPUT} ${RESULT} PARENT_SCOPE)
endfunction()

# There's no way to write binary files in CMake, so we use Powershell or Python.
# https://gitlab.kitware.com/cmake/cmake/-/issues/21878
function(write_binary_file)
    cmake_parse_arguments(PARSE_ARGV 0 ARG "" FILENAME DATA)
    string(JOIN "\n" TEXT ${ARG_DATA})
    file(WRITE ${ARG_FILENAME}.temp ${TEXT})
    find_package(Python COMPONENTS Interpreter)
    if(Python_Interpreter_FOUND)
        execute_process(COMMAND ${Python_EXECUTABLE} -c "with open('${ARG_FILENAME}.temp', 'r') as f, open('${ARG_FILENAME}.png', 'wb') as o: [o.write(int(l).to_bytes()) for l in f]"
        RESULT_VARIABLE ret)
    elseif(WIN32)
        execute_process(COMMAND powershell -Command "(Get-Content '${ARG_FILENAME}.temp').ForEach({ [byte] $_ }) | Set-Content '${ARG_FILENAME}.png' -Encoding Byte"
        RESULT_VARIABLE ret)
    else()
        message(FATAL_ERROR "Python or Powershell is required to write PNG files.")
    endif()
    if(NOT ret EQUAL 0)
        message(FATAL_ERROR "Failed to write ${ARG_FILENAME}.png")
    endif()
    file(REMOVE ${ARG_FILENAME}.temp)
endfunction()
