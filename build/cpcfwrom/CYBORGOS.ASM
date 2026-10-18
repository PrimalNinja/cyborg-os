; the window data (; @window ... ; @endwindow in #asm): put in the window hole by its guard
			MACRO ntc_windata
; (the hypervisor's page from #5300 - #4000 the disc buffers, #5000 the font: Install copies
; these into each bank from there, FileCall 99 put them there at the start)
            ds #5300 - $		; Hyp.cls 1782
; page zero (#0000-#0080)
fn_hyp_info_hi_p0:		; Hyp.cls 1784
            db #C3		; Hyp.cls 1785
            dw fn_hyp_info_sb_bwb                           ; #0000: warm boot - the BIOS's WBOOT (the task [1786]
            db 0, 0                             ; ends); (#0001) - 3: the BIOS jump table [1787]
            db #C3		; Hyp.cls 1788
            dw fn_hyp_info_sb_start                         ; #0005: BDOS (#0006: the top of the TPA) [1789]
            ds #38 - 8		; Hyp.cls 1790
            db #C3		; Hyp.cls 1791
            dw fn_hyp_info_sb_int                           ; #0038: the interrupt [1792]
            ds #44 - #3B		; Hyp.cls 1793
            db #ED, #49                         ; #0044: out (c), c [1794]
            db #C3		; Hyp.cls 1795
            dw fn_hyp_info_sb_land                          ; #0046: this bank switched in [1796]
            ds #5C - #49		; Hyp.cls 1797
            db 0, "           "                 ; #005C: the default FCB [1798]
            ds #80 - #68		; Hyp.cls 1799
            db 0                                ; #0080: no command tail [1800]
fn_hyp_info_hi_p0e:		; Hyp.cls 1801
; the stubs: assembled here, run at STUB in the bank (DISP: their labels are the bank's
; addresses). The BDOS: what needs nothing of the hypervisor is answered here, with no
; switch - the console out (2, 9: collected at OBUF; the hypervisor gets them, IX = how many, at
; the next far call or interrupt, or when 128 wait), the keys (1, 6, 10, 11: from KEY, where
; the hypervisor leaves the slot's next key), the IOBYTE (7, 8), the disc's parameters (27, 31)
; and the calls with nothing to do (3, 4, 5, 28, 29, 30, 37 - 30 with #C0 on at DE is CyborgOS's
; UniDOS call), CP/M 3's 49 for the console's size (MODE); the rest is a far call. Then the
; BIOS (its jump table: (#0001) - 3) and the start-up (the default FCBs)
fn_hyp_info_sb_img:		; Hyp.cls 1810
            DISP 61184		; Hyp.cls 1811
fn_hyp_info_sb_start:		; Hyp.cls 1812
            di                                  ; BDOS: C = function, DE = argument [1813]
            ld a, c		; Hyp.cls 1814
            cp 2		; Hyp.cls 1815
            jp z, fn_hyp_info_sb_put		; Hyp.cls 1816
            cp 6		; Hyp.cls 1817
            jr z, fn_hyp_info_sb_f6		; Hyp.cls 1818
            cp 11		; Hyp.cls 1819
            jr z, fn_hyp_info_sb_stat		; Hyp.cls 1820
            cp 1		; Hyp.cls 1821
            jr z, fn_hyp_info_sb_f1		; Hyp.cls 1822
            cp 9		; Hyp.cls 1823
            jp z, fn_hyp_info_sb_str		; Hyp.cls 1824
            cp 10		; Hyp.cls 1825
            jp z, fn_hyp_info_sb_line		; Hyp.cls 1826
            cp 3		; Hyp.cls 1827
            jr z, fn_hyp_info_sb_rdr		; Hyp.cls 1828
            cp 7		; Hyp.cls 1829
            jr z, fn_hyp_info_sb_iob		; Hyp.cls 1830
            cp 8		; Hyp.cls 1831
            jr z, fn_hyp_info_sb_siob		; Hyp.cls 1832
            cp 27		; Hyp.cls 1833
            jr z, fn_hyp_info_sb_alv		; Hyp.cls 1834
            cp 31		; Hyp.cls 1835
            jr z, fn_hyp_info_sb_dpb		; Hyp.cls 1836
            cp 4		; Hyp.cls 1837
            jr z, fn_hyp_info_sb_zero		; Hyp.cls 1838
            cp 5		; Hyp.cls 1839
            jr z, fn_hyp_info_sb_zero		; Hyp.cls 1840
            cp 28		; Hyp.cls 1841
            jr z, fn_hyp_info_sb_zero		; Hyp.cls 1842
            cp 29		; Hyp.cls 1843
            jr z, fn_hyp_info_sb_zero		; Hyp.cls 1844
            cp 30		; Hyp.cls 1845
            jr z, fn_hyp_info_sb_f30		; Hyp.cls 1846
            cp 37		; Hyp.cls 1847
            jr z, fn_hyp_info_sb_zero		; Hyp.cls 1848
            cp 49		; Hyp.cls 1849
            jp z, fn_hyp_info_sb_scb		; Hyp.cls 1850
            jp fn_hyp_info_sb_call		; Hyp.cls 1851
fn_hyp_info_sb_f30:                                         ; 30: nothing - unless #C0 on at DE: CyborgOS's [1852]
            ld a, (de)                          ; UniDOS call (CD, DIR: the hypervisor's) [1853]
            cp #C0		; Hyp.cls 1854
            jp nc, fn_hyp_info_sb_call		; Hyp.cls 1855
fn_hyp_info_sb_zero:		; Hyp.cls 1856
            xor a                               ; 4, 5 (the printer: not yet), 28, 29, 30, 37 [1857]
fn_hyp_info_sb_ret:		; Hyp.cls 1858
            ld l, a		; Hyp.cls 1859
            ld h, 0		; Hyp.cls 1860
            ei		; Hyp.cls 1861
            ret		; Hyp.cls 1862
fn_hyp_info_sb_rdr:		; Hyp.cls 1863
            ld a, #1A                           ; 3: the reader - the end of a file [1864]
            jr fn_hyp_info_sb_ret		; Hyp.cls 1865
fn_hyp_info_sb_iob:		; Hyp.cls 1866
            ld a, (#0003)                       ; 7: the IOBYTE [1867]
            jr fn_hyp_info_sb_ret		; Hyp.cls 1868
fn_hyp_info_sb_siob:		; Hyp.cls 1869
            ld a, e                             ; 8 [1870]
            ld (#0003), a		; Hyp.cls 1871
            jr fn_hyp_info_sb_zero		; Hyp.cls 1872
fn_hyp_info_sb_alv:		; Hyp.cls 1873
            ld hl, fn_hyp_info_sb_alvec                     ; 27: the allocation vector (a CPC data disc's) [1874]
            ei		; Hyp.cls 1875
            ret		; Hyp.cls 1876
fn_hyp_info_sb_dpb:		; Hyp.cls 1877
            ld hl, fn_hyp_info_sb_dpbv                      ; 31: the disc parameter block [1878]
            ei		; Hyp.cls 1879
            ret		; Hyp.cls 1880
fn_hyp_info_sb_f6:		; Hyp.cls 1881
            ld a, e		; Hyp.cls 1882
            cp #FF		; Hyp.cls 1883
            jr z, fn_hyp_info_sb_get		; Hyp.cls 1884
            cp #FE		; Hyp.cls 1885
            jr c, fn_hyp_info_sb_put		; Hyp.cls 1886
fn_hyp_info_sb_stat:		; Hyp.cls 1887
            ld a, (63105)                       ; 6 / #FE, 11: is a key waiting (#FF / 0) [1888]
            or a		; Hyp.cls 1889
            jr z, fn_hyp_info_sb_ret		; Hyp.cls 1890
            ld a, #FF		; Hyp.cls 1891
            jr fn_hyp_info_sb_ret		; Hyp.cls 1892
fn_hyp_info_sb_get:		; Hyp.cls 1893
            ld hl, 63105                        ; 6 / #FF: the key or 0 (no wait) [1894]
            ld a, (hl)		; Hyp.cls 1895
            ld (hl), 0		; Hyp.cls 1896
            jr fn_hyp_info_sb_ret		; Hyp.cls 1897
fn_hyp_info_sb_f1:		; Hyp.cls 1898
            call fn_hyp_info_sb_key                         ; 1: a key (waited for), echoed [1899]
            push af		; Hyp.cls 1900
            ld e, a		; Hyp.cls 1901
            call fn_hyp_info_sb_putc		; Hyp.cls 1902
            pop af		; Hyp.cls 1903
            jr fn_hyp_info_sb_ret		; Hyp.cls 1904
fn_hyp_info_sb_put:		; Hyp.cls 1905
            call fn_hyp_info_sb_putc                        ; 2: E out [1906]
            ei		; Hyp.cls 1907
            ret		; Hyp.cls 1908
fn_hyp_info_sb_str:		; Hyp.cls 1909
            ld h, d                             ; 9: the string at DE, to "$" [1910]
            ld l, e		; Hyp.cls 1911
fn_hyp_info_sb_st_lp:		; Hyp.cls 1912
            ld a, (hl)		; Hyp.cls 1913
            cp '$'		; Hyp.cls 1914
            jr z, fn_hyp_info_sb_zero		; Hyp.cls 1915
            push hl		; Hyp.cls 1916
            ld e, a		; Hyp.cls 1917
            call fn_hyp_info_sb_putc		; Hyp.cls 1918
            pop hl		; Hyp.cls 1919
            inc hl		; Hyp.cls 1920
            jr fn_hyp_info_sb_st_lp		; Hyp.cls 1921
; sb_putc - E collected at OBUF (the hypervisor shown them when 128 wait). Interrupts off
fn_hyp_info_sb_putc:		; Hyp.cls 1923
            ld hl, 62976 + 128                 ; the count [1924]
            ld a, (hl)		; Hyp.cls 1925
            inc (hl)		; Hyp.cls 1926
            ld l, a		; Hyp.cls 1927
            ld h, 62976 / 256		; Hyp.cls 1928
            ld (hl), e		; Hyp.cls 1929
            cp 127		; Hyp.cls 1930
            ret c		; Hyp.cls 1931
            push bc		; Hyp.cls 1932
            push de		; Hyp.cls 1933
            ld c, #80                           ; full: function #80, only the characters [1934]
            call fn_hyp_info_sb_call		; Hyp.cls 1935
            di		; Hyp.cls 1936
            pop de		; Hyp.cls 1937
            pop bc		; Hyp.cls 1938
            ret		; Hyp.cls 1939
; sb_key - A = the next key, waited for: none at KEY - a far call (#81) that has the hypervisor
; run the others until a key comes (or the clock moves on), then look again
fn_hyp_info_sb_key:		; Hyp.cls 1942
            ld hl, 63105		; Hyp.cls 1943
            ld a, (hl)		; Hyp.cls 1944
            or a		; Hyp.cls 1945
            jr z, fn_hyp_info_sb_k_wait		; Hyp.cls 1946
            ld (hl), 0		; Hyp.cls 1947
            ret		; Hyp.cls 1948
fn_hyp_info_sb_k_wait:		; Hyp.cls 1949
            push bc		; Hyp.cls 1950
            push de		; Hyp.cls 1951
            ld c, #81		; Hyp.cls 1952
            call fn_hyp_info_sb_call		; Hyp.cls 1953
            di		; Hyp.cls 1954
            pop de		; Hyp.cls 1955
            pop bc		; Hyp.cls 1956
            jr fn_hyp_info_sb_key		; Hyp.cls 1957
; 10: a line typed into the buffer at DE (its size, then how many came, then them): BS / DEL
; rub out, Control + U / X the whole line, Control + C at its start ends the program, CR / LF
; end it (CR echoed)
fn_hyp_info_sb_line:		; Hyp.cls 1961
            ld (fn_hyp_info_sb_lbuf), de		; Hyp.cls 1962
            xor a		; Hyp.cls 1963
            ld (fn_hyp_info_sb_lcnt), a		; Hyp.cls 1964
fn_hyp_info_sb_l_lp:		; Hyp.cls 1965
            call fn_hyp_info_sb_key		; Hyp.cls 1966
            cp 13		; Hyp.cls 1967
            jr z, fn_hyp_info_sb_l_end		; Hyp.cls 1968
            cp 10		; Hyp.cls 1969
            jr z, fn_hyp_info_sb_l_end		; Hyp.cls 1970
            cp 8		; Hyp.cls 1971
            jr z, fn_hyp_info_sb_l_bs		; Hyp.cls 1972
            cp 127		; Hyp.cls 1973
            jr z, fn_hyp_info_sb_l_bs		; Hyp.cls 1974
            cp 21		; Hyp.cls 1975
            jr z, fn_hyp_info_sb_l_kill		; Hyp.cls 1976
            cp 24		; Hyp.cls 1977
            jr z, fn_hyp_info_sb_l_kill		; Hyp.cls 1978
            cp 3		; Hyp.cls 1979
            jr nz, fn_hyp_info_sb_l_ch		; Hyp.cls 1980
            ld a, (fn_hyp_info_sb_lcnt)		; Hyp.cls 1981
            or a		; Hyp.cls 1982
            jr nz, fn_hyp_info_sb_l_lp		; Hyp.cls 1983
            ld c, 0                             ; Control + C: the program ends [1984]
            jp fn_hyp_info_sb_call		; Hyp.cls 1985
fn_hyp_info_sb_l_ch:		; Hyp.cls 1986
            cp 32		; Hyp.cls 1987
            jr c, fn_hyp_info_sb_l_lp		; Hyp.cls 1988
            ld b, a		; Hyp.cls 1989
            ld hl, (fn_hyp_info_sb_lbuf)		; Hyp.cls 1990
            ld a, (fn_hyp_info_sb_lcnt)		; Hyp.cls 1991
            cp (hl)		; Hyp.cls 1992
            jr nc, fn_hyp_info_sb_l_lp                      ; full [1993]
            inc a		; Hyp.cls 1994
            ld (fn_hyp_info_sb_lcnt), a		; Hyp.cls 1995
            ld e, a		; Hyp.cls 1996
            ld d, 0		; Hyp.cls 1997
            inc hl		; Hyp.cls 1998
            add hl, de		; Hyp.cls 1999
            ld (hl), b		; Hyp.cls 2000
            ld e, b		; Hyp.cls 2001
            call fn_hyp_info_sb_putc		; Hyp.cls 2002
            jr fn_hyp_info_sb_l_lp		; Hyp.cls 2003
fn_hyp_info_sb_l_kill:		; Hyp.cls 2004
            ld a, (fn_hyp_info_sb_lcnt)		; Hyp.cls 2005
            or a		; Hyp.cls 2006
            jr z, fn_hyp_info_sb_l_lp		; Hyp.cls 2007
            call fn_hyp_info_sb_l_rub		; Hyp.cls 2008
            jr fn_hyp_info_sb_l_kill		; Hyp.cls 2009
fn_hyp_info_sb_l_bs:		; Hyp.cls 2010
            ld a, (fn_hyp_info_sb_lcnt)		; Hyp.cls 2011
            or a		; Hyp.cls 2012
            jr z, fn_hyp_info_sb_l_lp		; Hyp.cls 2013
            call fn_hyp_info_sb_l_rub		; Hyp.cls 2014
            jr fn_hyp_info_sb_l_lp		; Hyp.cls 2015
fn_hyp_info_sb_l_rub:		; Hyp.cls 2016
            dec a		; Hyp.cls 2017
            ld (fn_hyp_info_sb_lcnt), a		; Hyp.cls 2018
            ld e, 8		; Hyp.cls 2019
            call fn_hyp_info_sb_putc		; Hyp.cls 2020
            ld e, ' '		; Hyp.cls 2021
            call fn_hyp_info_sb_putc		; Hyp.cls 2022
            ld e, 8		; Hyp.cls 2023
            jp fn_hyp_info_sb_putc		; Hyp.cls 2024
fn_hyp_info_sb_l_end:		; Hyp.cls 2025
            ld hl, (fn_hyp_info_sb_lbuf)		; Hyp.cls 2026
            inc hl		; Hyp.cls 2027
            ld a, (fn_hyp_info_sb_lcnt)		; Hyp.cls 2028
            ld (hl), a		; Hyp.cls 2029
            ld e, 13		; Hyp.cls 2030
            call fn_hyp_info_sb_putc		; Hyp.cls 2031
            jp fn_hyp_info_sb_zero		; Hyp.cls 2032
fn_hyp_info_sb_lbuf:    dw 0		; Hyp.cls 2033
fn_hyp_info_sb_lcnt:    db 0		; Hyp.cls 2034
fn_hyp_info_sb_call:		; Hyp.cls 2035
            push ix                             ; a far call: IX, IY and the alternate [2036]
            push iy                             ; registers kept over it (ex af, af') [2037]
            db #08		; Hyp.cls 2038
            exx		; Hyp.cls 2039
            push af		; Hyp.cls 2040
            push bc		; Hyp.cls 2041
            push de		; Hyp.cls 2042
            push hl		; Hyp.cls 2043
            exx		; Hyp.cls 2044
            db #08		; Hyp.cls 2045
            ld a, (62976 + 128)		; Hyp.cls 2046
            ld ixl, a		; Hyp.cls 2047
            ld ixh, 0		; Hyp.cls 2048
            ld a, c		; Hyp.cls 2049
            ld hl, fn_hyp_info_sb_far		; Hyp.cls 2050
            push hl		; Hyp.cls 2051
            ld (#FFFE), sp		; Hyp.cls 2052
            ld bc, #7FC0		; Hyp.cls 2053
            scf                                 ; carry: a far call [2054]
            jp #0044		; Hyp.cls 2055
fn_hyp_info_sb_far:		; Hyp.cls 2056
            db #08                              ; the answer in A and HL; the program's [2057]
            exx                                 ; other registers back [2058]
            pop hl		; Hyp.cls 2059
            pop de		; Hyp.cls 2060
            pop bc		; Hyp.cls 2061
            pop af		; Hyp.cls 2062
            exx		; Hyp.cls 2063
            db #08		; Hyp.cls 2064
            pop iy		; Hyp.cls 2065
            pop ix		; Hyp.cls 2066
            ei		; Hyp.cls 2067
            ret		; Hyp.cls 2068
fn_hyp_info_sb_int:		; Hyp.cls 2069
            push af                             ; an interrupt: everything kept [2070]
            push bc		; Hyp.cls 2071
            push de		; Hyp.cls 2072
            push hl		; Hyp.cls 2073
            db #08                              ; ex af, af' [2074]
            exx		; Hyp.cls 2075
            push af		; Hyp.cls 2076
            push bc		; Hyp.cls 2077
            push de		; Hyp.cls 2078
            push hl		; Hyp.cls 2079
            push ix		; Hyp.cls 2080
            push iy		; Hyp.cls 2081
            ld a, (62976 + 128)		; Hyp.cls 2082
            ld ixl, a		; Hyp.cls 2083
            ld ixh, 0		; Hyp.cls 2084
            ld hl, fn_hyp_info_sb_rest		; Hyp.cls 2085
            push hl		; Hyp.cls 2086
            ld (#FFFE), sp		; Hyp.cls 2087
            ld bc, #7FC0		; Hyp.cls 2088
            or a                                ; no carry: an interrupt [2089]
            jp #0044		; Hyp.cls 2090
fn_hyp_info_sb_rest:		; Hyp.cls 2091
            pop iy		; Hyp.cls 2092
            pop ix		; Hyp.cls 2093
            pop hl		; Hyp.cls 2094
            pop de		; Hyp.cls 2095
            pop bc		; Hyp.cls 2096
            pop af		; Hyp.cls 2097
            exx		; Hyp.cls 2098
            db #08                              ; ex af, af' [2099]
            pop hl		; Hyp.cls 2100
            pop de		; Hyp.cls 2101
            pop bc		; Hyp.cls 2102
            pop af		; Hyp.cls 2103
            ei		; Hyp.cls 2104
            ret		; Hyp.cls 2105
fn_hyp_info_sb_land:		; Hyp.cls 2106
            ld sp, (#FFFE)                      ; this bank's SP [2107]
            push af		; Hyp.cls 2108
            ld a, e                             ; E = 1: the hypervisor has the characters [2109]
            or a		; Hyp.cls 2110
            jr z, fn_hyp_info_sb_lkeep		; Hyp.cls 2111
            xor a		; Hyp.cls 2112
            ld (62976 + 128), a		; Hyp.cls 2113
fn_hyp_info_sb_lkeep:		; Hyp.cls 2114
            pop af		; Hyp.cls 2115
            ret		; Hyp.cls 2116
fn_hyp_info_sb_scb:		; Hyp.cls 2117
            ld h, d                             ; 49 (CP/M 3's system control block): the [2118]
            ld l, e                             ; console's width - 1 (#1A), its page length [2119]
            inc hl                              ; (#1C) - MODE's; other bytes 0, sets kept [2120]
            ld a, (hl)                          ; nowhere [2121]
            or a		; Hyp.cls 2122
            jp nz, fn_hyp_info_sb_zero		; Hyp.cls 2123
            ld a, (de)		; Hyp.cls 2124
            cp #1C		; Hyp.cls 2125
            ld hl, 63112		; Hyp.cls 2126
            jr z, fn_hyp_info_sb_scb_a		; Hyp.cls 2127
            cp #1A		; Hyp.cls 2128
            jp nz, fn_hyp_info_sb_zero		; Hyp.cls 2129
            ld a, (63111)		; Hyp.cls 2130
            dec a		; Hyp.cls 2131
            jp fn_hyp_info_sb_ret		; Hyp.cls 2132
fn_hyp_info_sb_scb_a:		; Hyp.cls 2133
            ld a, (hl)		; Hyp.cls 2134
            jp fn_hyp_info_sb_ret		; Hyp.cls 2135
; the BIOS: CP/M 2.2's 17 entries. The console ones as the BDOS's; the printer and punch take
; nothing yet; the disc ones (sectors) can't be had here: SELDSK gives 0 (no such drive),
; READ / WRITE 1 (an error)
fn_hyp_info_sb_bios:		; Hyp.cls 2139
            jp fn_hyp_info_sb_bboot                         ; BOOT [2140]
fn_hyp_info_sb_bwb:		; Hyp.cls 2141
            jp fn_hyp_info_sb_bboot                         ; WBOOT: (#0001) [2142]
            jp fn_hyp_info_sb_bconst                        ; CONST [2143]
            jp fn_hyp_info_sb_bconin                        ; CONIN [2144]
            jp fn_hyp_info_sb_bconout                       ; CONOUT [2145]
            jp fn_hyp_info_sb_bnone                         ; LIST [2146]
            jp fn_hyp_info_sb_bnone                         ; PUNCH [2147]
            jp fn_hyp_info_sb_brdr                          ; READER [2148]
            jp fn_hyp_info_sb_bnone                         ; HOME [2149]
            jp fn_hyp_info_sb_bseld                         ; SELDSK [2150]
            jp fn_hyp_info_sb_bnone                         ; SETTRK [2151]
            jp fn_hyp_info_sb_bnone                         ; SETSEC [2152]
            jp fn_hyp_info_sb_bdma                          ; SETDMA [2153]
            jp fn_hyp_info_sb_bfail                         ; READ [2154]
            jp fn_hyp_info_sb_bfail                         ; WRITE [2155]
            jp fn_hyp_info_sb_blstst                        ; LISTST [2156]
            jp fn_hyp_info_sb_bsectr                        ; SECTRAN [2157]
fn_hyp_info_sb_bboot:		; Hyp.cls 2158
            ld c, 0                             ; the task ends [2159]
            jp fn_hyp_info_sb_start		; Hyp.cls 2160
fn_hyp_info_sb_bconst:		; Hyp.cls 2161
            di		; Hyp.cls 2162
            ld a, (63105)		; Hyp.cls 2163
            or a		; Hyp.cls 2164
            jr z, fn_hyp_info_sb_bc_n		; Hyp.cls 2165
            ld a, #FF		; Hyp.cls 2166
fn_hyp_info_sb_bc_n:		; Hyp.cls 2167
            ei		; Hyp.cls 2168
            ret		; Hyp.cls 2169
fn_hyp_info_sb_bconin:		; Hyp.cls 2170
            di		; Hyp.cls 2171
            call fn_hyp_info_sb_key		; Hyp.cls 2172
            ei		; Hyp.cls 2173
            ret		; Hyp.cls 2174
fn_hyp_info_sb_bconout:		; Hyp.cls 2175
            di		; Hyp.cls 2176
            ld e, c		; Hyp.cls 2177
            call fn_hyp_info_sb_putc		; Hyp.cls 2178
            ei		; Hyp.cls 2179
fn_hyp_info_sb_bnone:		; Hyp.cls 2180
            ret		; Hyp.cls 2181
fn_hyp_info_sb_brdr:		; Hyp.cls 2182
            ld a, #1A		; Hyp.cls 2183
            ret		; Hyp.cls 2184
fn_hyp_info_sb_bseld:		; Hyp.cls 2185
            ld hl, 0		; Hyp.cls 2186
            ret		; Hyp.cls 2187
fn_hyp_info_sb_bdma:		; Hyp.cls 2188
            ld d, b		; Hyp.cls 2189
            ld e, c		; Hyp.cls 2190
            ld c, 26		; Hyp.cls 2191
            jp fn_hyp_info_sb_start		; Hyp.cls 2192
fn_hyp_info_sb_bfail:		; Hyp.cls 2193
            ld a, 1		; Hyp.cls 2194
            ret		; Hyp.cls 2195
fn_hyp_info_sb_blstst:		; Hyp.cls 2196
            ld a, #FF		; Hyp.cls 2197
            ret		; Hyp.cls 2198
fn_hyp_info_sb_bsectr:		; Hyp.cls 2199
            ld h, b		; Hyp.cls 2200
            ld l, c		; Hyp.cls 2201
            ret		; Hyp.cls 2202
; a CPC data format disc's parameters (31) and allocation vector (27): 180 1K blocks, 64
; directory entries in the first two
fn_hyp_info_sb_dpbv:		; Hyp.cls 2205
            dw 36                               ; SPT: 128 byte records a track [2206]
            db 3, 7, 0                          ; BSH, BLM, EXM [2207]
            dw 179, 63                          ; DSM, DRM [2208]
            db #C0, 0                           ; AL0, AL1 [2209]
            dw 16, 0                            ; CKS, OFF [2210]
fn_hyp_info_sb_alvec:		; Hyp.cls 2211
            db #C0		; Hyp.cls 2212
            ds 22		; Hyp.cls 2213
; the start-up: the default FCBs (#005C, #006C) from the command tail (#0080), as the CCP
; makes them - "B:NAME.EXT", * as ?s - then the program at #0100
fn_hyp_info_sb_init:		; Hyp.cls 2216
            ld hl, #005C		; Hyp.cls 2217
            call fn_hyp_info_sb_iclr		; Hyp.cls 2218
            ld hl, #006C		; Hyp.cls 2219
            call fn_hyp_info_sb_iclr		; Hyp.cls 2220
            ld hl, #0081		; Hyp.cls 2221
            ld a, (#0080)		; Hyp.cls 2222
            ld b, a		; Hyp.cls 2223
            ld de, #005C		; Hyp.cls 2224
            call fn_hyp_info_sb_parse		; Hyp.cls 2225
            ld de, #006C		; Hyp.cls 2226
            call fn_hyp_info_sb_parse		; Hyp.cls 2227
            jp #0100		; Hyp.cls 2228
fn_hyp_info_sb_iclr:		; Hyp.cls 2229
            ld (hl), 0		; Hyp.cls 2230
            inc hl		; Hyp.cls 2231
            ld c, 11		; Hyp.cls 2232
fn_hyp_info_sb_ic_sp:		; Hyp.cls 2233
            ld (hl), ' '		; Hyp.cls 2234
            inc hl		; Hyp.cls 2235
            dec c		; Hyp.cls 2236
            jr nz, fn_hyp_info_sb_ic_sp		; Hyp.cls 2237
            ld c, 4		; Hyp.cls 2238
fn_hyp_info_sb_ic_z:		; Hyp.cls 2239
            ld (hl), 0		; Hyp.cls 2240
            inc hl		; Hyp.cls 2241
            dec c		; Hyp.cls 2242
            jr nz, fn_hyp_info_sb_ic_z		; Hyp.cls 2243
            ret		; Hyp.cls 2244
; sb_parse - HL = the tail, B = characters left; DE = an FCB: the next word into it
fn_hyp_info_sb_parse:		; Hyp.cls 2246
            ld a, b		; Hyp.cls 2247
            or a		; Hyp.cls 2248
            ret z		; Hyp.cls 2249
            ld a, (hl)		; Hyp.cls 2250
            cp ' '		; Hyp.cls 2251
            jr nz, fn_hyp_info_sb_p_word		; Hyp.cls 2252
            inc hl		; Hyp.cls 2253
            dec b		; Hyp.cls 2254
            jr fn_hyp_info_sb_parse		; Hyp.cls 2255
fn_hyp_info_sb_p_word:		; Hyp.cls 2256
            ld (fn_hyp_info_sb_pfcb), de		; Hyp.cls 2257
            ld a, b		; Hyp.cls 2258
            cp 2		; Hyp.cls 2259
            jr c, fn_hyp_info_sb_p_name		; Hyp.cls 2260
            inc hl		; Hyp.cls 2261
            ld a, (hl)		; Hyp.cls 2262
            dec hl		; Hyp.cls 2263
            cp ':'		; Hyp.cls 2264
            jr nz, fn_hyp_info_sb_p_name		; Hyp.cls 2265
            ld a, (hl)		; Hyp.cls 2266
            sub '@'		; Hyp.cls 2267
            ld (de), a                          ; its drive [2268]
            inc hl		; Hyp.cls 2269
            inc hl		; Hyp.cls 2270
            dec b		; Hyp.cls 2271
            dec b		; Hyp.cls 2272
fn_hyp_info_sb_p_name:		; Hyp.cls 2273
            inc de		; Hyp.cls 2274
            ld c, 8		; Hyp.cls 2275
            call fn_hyp_info_sb_pfield		; Hyp.cls 2276
            ld a, b		; Hyp.cls 2277
            or a		; Hyp.cls 2278
            ret z		; Hyp.cls 2279
            ld a, (hl)		; Hyp.cls 2280
            cp '.'		; Hyp.cls 2281
            jr nz, fn_hyp_info_sb_p_skip		; Hyp.cls 2282
            inc hl		; Hyp.cls 2283
            dec b		; Hyp.cls 2284
            ld de, (fn_hyp_info_sb_pfcb)		; Hyp.cls 2285
            ld a, e		; Hyp.cls 2286
            add a, 9		; Hyp.cls 2287
            ld e, a		; Hyp.cls 2288
            ld c, 3		; Hyp.cls 2289
            call fn_hyp_info_sb_pfield		; Hyp.cls 2290
fn_hyp_info_sb_p_skip:		; Hyp.cls 2291
            ld a, b                             ; the rest of the word [2292]
            or a		; Hyp.cls 2293
            ret z		; Hyp.cls 2294
            ld a, (hl)		; Hyp.cls 2295
            cp ' '		; Hyp.cls 2296
            ret z		; Hyp.cls 2297
            inc hl		; Hyp.cls 2298
            dec b		; Hyp.cls 2299
            jr fn_hyp_info_sb_p_skip		; Hyp.cls 2300
; sb_pfield - up to C characters into the field at DE, to a "." or a space; * fills it with ?
fn_hyp_info_sb_pfield:		; Hyp.cls 2302
            ld a, b		; Hyp.cls 2303
            or a		; Hyp.cls 2304
            ret z		; Hyp.cls 2305
            ld a, (hl)		; Hyp.cls 2306
            cp ' '		; Hyp.cls 2307
            ret z		; Hyp.cls 2308
            cp '.'		; Hyp.cls 2309
            ret z		; Hyp.cls 2310
            cp '*'		; Hyp.cls 2311
            jr z, fn_hyp_info_sb_pf_star		; Hyp.cls 2312
            inc c		; Hyp.cls 2313
            dec c		; Hyp.cls 2314
            jr z, fn_hyp_info_sb_pf_on                      ; (the field full: the extra left out) [2315]
            ld (de), a		; Hyp.cls 2316
            inc de		; Hyp.cls 2317
            dec c		; Hyp.cls 2318
fn_hyp_info_sb_pf_on:		; Hyp.cls 2319
            inc hl		; Hyp.cls 2320
            dec b		; Hyp.cls 2321
            jr fn_hyp_info_sb_pfield		; Hyp.cls 2322
fn_hyp_info_sb_pf_star:		; Hyp.cls 2323
            inc c		; Hyp.cls 2324
            dec c		; Hyp.cls 2325
            jr z, fn_hyp_info_sb_pf_on		; Hyp.cls 2326
            ld a, '?'		; Hyp.cls 2327
            ld (de), a		; Hyp.cls 2328
            inc de		; Hyp.cls 2329
            dec c		; Hyp.cls 2330
            jr fn_hyp_info_sb_pf_star		; Hyp.cls 2331
fn_hyp_info_sb_pfcb:    dw 0		; Hyp.cls 2332
fn_hyp_info_sb_end:		; Hyp.cls 2333
            ENT		; Hyp.cls 2334
            ASSERT fn_hyp_info_sb_end - fn_hyp_info_sb_start <= 62208 - 61184, "the bank stubs must fit below FONT"		; Hyp.cls 2335
            ASSERT fn_hyp_info_sb_end - fn_hyp_info_sb_start <= #340, "the stubs must leave a program's first stack (#F240-#F2FF) free"		; Hyp.cls 2336
; ---- the page code: in the hypervisor's page (window data), called with it in the window
asm_1_2379_n_fp_start:		; Hyp.cls 2636
            ASSERT asm_1_2379_n_fp_start >= #5300, "FileCall's page code: after the disc buffers and the font"		; Hyp.cls 2637
asm_1_2379_n_fp_go:		; Hyp.cls 2638
            ld (asm_1_2379_n_fp_sp), sp		; Hyp.cls 2639
            ld a, (var_hyp_filecall_f)		; Hyp.cls 2640
            cp 15		; Hyp.cls 2641
            jp z, asm_1_2379_n_fl_open		; Hyp.cls 2642
            cp 16		; Hyp.cls 2643
            jp z, asm_1_2379_n_fl_close		; Hyp.cls 2644
            cp 19		; Hyp.cls 2645
            jp z, asm_1_2379_n_fl_del		; Hyp.cls 2646
            cp 23		; Hyp.cls 2647
            jp z, asm_1_2379_n_fl_ren		; Hyp.cls 2648
            cp 20		; Hyp.cls 2649
            jp z, asm_1_2379_n_fl_rdseq		; Hyp.cls 2650
            cp 33		; Hyp.cls 2651
            jp z, asm_1_2379_n_fl_rdran		; Hyp.cls 2652
            cp 21		; Hyp.cls 2653
            jp z, asm_1_2379_n_fl_write		; Hyp.cls 2654
            cp 34		; Hyp.cls 2655
            jp z, asm_1_2379_n_fl_write		; Hyp.cls 2656
            cp 22		; Hyp.cls 2657
            jp z, asm_1_2379_n_fl_make		; Hyp.cls 2658
            cp 17		; Hyp.cls 2659
            jp z, asm_1_2379_n_fl_srch1		; Hyp.cls 2660
            cp 18		; Hyp.cls 2661
            jp z, asm_1_2379_n_fl_srch		; Hyp.cls 2662
            cp 35		; Hyp.cls 2663
            jp z, asm_1_2379_n_fl_size		; Hyp.cls 2664
            cp 36		; Hyp.cls 2665
            jp z, asm_1_2379_n_fl_setran		; Hyp.cls 2666
            cp 100		; Hyp.cls 2667
            jp z, asm_1_2379_n_fl_hopen		; Hyp.cls 2668
            cp 101		; Hyp.cls 2669
            jp z, asm_1_2379_n_fl_hread		; Hyp.cls 2670
            cp 102		; Hyp.cls 2671
            jp z, asm_1_2379_n_fl_hclose		; Hyp.cls 2672
            cp 103		; Hyp.cls 2673
            jp z, asm_1_2379_n_fl_hload		; Hyp.cls 2674
            cp 30		; Hyp.cls 2675
            jp z, asm_1_2379_n_fl_unicall		; Hyp.cls 2676
            jp asm_1_2379_n_fp_done		; Hyp.cls 2677
; ---- the hypervisor's own reading (RUN, DIR, CD): 100 open the file named at fcb (dma
; characters, main RAM); 101 read dma bytes (128 at most) to buf: how many; 102 close; 103 the
; rest of it into the slot (setting) from address dma, fcb bytes at most: how many. Not while
; a slot reads a file (255)
asm_1_2379_n_fl_hopen:		; Hyp.cls 2682
            ld a, (var_hyp_fin)		; Hyp.cls 2683
            or a		; Hyp.cls 2684
            jp nz, asm_1_2379_n_fp_done		; Hyp.cls 2685
            ld de, asm_1_2379_n_fl_name_s + 1		; Hyp.cls 2686
            ld hl, (var_hyp_filecall_fcb)          ; a name with no drive: the hypervisor's drive's path first [2687]
            ld bc, (var_hyp_filecall_dma)          ; when it has one (UniDOS: CD IDE: ...) [2688]
            ld a, ':'		; Hyp.cls 2689
            cpir		; Hyp.cls 2690
            jr z, asm_1_2379_n_fl_ho_nm		; Hyp.cls 2691
            ld a, (var_hyp_hdr)		; Hyp.cls 2692
            call asm_1_2379_n_fl_pfxm		; Hyp.cls 2693
asm_1_2379_n_fl_ho_nm:		; Hyp.cls 2694
            ld hl, (var_hyp_filecall_fcb)		; Hyp.cls 2695
            ld bc, (var_hyp_filecall_dma)		; Hyp.cls 2696
            ldir		; Hyp.cls 2697
            call asm_1_2379_n_fl_nlen		; Hyp.cls 2698
            call asm_1_2379_n_fl_inopen		; Hyp.cls 2699
            jr c, asm_1_2379_n_fl_ho_ok		; Hyp.cls 2700
            ld hl, asm_1_2379_n_fl_name_s        ; NAME.CYB not there: with UniDOS NAME.COM instead (RUN - a [2701]
            ld e, (hl)              ; .COM with no entry: UniDOS reads a file with no header to [2702]
            ld d, 0                 ; its real end) [2703]
            add hl, de		; Hyp.cls 2704
            ld a, (hl)		; Hyp.cls 2705
            cp 'B'		; Hyp.cls 2706
            jp nz, asm_1_2379_n_fp_done		; Hyp.cls 2707
            ld (hl), 'M'		; Hyp.cls 2708
            dec hl		; Hyp.cls 2709
            ld a, (hl)		; Hyp.cls 2710
            cp 'Y'		; Hyp.cls 2711
            jp nz, asm_1_2379_n_fp_done		; Hyp.cls 2712
            ld (hl), 'O'		; Hyp.cls 2713
            call asm_1_2379_n_fl_uni		; Hyp.cls 2714
            jp nc, asm_1_2379_n_fp_done		; Hyp.cls 2715
            call asm_1_2379_n_fl_inopen		; Hyp.cls 2716
            jp nc, asm_1_2379_n_fp_done		; Hyp.cls 2717
            ld hl, (var_hyp_filecall_fcb)          ; (the caller's name too: NAME.COM) [2718]
            ld bc, (var_hyp_filecall_dma)		; Hyp.cls 2719
            add hl, bc		; Hyp.cls 2720
            dec hl		; Hyp.cls 2721
            ld (hl), 'M'		; Hyp.cls 2722
            dec hl		; Hyp.cls 2723
            ld (hl), 'O'		; Hyp.cls 2724
asm_1_2379_n_fl_ho_ok:		; Hyp.cls 2725
            ld a, 99                ; (99: the hypervisor's) [2726]
            ld (var_hyp_fin), a		; Hyp.cls 2727
            jp asm_1_2379_n_fl_ok		; Hyp.cls 2728
asm_1_2379_n_fl_hread:		; Hyp.cls 2729
            ld a, (var_hyp_filecall_dma)		; Hyp.cls 2730
            ld (asm_1_2379_n_fl_n), a		; Hyp.cls 2731
            call asm_1_2379_n_fl_rdrec		; Hyp.cls 2732
            ld (asm_1_2379_n_fl_res), a		; Hyp.cls 2733
            jp asm_1_2379_n_fp_done		; Hyp.cls 2734
asm_1_2379_n_fl_hclose:		; Hyp.cls 2735
            ld a, (var_hyp_fin)		; Hyp.cls 2736
            cp 99		; Hyp.cls 2737
            jp nz, asm_1_2379_n_fp_done		; Hyp.cls 2738
            call asm_1_2379_n_fl_inclose		; Hyp.cls 2739
            jp asm_1_2379_n_fl_ok		; Hyp.cls 2740
asm_1_2379_n_fl_hload:		; Hyp.cls 2741
            ld hl, 0		; Hyp.cls 2742
            ld (asm_1_2379_n_fl_cnt), hl		; Hyp.cls 2743
            ld hl, (var_hyp_filecall_dma)		; Hyp.cls 2744
            ld (asm_1_2379_n_fl_at), hl		; Hyp.cls 2745
asm_1_2379_n_fl_hl_lp:		; Hyp.cls 2746
            ld hl, (var_hyp_filecall_fcb)          ; what is left to load (fcb bytes at most) [2747]
            ld de, (asm_1_2379_n_fl_cnt)		; Hyp.cls 2748
            or a		; Hyp.cls 2749
            sbc hl, de		; Hyp.cls 2750
            jr z, asm_1_2379_n_fl_hl_end		; Hyp.cls 2751
            ld a, h		; Hyp.cls 2752
            or a		; Hyp.cls 2753
            ld a, 128		; Hyp.cls 2754
            jr nz, asm_1_2379_n_fl_hl_n		; Hyp.cls 2755
            ld a, l		; Hyp.cls 2756
            cp 128		; Hyp.cls 2757
            jr c, asm_1_2379_n_fl_hl_n		; Hyp.cls 2758
            ld a, 128		; Hyp.cls 2759
asm_1_2379_n_fl_hl_n:		; Hyp.cls 2760
            ld (asm_1_2379_n_fl_n), a		; Hyp.cls 2761
            ld (asm_1_2379_n_fl_want), a		; Hyp.cls 2762
            call asm_1_2379_n_fl_rdrec           ; a record's worth into buf [2763]
            jr z, asm_1_2379_n_fl_hl_end		; Hyp.cls 2764
            ld b, a		; Hyp.cls 2765
            ld (asm_1_2379_n_fl_want + 1), a		; Hyp.cls 2766
            ld hl, (asm_1_2379_n_fl_cnt)		; Hyp.cls 2767
            ld e, a		; Hyp.cls 2768
            ld d, 0		; Hyp.cls 2769
            add hl, de		; Hyp.cls 2770
            ld (asm_1_2379_n_fl_cnt), hl		; Hyp.cls 2771
            ld hl, (asm_1_2379_n_fl_at)		; Hyp.cls 2772
            ld c, b		; Hyp.cls 2773
            ld b, 0		; Hyp.cls 2774
            call asm_1_2379_n_fl_fits		; Hyp.cls 2775
            jr c, asm_1_2379_n_fl_hl_slow		; Hyp.cls 2776
            push bc		; Hyp.cls 2777
            ld de, (var_hyp_filecall_buf)          ; in one page: one ldir [2778]
            call asm_1_2379_n_fl_toslot		; Hyp.cls 2779
            pop bc		; Hyp.cls 2780
            ld hl, (asm_1_2379_n_fl_at)		; Hyp.cls 2781
            add hl, bc		; Hyp.cls 2782
            jr asm_1_2379_n_fl_hl_put		; Hyp.cls 2783
asm_1_2379_n_fl_hl_slow:		; Hyp.cls 2784
            ld b, c		; Hyp.cls 2785
            ld de, (var_hyp_filecall_buf)		; Hyp.cls 2786
asm_1_2379_n_fl_hl_cp:		; Hyp.cls 2787
            ld a, (de)              ; into the slot [2788]
            call asm_1_2379_n_fl_poke		; Hyp.cls 2789
            inc hl		; Hyp.cls 2790
            inc de		; Hyp.cls 2791
            djnz asm_1_2379_n_fl_hl_cp		; Hyp.cls 2792
asm_1_2379_n_fl_hl_put:		; Hyp.cls 2793
            ld (asm_1_2379_n_fl_at), hl		; Hyp.cls 2794
            ld a, (asm_1_2379_n_fl_want)		; Hyp.cls 2795
            ld b, a		; Hyp.cls 2796
            ld a, (asm_1_2379_n_fl_want + 1)		; Hyp.cls 2797
            cp b		; Hyp.cls 2798
            jr z, asm_1_2379_n_fl_hl_lp          ; a whole one: on [2799]
asm_1_2379_n_fl_hl_end:		; Hyp.cls 2800
            ld hl, (asm_1_2379_n_fl_cnt)		; Hyp.cls 2801
            ld (asm_1_2379_n_fl_res16), hl		; Hyp.cls 2802
            ld a, 1		; Hyp.cls 2803
            ld (asm_1_2379_n_fl_r16), a		; Hyp.cls 2804
            jp asm_1_2379_n_fp_done		; Hyp.cls 2805
; ---- 15: open (to read)
asm_1_2379_n_fl_open:		; Hyp.cls 2807
            ld a, (var_hyp_fin)		; Hyp.cls 2808
            or a		; Hyp.cls 2809
            jr z, asm_1_2379_n_fl_op_new		; Hyp.cls 2810
            ld b, a		; Hyp.cls 2811
            ld a, (asm_1_2379_n_fl_slot)		; Hyp.cls 2812
            cp b		; Hyp.cls 2813
            jp nz, asm_1_2379_n_fp_done          ; another slot's being read [2814]
            call asm_1_2379_n_fl_inclose         ; this slot's: CP/M needs no close after reading - this open [2815]
asm_1_2379_n_fl_op_new:                          ; replaces it (Exists opens and leaves it) [2816]
            call asm_1_2379_n_fl_name		; Hyp.cls 2817
            call asm_1_2379_n_fl_inopen		; Hyp.cls 2818
            jp nc, asm_1_2379_n_fp_done		; Hyp.cls 2819
            ld hl, asm_1_2379_n_fl_name_s        ; kept, to open it again (33 going back) [2820]
            ld de, asm_1_2379_n_fl_inname		; Hyp.cls 2821
            ld bc, asm_1_2379_n_FL_NL		; Hyp.cls 2822
            ldir		; Hyp.cls 2823
            ld a, (asm_1_2379_n_fl_slot)		; Hyp.cls 2824
            ld (var_hyp_fin), a		; Hyp.cls 2825
            ld hl, (var_hyp_filecall_fcb)		; Hyp.cls 2826
            ld (asm_1_2379_n_fl_infcb), hl		; Hyp.cls 2827
            ld a, 1		; Hyp.cls 2828
            ld (asm_1_2379_n_fl_infcb + 2), a		; Hyp.cls 2829
            ld hl, 0		; Hyp.cls 2830
            ld (asm_1_2379_n_fl_inrec), hl		; Hyp.cls 2831
            jp asm_1_2379_n_fl_ok		; Hyp.cls 2832
; ---- 22: make (a new file, to write)
asm_1_2379_n_fl_make:		; Hyp.cls 2834
            ld a, (var_hyp_fout)		; Hyp.cls 2835
            or a		; Hyp.cls 2836
            jp nz, asm_1_2379_n_fp_done		; Hyp.cls 2837
            call asm_1_2379_n_fl_name		; Hyp.cls 2838
            call asm_1_2379_n_fl_plain		; Hyp.cls 2839
            ld hl, asm_1_2379_n_fl_name_s + 1		; Hyp.cls 2840
            ld a, (asm_1_2379_n_fl_name_s)		; Hyp.cls 2841
            ld b, a		; Hyp.cls 2842
            ld de, #4800		; Hyp.cls 2843
            call #BC8C              ; CAS OUT OPEN [2844]
            di		; Hyp.cls 2845
            jp nc, asm_1_2379_n_fp_done		; Hyp.cls 2846
            ld a, (asm_1_2379_n_fl_slot)		; Hyp.cls 2847
            ld (var_hyp_fout), a		; Hyp.cls 2848
            ld hl, (var_hyp_filecall_fcb)		; Hyp.cls 2849
            ld (asm_1_2379_n_fl_outfcb), hl		; Hyp.cls 2850
            ld a, 1		; Hyp.cls 2851
            ld (asm_1_2379_n_fl_outfcb + 2), a		; Hyp.cls 2852
            ld hl, 0		; Hyp.cls 2853
            ld (asm_1_2379_n_fl_outrec), hl		; Hyp.cls 2854
            jp asm_1_2379_n_fl_ok		; Hyp.cls 2855
; ---- 16: close
asm_1_2379_n_fl_close:		; Hyp.cls 2857
            call asm_1_2379_n_fl_isin		; Hyp.cls 2858
            jr nz, asm_1_2379_n_fl_cl_out		; Hyp.cls 2859
            call asm_1_2379_n_fl_inclose		; Hyp.cls 2860
            jp asm_1_2379_n_fl_ok		; Hyp.cls 2861
asm_1_2379_n_fl_cl_out:		; Hyp.cls 2862
            call asm_1_2379_n_fl_isout		; Hyp.cls 2863
            jp nz, asm_1_2379_n_fp_done		; Hyp.cls 2864
            xor a		; Hyp.cls 2865
            ld (var_hyp_fout), a		; Hyp.cls 2866
            call asm_1_2379_n_fl_plain		; Hyp.cls 2867
            call #BC8F              ; CAS OUT CLOSE [2868]
            di		; Hyp.cls 2869
            jp nc, asm_1_2379_n_fp_done		; Hyp.cls 2870
            jp asm_1_2379_n_fl_ok		; Hyp.cls 2871
; ---- 19: delete (|ERA, "name")
asm_1_2379_n_fl_del:		; Hyp.cls 2873
            call asm_1_2379_n_fl_name		; Hyp.cls 2874
            call asm_1_2379_n_fl_plain		; Hyp.cls 2875
            ld hl, asm_1_2379_n_fl_name_s + 1		; Hyp.cls 2876
            ld (asm_1_2379_n_fl_desc + 1), hl		; Hyp.cls 2877
            ld a, (asm_1_2379_n_fl_name_s)		; Hyp.cls 2878
            ld (asm_1_2379_n_fl_desc), a		; Hyp.cls 2879
            ld hl, asm_1_2379_n_fl_yes           ; (UniDOS asks before it deletes a folder - all it holds too -, [2880]
            ld a, (hl)              ; a read-only or a hidden file: KM WAIT CHAR, its text unseen, [2881]
            ld (hl), 0              ; the VDU off. KM CHAR RETURN: the answer waiting for it - N, [2882]
            or a                    ; so a CP/M program's delete never takes a folder; Y only after [2883]
            ld a, 'N'               ; BDOS 30 op 8, RMDIR's, for its empty folder) [2884]
            jr z, asm_1_2379_n_fl_del_n		; Hyp.cls 2885
            ld a, 'Y'		; Hyp.cls 2886
asm_1_2379_n_fl_del_n:		; Hyp.cls 2887
            call #BB0C		; Hyp.cls 2888
            ld hl, asm_1_2379_n_fl_era           ; KL FIND COMMAND; KM READ CHAR after [2889]
            call #BCD4              ; takes the answer back when nothing asked [2890]
            di		; Hyp.cls 2891
            jp nc, asm_1_2379_n_fp_done		; Hyp.cls 2892
            ld ix, asm_1_2379_n_fl_par		; Hyp.cls 2893
            ld a, 1                 ; one parameter: the string [2894]
            call #001B              ; KL FAR PCALL [2895]
            call #BB09              ; KM READ CHAR (interrupts: off again in fl_done) [2896]
            jp asm_1_2379_n_fl_ok		; Hyp.cls 2897
; ---- 23: rename (the disc ROM's |REN, "new", "old"): the old name at FCB 0-11, the new
; at 16-27 (its drive 0: the old one's)
asm_1_2379_n_fl_ren:		; Hyp.cls 2900
            ld hl, (var_hyp_filecall_fcb)		; Hyp.cls 2901
            call asm_1_2379_n_fl_peek		; Hyp.cls 2902
            ld (asm_1_2379_n_fl_dfl), a		; Hyp.cls 2903
            ld de, 16		; Hyp.cls 2904
            add hl, de		; Hyp.cls 2905
            call asm_1_2379_n_fl_namehl          ; the new name [2906]
            xor a		; Hyp.cls 2907
            ld (asm_1_2379_n_fl_dfl), a		; Hyp.cls 2908
            ld hl, asm_1_2379_n_fl_name_s		; Hyp.cls 2909
            ld de, asm_1_2379_n_fl_new_s		; Hyp.cls 2910
            ld bc, asm_1_2379_n_FL_NL		; Hyp.cls 2911
            ldir		; Hyp.cls 2912
            call asm_1_2379_n_fl_name            ; the old one [2913]
            call asm_1_2379_n_fl_plain		; Hyp.cls 2914
            ld hl, asm_1_2379_n_fl_name_s + 1		; Hyp.cls 2915
            ld (asm_1_2379_n_fl_desc + 1), hl		; Hyp.cls 2916
            ld a, (asm_1_2379_n_fl_name_s)		; Hyp.cls 2917
            ld (asm_1_2379_n_fl_desc), a		; Hyp.cls 2918
            ld hl, asm_1_2379_n_fl_new_s + 1		; Hyp.cls 2919
            ld (asm_1_2379_n_fl_desc2 + 1), hl		; Hyp.cls 2920
            ld a, (asm_1_2379_n_fl_new_s)		; Hyp.cls 2921
            ld (asm_1_2379_n_fl_desc2), a		; Hyp.cls 2922
            ld hl, asm_1_2379_n_fl_rencmd		; Hyp.cls 2923
            call #BCD4              ; KL FIND COMMAND [2924]
            di		; Hyp.cls 2925
            jp nc, asm_1_2379_n_fp_done		; Hyp.cls 2926
            ld ix, asm_1_2379_n_fl_par2          ; IX+0: the last parameter (the old name), IX+2: the new [2927]
            ld a, 2		; Hyp.cls 2928
            call #001B              ; KL FAR PCALL [2929]
            jp asm_1_2379_n_fl_ok              ; (interrupts: off again in fl_done) [2930]
; ---- 33: read record r0-r1: on to it (from the start again if it is behind)
asm_1_2379_n_fl_rdran:		; Hyp.cls 2932
            call asm_1_2379_n_fl_isin		; Hyp.cls 2933
            jp nz, asm_1_2379_n_fl_rdout		; Hyp.cls 2934
            ld hl, (var_hyp_filecall_fcb)		; Hyp.cls 2935
            ld de, 33		; Hyp.cls 2936
            add hl, de		; Hyp.cls 2937
            call asm_1_2379_n_fl_peek		; Hyp.cls 2938
            ld e, a		; Hyp.cls 2939
            inc hl		; Hyp.cls 2940
            call asm_1_2379_n_fl_peek		; Hyp.cls 2941
            ld d, a		; Hyp.cls 2942
            ld (asm_1_2379_n_fl_want), de		; Hyp.cls 2943
            ld hl, (asm_1_2379_n_fl_inrec)		; Hyp.cls 2944
            or a		; Hyp.cls 2945
            sbc hl, de		; Hyp.cls 2946
            jr c, asm_1_2379_n_fl_rr_on		; Hyp.cls 2947
            jr z, asm_1_2379_n_fl_rr_on		; Hyp.cls 2948
            call asm_1_2379_n_fl_inclose         ; behind: open it again [2949]
            ld hl, asm_1_2379_n_fl_inname		; Hyp.cls 2950
            ld de, asm_1_2379_n_fl_name_s		; Hyp.cls 2951
            ld bc, asm_1_2379_n_FL_NL		; Hyp.cls 2952
            ldir		; Hyp.cls 2953
            call asm_1_2379_n_fl_inopen		; Hyp.cls 2954
            jp nc, asm_1_2379_n_fp_done		; Hyp.cls 2955
            ld a, (asm_1_2379_n_fl_slot)		; Hyp.cls 2956
            ld (var_hyp_fin), a		; Hyp.cls 2957
            ld hl, 0		; Hyp.cls 2958
            ld (asm_1_2379_n_fl_inrec), hl		; Hyp.cls 2959
asm_1_2379_n_fl_rr_on:		; Hyp.cls 2960
            ld hl, (asm_1_2379_n_fl_inrec)		; Hyp.cls 2961
            ld de, (asm_1_2379_n_fl_want)		; Hyp.cls 2962
            or a		; Hyp.cls 2963
            sbc hl, de		; Hyp.cls 2964
            jr nc, asm_1_2379_n_fl_rdseq		; Hyp.cls 2965
            call asm_1_2379_n_fl_rdrec		; Hyp.cls 2966
            jp z, asm_1_2379_n_fl_eof		; Hyp.cls 2967
            ld hl, (asm_1_2379_n_fl_inrec)		; Hyp.cls 2968
            inc hl		; Hyp.cls 2969
            ld (asm_1_2379_n_fl_inrec), hl		; Hyp.cls 2970
            jr asm_1_2379_n_fl_rr_on		; Hyp.cls 2971
; ---- 20: read the next record
asm_1_2379_n_fl_rdseq:		; Hyp.cls 2973
            call asm_1_2379_n_fl_isin		; Hyp.cls 2974
            jr nz, asm_1_2379_n_fl_rdout		; Hyp.cls 2975
            call asm_1_2379_n_fl_rdrec		; Hyp.cls 2976
            jr z, asm_1_2379_n_fl_eof		; Hyp.cls 2977
            ex de, hl		; Hyp.cls 2978
            ld hl, (asm_1_2379_n_fl_inrec)		; Hyp.cls 2979
            inc hl		; Hyp.cls 2980
            ld (asm_1_2379_n_fl_inrec), hl		; Hyp.cls 2981
            ex de, hl		; Hyp.cls 2982
            ld b, a                 ; the record padded with #1A [2983]
            ld a, 128		; Hyp.cls 2984
            sub b		; Hyp.cls 2985
            jr z, asm_1_2379_n_fl_rd_put		; Hyp.cls 2986
            ld b, a		; Hyp.cls 2987
            ld a, #1A		; Hyp.cls 2988
asm_1_2379_n_fl_rd_pad:		; Hyp.cls 2989
            ld (hl), a		; Hyp.cls 2990
            inc hl		; Hyp.cls 2991
            djnz asm_1_2379_n_fl_rd_pad		; Hyp.cls 2992
asm_1_2379_n_fl_rd_put:		; Hyp.cls 2993
            ld hl, (var_hyp_filecall_dma)          ; into the slot's DMA: in one page, one ldir [2994]
            ld bc, 128		; Hyp.cls 2995
            call asm_1_2379_n_fl_fits		; Hyp.cls 2996
            jr c, asm_1_2379_n_fl_rd_slow		; Hyp.cls 2997
            ld de, (var_hyp_filecall_buf)		; Hyp.cls 2998
            call asm_1_2379_n_fl_toslot		; Hyp.cls 2999
            jp asm_1_2379_n_fl_ok		; Hyp.cls 3000
asm_1_2379_n_fl_rd_slow:                         ; (across two pages: a byte at a time) [3001]
            ld hl, (var_hyp_filecall_buf)		; Hyp.cls 3002
            ld de, (var_hyp_filecall_dma)		; Hyp.cls 3003
            ld b, 128		; Hyp.cls 3004
asm_1_2379_n_fl_rd_cp:		; Hyp.cls 3005
            ld a, (hl)		; Hyp.cls 3006
            ex de, hl		; Hyp.cls 3007
            call asm_1_2379_n_fl_poke		; Hyp.cls 3008
            ex de, hl		; Hyp.cls 3009
            inc hl		; Hyp.cls 3010
            inc de		; Hyp.cls 3011
            djnz asm_1_2379_n_fl_rd_cp		; Hyp.cls 3012
            jp asm_1_2379_n_fl_ok		; Hyp.cls 3013
asm_1_2379_n_fl_rdout:		; Hyp.cls 3014
            call asm_1_2379_n_fl_isout           ; a file being written: nothing to read back [3015]
            jp nz, asm_1_2379_n_fp_done		; Hyp.cls 3016
asm_1_2379_n_fl_eof:		; Hyp.cls 3017
            ld a, 1		; Hyp.cls 3018
            ld (asm_1_2379_n_fl_res), a		; Hyp.cls 3019
            jp asm_1_2379_n_fp_done		; Hyp.cls 3020
; ---- 21 / 34: write the next record
asm_1_2379_n_fl_write:		; Hyp.cls 3022
            call asm_1_2379_n_fl_isout		; Hyp.cls 3023
            jp nz, asm_1_2379_n_fp_done		; Hyp.cls 3024
            ld hl, (var_hyp_filecall_dma)          ; the slot's DMA into buf [3025]
            ld bc, 128		; Hyp.cls 3026
            call asm_1_2379_n_fl_fits		; Hyp.cls 3027
            jr c, asm_1_2379_n_fl_wr_slow		; Hyp.cls 3028
            ld de, (var_hyp_filecall_buf)		; Hyp.cls 3029
            call asm_1_2379_n_fl_fromslot		; Hyp.cls 3030
            jr asm_1_2379_n_fl_wr_got		; Hyp.cls 3031
asm_1_2379_n_fl_wr_slow:		; Hyp.cls 3032
            ld de, (var_hyp_filecall_buf)		; Hyp.cls 3033
            ld b, 128		; Hyp.cls 3034
asm_1_2379_n_fl_wr_cp:		; Hyp.cls 3035
            call asm_1_2379_n_fl_peek		; Hyp.cls 3036
            ld (de), a		; Hyp.cls 3037
            inc hl		; Hyp.cls 3038
            inc de		; Hyp.cls 3039
            djnz asm_1_2379_n_fl_wr_cp		; Hyp.cls 3040
asm_1_2379_n_fl_wr_got:		; Hyp.cls 3041
            call asm_1_2379_n_fl_plain		; Hyp.cls 3042
            ld hl, (var_hyp_filecall_buf)		; Hyp.cls 3043
            ld b, 128		; Hyp.cls 3044
asm_1_2379_n_fl_wr_lp:		; Hyp.cls 3045
            ld a, (hl)		; Hyp.cls 3046
            push bc		; Hyp.cls 3047
            push hl		; Hyp.cls 3048
            call #BC95              ; CAS OUT CHAR [3049]
            di		; Hyp.cls 3050
            pop hl		; Hyp.cls 3051
            pop bc		; Hyp.cls 3052
            jp nc, asm_1_2379_n_fp_done		; Hyp.cls 3053
            inc hl		; Hyp.cls 3054
            djnz asm_1_2379_n_fl_wr_lp		; Hyp.cls 3055
            ld hl, (asm_1_2379_n_fl_outrec)		; Hyp.cls 3056
            inc hl		; Hyp.cls 3057
            ld (asm_1_2379_n_fl_outrec), hl		; Hyp.cls 3058
            jp asm_1_2379_n_fl_ok		; Hyp.cls 3059
; ---- 35: the file's size in records (r0-r2): counted, reading it through. The file this slot
; is reading is opened again after, at its record; another slot's being read: 255
asm_1_2379_n_fl_size:		; Hyp.cls 3062
            ld a, (var_hyp_fin)		; Hyp.cls 3063
            or a		; Hyp.cls 3064
            jr z, asm_1_2379_n_fl_sz_free		; Hyp.cls 3065
            ld b, a		; Hyp.cls 3066
            ld a, (asm_1_2379_n_fl_slot)		; Hyp.cls 3067
            cp b		; Hyp.cls 3068
            jp nz, asm_1_2379_n_fp_done		; Hyp.cls 3069
            call asm_1_2379_n_fl_inclose		; Hyp.cls 3070
            ld a, 1		; Hyp.cls 3071
asm_1_2379_n_fl_sz_free:		; Hyp.cls 3072
            ld (asm_1_2379_n_fl_had), a		; Hyp.cls 3073
            call asm_1_2379_n_fl_name		; Hyp.cls 3074
            call asm_1_2379_n_fl_inopen		; Hyp.cls 3075
            jr nc, asm_1_2379_n_fl_sz_back		; Hyp.cls 3076
            ld hl, 0		; Hyp.cls 3077
            ld (asm_1_2379_n_fl_cnt), hl		; Hyp.cls 3078
asm_1_2379_n_fl_sz_lp:		; Hyp.cls 3079
            call asm_1_2379_n_fl_rdrec		; Hyp.cls 3080
            jr z, asm_1_2379_n_fl_sz_end		; Hyp.cls 3081
            ld hl, (asm_1_2379_n_fl_cnt)		; Hyp.cls 3082
            inc hl		; Hyp.cls 3083
            ld (asm_1_2379_n_fl_cnt), hl		; Hyp.cls 3084
            cp 128		; Hyp.cls 3085
            jr z, asm_1_2379_n_fl_sz_lp		; Hyp.cls 3086
asm_1_2379_n_fl_sz_end:		; Hyp.cls 3087
            call asm_1_2379_n_fl_inclose		; Hyp.cls 3088
            ld hl, (asm_1_2379_n_fl_cnt)		; Hyp.cls 3089
            call asm_1_2379_n_fl_ranput		; Hyp.cls 3090
            xor a		; Hyp.cls 3091
            ld (asm_1_2379_n_fl_res), a		; Hyp.cls 3092
asm_1_2379_n_fl_sz_back:		; Hyp.cls 3093
            ld a, (asm_1_2379_n_fl_had)		; Hyp.cls 3094
            or a		; Hyp.cls 3095
            jp z, asm_1_2379_n_fp_done		; Hyp.cls 3096
            ld hl, asm_1_2379_n_fl_inname        ; the slot's read file again, on to its record [3097]
            ld de, asm_1_2379_n_fl_name_s		; Hyp.cls 3098
            ld bc, asm_1_2379_n_FL_NL		; Hyp.cls 3099
            ldir		; Hyp.cls 3100
            call asm_1_2379_n_fl_inopen		; Hyp.cls 3101
            jp nc, asm_1_2379_n_fp_done		; Hyp.cls 3102
            ld a, (asm_1_2379_n_fl_slot)		; Hyp.cls 3103
            ld (var_hyp_fin), a		; Hyp.cls 3104
            ld hl, (asm_1_2379_n_fl_inrec)		; Hyp.cls 3105
asm_1_2379_n_fl_sz_skip:		; Hyp.cls 3106
            ld a, h		; Hyp.cls 3107
            or l		; Hyp.cls 3108
            jp z, asm_1_2379_n_fp_done		; Hyp.cls 3109
            push hl		; Hyp.cls 3110
            call asm_1_2379_n_fl_rdrec		; Hyp.cls 3111
            pop hl		; Hyp.cls 3112
            dec hl		; Hyp.cls 3113
            jr asm_1_2379_n_fl_sz_skip		; Hyp.cls 3114
; ---- 36: set the random record (r0-r2) from where the file is: the next record read or
; written; a file not open here: from the FCB's extent and record (ex * 128 + cr)
asm_1_2379_n_fl_setran:		; Hyp.cls 3117
            call asm_1_2379_n_fl_isin		; Hyp.cls 3118
            ld hl, (asm_1_2379_n_fl_inrec)		; Hyp.cls 3119
            jr z, asm_1_2379_n_fl_sr_put		; Hyp.cls 3120
            call asm_1_2379_n_fl_isout		; Hyp.cls 3121
            ld hl, (asm_1_2379_n_fl_outrec)		; Hyp.cls 3122
            jr z, asm_1_2379_n_fl_sr_put		; Hyp.cls 3123
            ld hl, (var_hyp_filecall_fcb)		; Hyp.cls 3124
            ld de, 32		; Hyp.cls 3125
            add hl, de		; Hyp.cls 3126
            call asm_1_2379_n_fl_peek            ; cr [3127]
            ld e, a		; Hyp.cls 3128
            ld bc, -20		; Hyp.cls 3129
            add hl, bc		; Hyp.cls 3130
            call asm_1_2379_n_fl_peek            ; ex [3131]
            ld h, a		; Hyp.cls 3132
            srl h		; Hyp.cls 3133
            ld a, e		; Hyp.cls 3134
            jr nc, asm_1_2379_n_fl_sr_lo		; Hyp.cls 3135
            or #80		; Hyp.cls 3136
asm_1_2379_n_fl_sr_lo:		; Hyp.cls 3137
            ld l, a		; Hyp.cls 3138
asm_1_2379_n_fl_sr_put:		; Hyp.cls 3139
            call asm_1_2379_n_fl_ranput		; Hyp.cls 3140
            jp asm_1_2379_n_fl_ok		; Hyp.cls 3141
; ---- 17 / 18: search the folder (UniDOS: the FCB's drive's, else the slot's) for BDOS 17's
; name ("?" any character; kept at SRCH in the bank, SRCH + 12 the entries passed - 18 goes on
; from there): the next one, as a CP/M directory entry at the DMA (its record count from its
; length, 128 at most). 17 examines the folder (Ctrl J) into the hypervisor's page (#6000-#7BFF:
; 112 entries at most), then 17 and 18 look there. No UniDOS (or an AMSDOS floppy): none (255)
asm_1_2379_n_fl_srch1:		; Hyp.cls 3147
            ld hl, (var_hyp_filecall_fcb)		; Hyp.cls 3148
            ld de, 63216		; Hyp.cls 3149
            ld b, 12		; Hyp.cls 3150
asm_1_2379_n_fl_s1_lp:		; Hyp.cls 3151
            call asm_1_2379_n_fl_peek		; Hyp.cls 3152
            ex de, hl		; Hyp.cls 3153
            call asm_1_2379_n_fl_poke		; Hyp.cls 3154
            ex de, hl		; Hyp.cls 3155
            inc hl		; Hyp.cls 3156
            inc de		; Hyp.cls 3157
            djnz asm_1_2379_n_fl_s1_lp		; Hyp.cls 3158
            ex de, hl		; Hyp.cls 3159
            xor a		; Hyp.cls 3160
            call asm_1_2379_n_fl_poke            ; none passed [3161]
            xor a		; Hyp.cls 3162
            ld (asm_1_2379_n_fl_cn), a		; Hyp.cls 3163
            ld hl, #6000		; Hyp.cls 3164
            ld (asm_1_2379_n_fl_at), hl		; Hyp.cls 3165
            ld de, asm_1_2379_n_fl_name_s + 1    ; "B:" (or B's path) [3166]
            ld hl, 63216		; Hyp.cls 3167
            call asm_1_2379_n_fl_peek		; Hyp.cls 3168
            or a		; Hyp.cls 3169
            jr z, asm_1_2379_n_fl_s_own		; Hyp.cls 3170
            add a, 64		; Hyp.cls 3171
            jr asm_1_2379_n_fl_s_drv		; Hyp.cls 3172
asm_1_2379_n_fl_s_own:		; Hyp.cls 3173
            ld a, (var_hyp_filecall_drive)		; Hyp.cls 3174
            or a		; Hyp.cls 3175
            jr z, asm_1_2379_n_fl_s_nod		; Hyp.cls 3176
asm_1_2379_n_fl_s_drv:		; Hyp.cls 3177
            call asm_1_2379_n_fl_pfx		; Hyp.cls 3178
asm_1_2379_n_fl_s_nod:		; Hyp.cls 3179
; UniDOS: the directory itself (Ctrl J examine), its files into the cache - no file opened (so
; not held up by another slot's reading)
            push de		; Hyp.cls 3182
            call asm_1_2379_n_fl_exdir		; Hyp.cls 3183
            pop de		; Hyp.cls 3184
            jp nz, asm_1_2379_n_fp_done          ; (none to list: no UniDOS, an AMSDOS floppy - 255) [3185]
asm_1_2379_n_fl_sx_lp:		; Hyp.cls 3186
            ld hl, (asm_1_2379_n_fl_at)		; Hyp.cls 3187
            inc hl                  ; (the name straight into the entry) [3188]
            ld ix, asm_1_2379_n_FL_DATE		; Hyp.cls 3189
            ld c, 13                ; examine next [3190]
            call asm_1_2379_n_fl_cjc		; Hyp.cls 3191
            jr nc, asm_1_2379_n_fl_sx_end		; Hyp.cls 3192
            jr nz, asm_1_2379_n_fl_sx_end		; Hyp.cls 3193
            bit 4, a		; Hyp.cls 3194
            jr nz, asm_1_2379_n_fl_sx_lp         ; (a folder: not for CP/M) [3195]
            ld hl, (asm_1_2379_n_fl_at)		; Hyp.cls 3196
            ld (hl), 1              ; in use [3197]
            ld a, b		; Hyp.cls 3198
            or c		; Hyp.cls 3199
            jr z, asm_1_2379_n_fl_sx_sz		; Hyp.cls 3200
            ld de, #FFFF            ; (64K or more) [3201]
asm_1_2379_n_fl_sx_sz:		; Hyp.cls 3202
            ld bc, 12		; Hyp.cls 3203
            add hl, bc		; Hyp.cls 3204
            ld (hl), b              ; kind, flags 0 [3205]
            inc hl		; Hyp.cls 3206
            ld (hl), b		; Hyp.cls 3207
            inc hl		; Hyp.cls 3208
            ld (hl), e              ; its length [3209]
            inc hl		; Hyp.cls 3210
            ld (hl), d		; Hyp.cls 3211
            ld hl, (asm_1_2379_n_fl_at)		; Hyp.cls 3212
            ld bc, 64		; Hyp.cls 3213
            add hl, bc		; Hyp.cls 3214
            ld (asm_1_2379_n_fl_at), hl		; Hyp.cls 3215
            ld hl, asm_1_2379_n_fl_cn		; Hyp.cls 3216
            inc (hl)		; Hyp.cls 3217
            ld a, (hl)		; Hyp.cls 3218
            cp asm_1_2379_n_FL_CMAX		; Hyp.cls 3219
            jr c, asm_1_2379_n_fl_sx_lp		; Hyp.cls 3220
asm_1_2379_n_fl_sx_end:		; Hyp.cls 3221
            jp asm_1_2379_n_fl_srch		; Hyp.cls 3222
asm_1_2379_n_fl_srch:		; Hyp.cls 3223
            ld hl, 63216 + 12		; Hyp.cls 3224
            call asm_1_2379_n_fl_peek		; Hyp.cls 3225
            ld (asm_1_2379_n_fl_skip), a		; Hyp.cls 3226
            xor a		; Hyp.cls 3227
            ld (asm_1_2379_n_fl_k), a		; Hyp.cls 3228
asm_1_2379_n_fl_s_lp:		; Hyp.cls 3229
            ld a, (asm_1_2379_n_fl_cn)           ; the next entry, from the cache [3230]
            ld b, a		; Hyp.cls 3231
            ld a, (asm_1_2379_n_fl_k)		; Hyp.cls 3232
            cp b		; Hyp.cls 3233
            jp nc, asm_1_2379_n_fp_done          ; (none: 255) [3234]
            ld l, a		; Hyp.cls 3235
            ld h, 0		; Hyp.cls 3236
            add hl, hl		; Hyp.cls 3237
            add hl, hl		; Hyp.cls 3238
            add hl, hl		; Hyp.cls 3239
            add hl, hl		; Hyp.cls 3240
            add hl, hl		; Hyp.cls 3241
            add hl, hl		; Hyp.cls 3242
            ld de, #6000		; Hyp.cls 3243
            add hl, de		; Hyp.cls 3244
            ld de, (var_hyp_filecall_buf)		; Hyp.cls 3245
            ld bc, 64		; Hyp.cls 3246
            ldir		; Hyp.cls 3247
            ld hl, asm_1_2379_n_fl_k		; Hyp.cls 3248
            inc (hl)		; Hyp.cls 3249
            ld a, (asm_1_2379_n_fl_skip)		; Hyp.cls 3250
            cp (hl)		; Hyp.cls 3251
            jr nc, asm_1_2379_n_fl_s_lp          ; passed already [3252]
            ld hl, (var_hyp_filecall_buf)		; Hyp.cls 3253
            ld a, (hl)		; Hyp.cls 3254
            dec a		; Hyp.cls 3255
            jr nz, asm_1_2379_n_fl_s_lp          ; not in use (1) [3256]
            inc hl		; Hyp.cls 3257
            ld de, 63216 + 1		; Hyp.cls 3258
            ld b, 11		; Hyp.cls 3259
asm_1_2379_n_fl_s_cmp:		; Hyp.cls 3260
            ex de, hl		; Hyp.cls 3261
            call asm_1_2379_n_fl_peek		; Hyp.cls 3262
            ex de, hl		; Hyp.cls 3263
            and #7F		; Hyp.cls 3264
            cp '?'		; Hyp.cls 3265
            jr z, asm_1_2379_n_fl_s_any		; Hyp.cls 3266
            ld c, a		; Hyp.cls 3267
            ld a, (hl)		; Hyp.cls 3268
            and #7F		; Hyp.cls 3269
            cp c		; Hyp.cls 3270
            jr nz, asm_1_2379_n_fl_s_lp		; Hyp.cls 3271
asm_1_2379_n_fl_s_any:		; Hyp.cls 3272
            inc hl		; Hyp.cls 3273
            inc de		; Hyp.cls 3274
            djnz asm_1_2379_n_fl_s_cmp		; Hyp.cls 3275
            ld hl, (var_hyp_filecall_buf)          ; the entry: user 0, the name, extent 0, the records, no blocks [3276]
            ld (hl), 0		; Hyp.cls 3277
            ld de, 14		; Hyp.cls 3278
            add hl, de		; Hyp.cls 3279
            ld e, (hl)		; Hyp.cls 3280
            inc hl		; Hyp.cls 3281
            ld d, (hl)		; Hyp.cls 3282
            ex de, hl		; Hyp.cls 3283
            ld bc, 127		; Hyp.cls 3284
            add hl, bc		; Hyp.cls 3285
            jr c, asm_1_2379_n_fl_s_big		; Hyp.cls 3286
            ld a, h		; Hyp.cls 3287
            cp #40		; Hyp.cls 3288
            jr nc, asm_1_2379_n_fl_s_big		; Hyp.cls 3289
            sla l		; Hyp.cls 3290
            rla		; Hyp.cls 3291
            jr asm_1_2379_n_fl_s_rc		; Hyp.cls 3292
asm_1_2379_n_fl_s_big:		; Hyp.cls 3293
            ld a, 128		; Hyp.cls 3294
asm_1_2379_n_fl_s_rc:		; Hyp.cls 3295
            ex de, hl		; Hyp.cls 3296
            ld (hl), a		; Hyp.cls 3297
            ld b, 3		; Hyp.cls 3298
asm_1_2379_n_fl_s_z1:		; Hyp.cls 3299
            dec hl		; Hyp.cls 3300
            ld (hl), 0		; Hyp.cls 3301
            djnz asm_1_2379_n_fl_s_z1		; Hyp.cls 3302
            ld de, 4		; Hyp.cls 3303
            add hl, de		; Hyp.cls 3304
            ld b, 16		; Hyp.cls 3305
asm_1_2379_n_fl_s_z2:		; Hyp.cls 3306
            ld (hl), 0		; Hyp.cls 3307
            inc hl		; Hyp.cls 3308
            djnz asm_1_2379_n_fl_s_z2		; Hyp.cls 3309
            ld hl, (var_hyp_filecall_dma)		; Hyp.cls 3310
            ld de, (var_hyp_filecall_buf)		; Hyp.cls 3311
            ld b, 32		; Hyp.cls 3312
asm_1_2379_n_fl_s_put:		; Hyp.cls 3313
            ld a, (de)		; Hyp.cls 3314
            call asm_1_2379_n_fl_poke		; Hyp.cls 3315
            inc hl		; Hyp.cls 3316
            inc de		; Hyp.cls 3317
            djnz asm_1_2379_n_fl_s_put		; Hyp.cls 3318
            ld hl, 63216 + 12		; Hyp.cls 3319
            ld a, (asm_1_2379_n_fl_k)		; Hyp.cls 3320
            call asm_1_2379_n_fl_poke		; Hyp.cls 3321
            jp asm_1_2379_n_fl_ok		; Hyp.cls 3322
asm_1_2379_n_fl_skip:    db 0		; Hyp.cls 3323
asm_1_2379_n_fl_k:       db 0		; Hyp.cls 3324
asm_1_2379_n_fl_cn:      db 0                    ; the folder's entries in the cache (#6000) [3325]
asm_1_2379_n_fl_ranput:                          ; the FCB's r0-r2 = HL [3326]
            ex de, hl		; Hyp.cls 3327
            ld hl, (var_hyp_filecall_fcb)		; Hyp.cls 3328
            ld bc, 33		; Hyp.cls 3329
            add hl, bc		; Hyp.cls 3330
            ld a, e		; Hyp.cls 3331
            call asm_1_2379_n_fl_poke		; Hyp.cls 3332
            inc hl		; Hyp.cls 3333
            ld a, d		; Hyp.cls 3334
            call asm_1_2379_n_fl_poke		; Hyp.cls 3335
            inc hl		; Hyp.cls 3336
            xor a		; Hyp.cls 3337
            jp asm_1_2379_n_fl_poke		; Hyp.cls 3338
; ---- the parts
asm_1_2379_n_fl_inopen:                          ; open fl_name_s to read: carry = done [3340]
            call asm_1_2379_n_fl_plain		; Hyp.cls 3341
            ld hl, asm_1_2379_n_fl_name_s + 1		; Hyp.cls 3342
            ld a, (asm_1_2379_n_fl_name_s)		; Hyp.cls 3343
            ld b, a		; Hyp.cls 3344
            ld de, #4000		; Hyp.cls 3345
            call #BC77              ; CAS IN OPEN [3346]
            di		; Hyp.cls 3347
            ld (asm_1_2379_n_fl_hdr), hl         ; (its header: BDOS 30 #C7) [3348]
            ret		; Hyp.cls 3349
asm_1_2379_n_fl_inclose:		; Hyp.cls 3350
            xor a		; Hyp.cls 3351
            ld (var_hyp_fin), a		; Hyp.cls 3352
            call asm_1_2379_n_fl_plain		; Hyp.cls 3353
            call #BC7A              ; CAS IN CLOSE [3354]
            di		; Hyp.cls 3355
            ret		; Hyp.cls 3356
asm_1_2379_n_fl_rdrec:                           ; read up to fl_n bytes (128) into buf: A = how many (Z [3357]
            call asm_1_2379_n_fl_plain           ; none), HL past them. A #1A is a byte (the soft end of file) [3358]
            ld hl, (var_hyp_filecall_buf)		; Hyp.cls 3359
            ld a, (asm_1_2379_n_fl_n)		; Hyp.cls 3360
            ld b, a		; Hyp.cls 3361
asm_1_2379_n_fl_rr_lp:		; Hyp.cls 3362
            push bc		; Hyp.cls 3363
            push hl		; Hyp.cls 3364
            call #BC80              ; CAS IN CHAR [3365]
            di		; Hyp.cls 3366
            pop hl		; Hyp.cls 3367
            pop bc		; Hyp.cls 3368
            jr c, asm_1_2379_n_fl_rr_b		; Hyp.cls 3369
            cp #1A		; Hyp.cls 3370
            jr nz, asm_1_2379_n_fl_rr_end		; Hyp.cls 3371
asm_1_2379_n_fl_rr_b:		; Hyp.cls 3372
            ld (hl), a		; Hyp.cls 3373
            inc hl		; Hyp.cls 3374
            djnz asm_1_2379_n_fl_rr_lp		; Hyp.cls 3375
asm_1_2379_n_fl_rr_end:		; Hyp.cls 3376
            ld a, (asm_1_2379_n_fl_n)		; Hyp.cls 3377
            sub b		; Hyp.cls 3378
            ld c, a		; Hyp.cls 3379
            ld a, 128		; Hyp.cls 3380
            ld (asm_1_2379_n_fl_n), a            ; (128 again for the next) [3381]
            ld a, c		; Hyp.cls 3382
            or a		; Hyp.cls 3383
            ret		; Hyp.cls 3384
asm_1_2379_n_fl_fits:                            ; HL = a slot address, BC = bytes: NC = all in its 16K page. [3385]
            push hl                 ; Keeps BC, DE, HL [3386]
            ld a, h		; Hyp.cls 3387
            and #3F		; Hyp.cls 3388
            ld h, a		; Hyp.cls 3389
            add hl, bc		; Hyp.cls 3390
            ld a, h		; Hyp.cls 3391
            cp #40		; Hyp.cls 3392
            jr c, asm_1_2379_n_fl_ft_ok		; Hyp.cls 3393
            jr nz, asm_1_2379_n_fl_ft_no		; Hyp.cls 3394
            ld a, l		; Hyp.cls 3395
            or a		; Hyp.cls 3396
            jr nz, asm_1_2379_n_fl_ft_no		; Hyp.cls 3397
asm_1_2379_n_fl_ft_ok:		; Hyp.cls 3398
            pop hl		; Hyp.cls 3399
            or a		; Hyp.cls 3400
            ret		; Hyp.cls 3401
asm_1_2379_n_fl_ft_no:		; Hyp.cls 3402
            pop hl		; Hyp.cls 3403
            scf		; Hyp.cls 3404
            ret		; Hyp.cls 3405
asm_1_2379_n_fl_plain:                           ; the hypervisor's page in the window (the buffers) [3406]
            ld bc, (var_hyp_hps)		; Hyp.cls 3407
            out (c), c		; Hyp.cls 3408
            ret		; Hyp.cls 3409
asm_1_2379_n_fl_name:                            ; fl_name_s = the FCB's file: length, "B:NAME.EXT" [3410]
            ld hl, (var_hyp_filecall_fcb)		; Hyp.cls 3411
asm_1_2379_n_fl_namehl:                          ; (HL = an FCB in the slot) [3412]
            ld de, asm_1_2379_n_fl_name_s + 1		; Hyp.cls 3413
            call asm_1_2379_n_fl_peek            ; its drive: 0 = the slot's (or fl_dfl's) [3414]
            or a		; Hyp.cls 3415
            jr nz, asm_1_2379_n_fl_nm_d		; Hyp.cls 3416
            ld a, (asm_1_2379_n_fl_dfl)		; Hyp.cls 3417
            or a		; Hyp.cls 3418
            jr nz, asm_1_2379_n_fl_nm_d		; Hyp.cls 3419
            ld a, (var_hyp_filecall_drive)		; Hyp.cls 3420
            or a		; Hyp.cls 3421
            jr z, asm_1_2379_n_fl_nm_nod		; Hyp.cls 3422
            sub 64		; Hyp.cls 3423
asm_1_2379_n_fl_nm_d:		; Hyp.cls 3424
            add a, 64		; Hyp.cls 3425
            call asm_1_2379_n_fl_pfx             ; "B:", or B's path (UniDOS: "IDE:GAMES/") [3426]
asm_1_2379_n_fl_nm_nod:		; Hyp.cls 3427
            ld b, 11		; Hyp.cls 3428
asm_1_2379_n_fl_nm_lp:		; Hyp.cls 3429
            inc hl		; Hyp.cls 3430
            ld a, b		; Hyp.cls 3431
            cp 3		; Hyp.cls 3432
            jr nz, asm_1_2379_n_fl_nm_c		; Hyp.cls 3433
            ld a, '.'		; Hyp.cls 3434
            ld (de), a		; Hyp.cls 3435
            inc de		; Hyp.cls 3436
asm_1_2379_n_fl_nm_c:		; Hyp.cls 3437
            call asm_1_2379_n_fl_peek		; Hyp.cls 3438
            and #7F		; Hyp.cls 3439
            cp ' ' + 1		; Hyp.cls 3440
            jr c, asm_1_2379_n_fl_nm_sk		; Hyp.cls 3441
            ld (de), a		; Hyp.cls 3442
            inc de		; Hyp.cls 3443
asm_1_2379_n_fl_nm_sk:		; Hyp.cls 3444
            djnz asm_1_2379_n_fl_nm_lp		; Hyp.cls 3445
            ex de, hl		; Hyp.cls 3446
            ld de, asm_1_2379_n_fl_name_s + 1		; Hyp.cls 3447
            or a		; Hyp.cls 3448
            sbc hl, de		; Hyp.cls 3449
            ld a, l		; Hyp.cls 3450
            ld (asm_1_2379_n_fl_name_s), a		; Hyp.cls 3451
            ret		; Hyp.cls 3452
asm_1_2379_n_fl_ok:		; Hyp.cls 3453
            xor a		; Hyp.cls 3454
            ld (asm_1_2379_n_fl_res), a		; Hyp.cls 3455
asm_1_2379_n_fp_done:                            ; back to FileCall in main RAM (fp_done) [3456]
            ld sp, (asm_1_2379_n_fp_sp)		; Hyp.cls 3457
            ret		; Hyp.cls 3458
asm_1_2379_n_fl_era:     db "ER", "A" + #80		; Hyp.cls 3459
asm_1_2379_n_fl_rencmd:  db "RE", "N" + #80		; Hyp.cls 3460
asm_1_2379_n_fl_par2:    dw asm_1_2379_n_fl_desc, asm_1_2379_n_fl_desc2		; Hyp.cls 3461
asm_1_2379_n_fl_desc2:   db 0		; Hyp.cls 3462
            dw 0		; Hyp.cls 3463
asm_1_2379_n_fl_dfl:     db 0                    ; fl_name: the drive for an FCB whose own is 0 (rename) [3464]
asm_1_2379_n_fl_par:     dw asm_1_2379_n_fl_desc		; Hyp.cls 3465
asm_1_2379_n_fl_desc:    db 0		; Hyp.cls 3466
            dw 0		; Hyp.cls 3467
asm_1_2379_n_fl_n:       db 128                  ; bytes fl_rdrec reads [3468]
asm_1_2379_n_fl_cnt:     dw 0		; Hyp.cls 3469
asm_1_2379_n_fl_at:      dw 0		; Hyp.cls 3470
asm_1_2379_n_fl_infcb:   dw 0		; Hyp.cls 3471
            db 0                    ; (1: fl_infcb the open's - fl_is) [3472]
asm_1_2379_n_fl_inrec:   dw 0		; Hyp.cls 3473
asm_1_2379_n_fl_want:    dw 0		; Hyp.cls 3474
asm_1_2379_n_fl_outfcb:  dw 0		; Hyp.cls 3475
            db 0		; Hyp.cls 3476
asm_1_2379_n_fl_outrec:  dw 0                    ; the next record written (36) [3477]
asm_1_2379_n_fl_had:     db 0                    ; 35: this slot's read file closed for it [3478]
asm_1_2379_n_fp_sp:      dw 0		; Hyp.cls 3479
; ---- UniDOS: its Ctrl J BIOS command (found once, KL FIND COMMAND) - a drive letter can be a
; path (CD IDE:, CD SD:GAMES ...: any UniDOS device's folder), folders listed (examine). FL_MAP:
; letters A-P, 32 bytes each: the path's length (0 none: the letter itself, "B:"), the path
; ("IDE:GAMES/": a device or logical drive, its folders, the last "/" or ":"). Cleared when
; UniDOS is found, and only set with it: with AMSDOS no letter has a path. Up there with the
; names (48 characters: a path and NAME.EXT), BDOS 132's block, DIR's listing: the FILES.DIR
; cache is #6000-#7BFF (112 entries)
asm_1_2379_n_FL_CMAX:    equ 112                 ; the cache's entries [3487]
asm_1_2379_n_FL_NL:      equ 49                  ; a name: its length, then the characters [3488]
asm_1_2379_n_fl_name_s:  equ #7C00               ; length, then "B:NAME.EXT" (or "IDE:GAMES/NAME.EXT") [3489]
asm_1_2379_n_fl_inname:  equ asm_1_2379_n_fl_name_s + asm_1_2379_n_FL_NL   ; the one being read's (33 going back) [3490]
asm_1_2379_n_fl_new_s:   equ asm_1_2379_n_fl_inname + asm_1_2379_n_FL_NL   ; (23: the new name) [3491]
asm_1_2379_n_FL_UB:      equ #7D00               ; BDOS 132's block (72 bytes) [3492]
asm_1_2379_n_FL_EXK:     equ #7D48               ; the folder DIR lists (its path: length, 31 characters) [3493]
asm_1_2379_n_FL_DATE:    equ #7D68               ; a date examine gives (7), then a name (11) [3494]
asm_1_2379_n_FL_TN:      equ #7D70		; Hyp.cls 3495
asm_1_2379_n_FL_MAP:     equ #7E00		; Hyp.cls 3496
            ASSERT #6000 + asm_1_2379_n_FL_CMAX * 64 <= asm_1_2379_n_fl_name_s, "the search's cache, below the names"		; Hyp.cls 3497
            ASSERT asm_1_2379_n_fl_new_s + asm_1_2379_n_FL_NL <= asm_1_2379_n_FL_UB, "the names, below BDOS 132's block"		; Hyp.cls 3498
            ASSERT (asm_1_2379_n_FL_MAP & 255) = 0, "asm_1_2379_n_FL_MAP: a page's start (asm_1_2379_n_fl_mapa)"		; Hyp.cls 3499
asm_1_2379_n_fl_cjf:     db 0                    ; 0: not looked for yet, 1: UniDOS, 2: none [3500]
asm_1_2379_n_fl_cj:      dw 0                    ; Ctrl J's far address (address, ROM) [3501]
            db 0		; Hyp.cls 3502
asm_1_2379_n_fl_cjn:     db #8A                  ; (its name) [3503]
asm_1_2379_n_fl_exv:     db 0                    ; FL_EXK's listing is the one UniDOS examines now ... [3504]
asm_1_2379_n_fl_exi:     dw 0                    ; ... at this entry next [3505]
asm_1_2379_n_fl_ue:      dw 0		; Hyp.cls 3506
; carry: UniDOS here (the first time: looked for, the paths cleared)
asm_1_2379_n_fl_uni:		; Hyp.cls 3508
            ld a, (asm_1_2379_n_fl_cjf)		; Hyp.cls 3509
            cp 1		; Hyp.cls 3510
            jr z, asm_1_2379_n_fl_un_y		; Hyp.cls 3511
            or a		; Hyp.cls 3512
            ret nz                  ; (2: none - NC) [3513]
            ld hl, asm_1_2379_n_fl_cjn		; Hyp.cls 3514
            call #BCD4              ; KL FIND COMMAND: C = its ROM, HL = its address [3515]
            di		; Hyp.cls 3516
            ld a, 2		; Hyp.cls 3517
            jr nc, asm_1_2379_n_fl_un_s		; Hyp.cls 3518
            ld (asm_1_2379_n_fl_cj), hl		; Hyp.cls 3519
            ld a, c		; Hyp.cls 3520
            ld (asm_1_2379_n_fl_cj + 2), a		; Hyp.cls 3521
            ld hl, asm_1_2379_n_FL_MAP		; Hyp.cls 3522
            ld de, asm_1_2379_n_FL_MAP + 1		; Hyp.cls 3523
            ld bc, 511		; Hyp.cls 3524
            ld (hl), 0		; Hyp.cls 3525
            ldir		; Hyp.cls 3526
            ld a, 1		; Hyp.cls 3527
asm_1_2379_n_fl_un_s:		; Hyp.cls 3528
            ld (asm_1_2379_n_fl_cjf), a		; Hyp.cls 3529
            jr asm_1_2379_n_fl_uni		; Hyp.cls 3530
asm_1_2379_n_fl_un_y:		; Hyp.cls 3531
            scf		; Hyp.cls 3532
            ret		; Hyp.cls 3533
; Ctrl J command C (the other registers its input; its output back)
asm_1_2379_n_fl_cjc:		; Hyp.cls 3535
            rst #18                 ; (RST 3: a far call) [3536]
            dw asm_1_2379_n_fl_cj		; Hyp.cls 3537
            di		; Hyp.cls 3538
            ret		; Hyp.cls 3539
; A = a drive letter: HL = its FL_MAP entry, A = its path's length (Z: none). Carry: not A-P,
; or no UniDOS (no paths). A, HL only
asm_1_2379_n_fl_mapa:		; Hyp.cls 3542
            sub 'A'		; Hyp.cls 3543
            cp 16		; Hyp.cls 3544
            ccf		; Hyp.cls 3545
            ret c		; Hyp.cls 3546
            ld l, a		; Hyp.cls 3547
            ld a, (asm_1_2379_n_fl_cjf)		; Hyp.cls 3548
            cp 1		; Hyp.cls 3549
            scf		; Hyp.cls 3550
            ret nz		; Hyp.cls 3551
            ld h, 0		; Hyp.cls 3552
            add hl, hl		; Hyp.cls 3553
            add hl, hl		; Hyp.cls 3554
            add hl, hl		; Hyp.cls 3555
            add hl, hl		; Hyp.cls 3556
            add hl, hl		; Hyp.cls 3557
            ld a, h		; Hyp.cls 3558
            add a, asm_1_2379_n_FL_MAP / 256		; Hyp.cls 3559
            ld h, a		; Hyp.cls 3560
            ld a, (hl)		; Hyp.cls 3561
            or a		; Hyp.cls 3562
            ret		; Hyp.cls 3563
; A = a drive letter: "B:" at DE, or its path - DE past it (BC, HL kept)
asm_1_2379_n_fl_pfx:		; Hyp.cls 3565
            push af		; Hyp.cls 3566
            call asm_1_2379_n_fl_pfxm		; Hyp.cls 3567
            jr nz, asm_1_2379_n_fl_px_d		; Hyp.cls 3568
            pop af		; Hyp.cls 3569
            ld (de), a		; Hyp.cls 3570
            inc de		; Hyp.cls 3571
            ld a, ':'		; Hyp.cls 3572
            ld (de), a		; Hyp.cls 3573
            inc de		; Hyp.cls 3574
            ret		; Hyp.cls 3575
asm_1_2379_n_fl_px_d:		; Hyp.cls 3576
            pop af		; Hyp.cls 3577
            ret		; Hyp.cls 3578
; ... its path only, if it has one (NZ; Z: none, nothing put)
asm_1_2379_n_fl_pfxm:		; Hyp.cls 3580
            push hl		; Hyp.cls 3581
            call asm_1_2379_n_fl_mapa		; Hyp.cls 3582
            jr c, asm_1_2379_n_fl_pm_no		; Hyp.cls 3583
            jr z, asm_1_2379_n_fl_pm_no		; Hyp.cls 3584
            push bc		; Hyp.cls 3585
            ld c, a		; Hyp.cls 3586
            ld b, 0		; Hyp.cls 3587
            inc hl		; Hyp.cls 3588
            ldir		; Hyp.cls 3589
            pop bc		; Hyp.cls 3590
            or a		; Hyp.cls 3591
            jr asm_1_2379_n_fl_pm_r		; Hyp.cls 3592
asm_1_2379_n_fl_pm_no:		; Hyp.cls 3593
            xor a		; Hyp.cls 3594
asm_1_2379_n_fl_pm_r:		; Hyp.cls 3595
            pop hl		; Hyp.cls 3596
            ret		; Hyp.cls 3597
asm_1_2379_n_fl_nlen:                            ; fl_name_s's length: its characters end at DE [3598]
            ld hl, -(asm_1_2379_n_fl_name_s + 1)		; Hyp.cls 3599
            add hl, de		; Hyp.cls 3600
            ld a, l		; Hyp.cls 3601
            ld (asm_1_2379_n_fl_name_s), a		; Hyp.cls 3602
            ret		; Hyp.cls 3603
; the folder whose path is at fl_name_s + 1 to DE (fl_exdir2: fl_name_s, its length set)
; examined (Ctrl J 12): Z its listing ready (examine next: Ctrl J 13), NZ no UniDOS, a drive
; it can't examine (AMSDOS's floppies), not a folder
asm_1_2379_n_fl_exdir:		; Hyp.cls 3607
            call asm_1_2379_n_fl_nlen		; Hyp.cls 3608
asm_1_2379_n_fl_exdir2:		; Hyp.cls 3609
            call asm_1_2379_n_fl_uni		; Hyp.cls 3610
            jr nc, asm_1_2379_n_fl_ed_no		; Hyp.cls 3611
            xor a		; Hyp.cls 3612
            ld (asm_1_2379_n_fl_exv), a		; Hyp.cls 3613
            ld hl, asm_1_2379_n_fl_name_s		; Hyp.cls 3614
            ld b, (hl)		; Hyp.cls 3615
            inc hl		; Hyp.cls 3616
            ld ix, asm_1_2379_n_FL_DATE		; Hyp.cls 3617
            ld c, 12		; Hyp.cls 3618
            call asm_1_2379_n_fl_cjc		; Hyp.cls 3619
            ret c		; Hyp.cls 3620
asm_1_2379_n_fl_ed_no:		; Hyp.cls 3621
            ld a, 254               ; (254: no UniDOS, or a drive it can't examine) [3622]
            or a		; Hyp.cls 3623
            ret		; Hyp.cls 3624
; ---- 30: CP/M's set file attributes - not done here (255) - unless the block at DE (72 bytes)
; is CyborgOS's UniDOS call (CD, DIR): Byte(0) #C0 + the call (an FCB's drive byte is 0-16:
; never that), Byte(1) a drive letter (A-P). 255: no UniDOS (or a bad block). So Main sends it
; here with the other file calls, nothing of its own
;   0  UniDOS here: 0
;   1  the letter's path to Byte(2) (its length - 0 none -, the path)
;   2  the letter's path from Byte(2) (length, 31 at most - a "/" put at its end if it has no
;      "/" or ":" there -; 0: none, the letter itself again): it must be a folder (examined;
;      a drive UniDOS can't examine - DFA:, DFB:, AMSDOS's floppies - is taken as it is):
;      0 set, else UniDOS's error (not 0; 254 a drive it can't examine - a floppy AMSDOS has)
;   3  the devices (Ctrl J 1): 64 bytes at Byte(2) (names, the last character + #80, 255 the end)
;   4  a device (Ctrl J 2): its name at Byte(2) (the last character + #80) - 64 bytes at
;      Byte(8): the status (bit 0 there, 1 folders, 2 read only, 3 removable, 4 a stream, 5
;      the new API), -, free K (4 bytes), all K (4), the description (the last + #80)
;   5  the letter's folder's entry Word(2) (0 the first): Byte(4) its protection bits (bit 0
;      read only, 1 hidden, 2 system, 4 a folder), Byte(5-8) its size, Byte(9-15) its date (year
;      word, month, day, hours, minutes, seconds), Byte(16-26) its name (8 + 3): 0; 1 no more.
;      Byte(1) 0: the folder's path at Byte(28) (length, path) instead. One after another
;      (0, 1, 2 ...) each is the next examined, else the folder is examined again to it
;   6  a folder made: its path at Byte(2) (length, path ending "/": "IDE:GAMES/NEW/"): 0, else
;      UniDOS's error (255 also while a file is being written)
;   7  the header of the file this slot reads (the disc ROM's copy, 69 bytes - UniDOS's made-up
;      one for a file with none: its 24 bit length at 64 #800000) at Byte(2): 0; 255 none open
asm_1_2379_n_fl_unicall:		; Hyp.cls 3648
            ld hl, (var_hyp_filecall_fcb)		; Hyp.cls 3649
            ld de, asm_1_2379_n_FL_UB		; Hyp.cls 3650
            ld b, 72		; Hyp.cls 3651
asm_1_2379_n_fl_uc_in:		; Hyp.cls 3652
            call asm_1_2379_n_fl_peek		; Hyp.cls 3653
            ld (de), a		; Hyp.cls 3654
            inc hl		; Hyp.cls 3655
            inc de		; Hyp.cls 3656
            djnz asm_1_2379_n_fl_uc_in		; Hyp.cls 3657
            ld a, (asm_1_2379_n_FL_UB)		; Hyp.cls 3658
            sub #C0		; Hyp.cls 3659
            cp 9		; Hyp.cls 3660
            jp nc, asm_1_2379_n_fp_done          ; (CP/M's 30) [3661]
            ld (asm_1_2379_n_FL_UB), a		; Hyp.cls 3662
            call asm_1_2379_n_fl_uni		; Hyp.cls 3663
            jp nc, asm_1_2379_n_fp_done		; Hyp.cls 3664
            ld a, (asm_1_2379_n_FL_UB)		; Hyp.cls 3665
            or a		; Hyp.cls 3666
            jp z, asm_1_2379_n_fl_ok		; Hyp.cls 3667
            dec a		; Hyp.cls 3668
            jp z, asm_1_2379_n_fl_uc_get		; Hyp.cls 3669
            dec a		; Hyp.cls 3670
            jp z, asm_1_2379_n_fl_uc_set		; Hyp.cls 3671
            dec a		; Hyp.cls 3672
            jp z, asm_1_2379_n_fl_uc_dev		; Hyp.cls 3673
            dec a		; Hyp.cls 3674
            jp z, asm_1_2379_n_fl_uc_inf		; Hyp.cls 3675
            dec a		; Hyp.cls 3676
            jp z, asm_1_2379_n_fl_uc_dir		; Hyp.cls 3677
            dec a		; Hyp.cls 3678
            jr z, asm_1_2379_n_fl_uc_md		; Hyp.cls 3679
            cp 2		; Hyp.cls 3680
            jr z, asm_1_2379_n_fl_uc_yes		; Hyp.cls 3681
            ld a, (var_hyp_fin)           ; 7: the header of the file this slot reads (the disc ROM's, [3682]
            ld hl, asm_1_2379_n_fl_slot          ; from CAS IN OPEN: 69 bytes) to Byte(2) [3683]
            cp (hl)		; Hyp.cls 3684
            jp nz, asm_1_2379_n_fp_done		; Hyp.cls 3685
            ld hl, (asm_1_2379_n_fl_hdr)		; Hyp.cls 3686
            ld de, asm_1_2379_n_FL_UB + 2		; Hyp.cls 3687
            ld bc, 69		; Hyp.cls 3688
            ldir		; Hyp.cls 3689
            xor a		; Hyp.cls 3690
            ld b, 71		; Hyp.cls 3691
            jp asm_1_2379_n_fl_uc_back		; Hyp.cls 3692
asm_1_2379_n_fl_hdr:     dw 0		; Hyp.cls 3693
asm_1_2379_n_fl_uc_yes:                          ; 8: the next delete (19) may take a folder (RMDIR's) [3694]
            ld a, 1		; Hyp.cls 3695
            ld (asm_1_2379_n_fl_yes), a		; Hyp.cls 3696
            jp asm_1_2379_n_fl_ok		; Hyp.cls 3697
asm_1_2379_n_fl_yes:     db 0		; Hyp.cls 3698
asm_1_2379_n_fl_uc_md:                           ; 6: a folder made (CAS OUT OPEN, the path ending "/") [3699]
            ld a, (var_hyp_fout)		; Hyp.cls 3700
            or a		; Hyp.cls 3701
            jp nz, asm_1_2379_n_fp_done		; Hyp.cls 3702
            ld hl, asm_1_2379_n_FL_UB + 2		; Hyp.cls 3703
            ld a, (hl)		; Hyp.cls 3704
            or a		; Hyp.cls 3705
            jp z, asm_1_2379_n_fp_done		; Hyp.cls 3706
            ld b, a		; Hyp.cls 3707
            inc hl		; Hyp.cls 3708
            ld de, #4800		; Hyp.cls 3709
            call #BC8C              ; CAS OUT OPEN [3710]
            di		; Hyp.cls 3711
            jr nc, asm_1_2379_n_fl_md_nc		; Hyp.cls 3712
            call #BC92              ; (a file: CAS OUT ABANDON - not made) [3713]
            di		; Hyp.cls 3714
            ld a, 1		; Hyp.cls 3715
            jr asm_1_2379_n_fl_md_r		; Hyp.cls 3716
asm_1_2379_n_fl_md_nc:		; Hyp.cls 3717
            and #7F		; Hyp.cls 3718
            cp #17                  ; (DSK_ERR_DIRECTORY_FOUND: made) [3719]
            jp z, asm_1_2379_n_fl_ok		; Hyp.cls 3720
            or a		; Hyp.cls 3721
            jr nz, asm_1_2379_n_fl_md_r		; Hyp.cls 3722
            inc a		; Hyp.cls 3723
asm_1_2379_n_fl_md_r:		; Hyp.cls 3724
            ld (asm_1_2379_n_fl_res), a		; Hyp.cls 3725
            jp asm_1_2379_n_fp_done		; Hyp.cls 3726
asm_1_2379_n_fl_uc_back:                         ; A the answer, the block's first B bytes back to the slot [3727]
            ld (asm_1_2379_n_fl_res), a		; Hyp.cls 3728
            ld a, (asm_1_2379_n_FL_UB)		; Hyp.cls 3729
            add a, #C0		; Hyp.cls 3730
            ld (asm_1_2379_n_FL_UB), a		; Hyp.cls 3731
            ld hl, (var_hyp_filecall_fcb)		; Hyp.cls 3732
            ld de, asm_1_2379_n_FL_UB		; Hyp.cls 3733
asm_1_2379_n_fl_uc_out:		; Hyp.cls 3734
            ld a, (de)		; Hyp.cls 3735
            call asm_1_2379_n_fl_poke		; Hyp.cls 3736
            inc hl		; Hyp.cls 3737
            inc de		; Hyp.cls 3738
            djnz asm_1_2379_n_fl_uc_out		; Hyp.cls 3739
            jp asm_1_2379_n_fp_done		; Hyp.cls 3740
asm_1_2379_n_fl_uc_get:		; Hyp.cls 3741
            ld a, (asm_1_2379_n_FL_UB + 1)		; Hyp.cls 3742
            call asm_1_2379_n_fl_mapa		; Hyp.cls 3743
            jp c, asm_1_2379_n_fp_done		; Hyp.cls 3744
            ld de, asm_1_2379_n_FL_UB + 2		; Hyp.cls 3745
            ld c, (hl)		; Hyp.cls 3746
            ld b, 0		; Hyp.cls 3747
            inc bc		; Hyp.cls 3748
            ldir		; Hyp.cls 3749
            xor a		; Hyp.cls 3750
            ld b, 34		; Hyp.cls 3751
            jr asm_1_2379_n_fl_uc_back		; Hyp.cls 3752
asm_1_2379_n_fl_uc_dev:		; Hyp.cls 3753
            ld de, asm_1_2379_n_FL_UB + 2		; Hyp.cls 3754
            ld c, 1		; Hyp.cls 3755
            call asm_1_2379_n_fl_cjc		; Hyp.cls 3756
            jp nc, asm_1_2379_n_fp_done		; Hyp.cls 3757
            xor a		; Hyp.cls 3758
            ld b, 66		; Hyp.cls 3759
            jr asm_1_2379_n_fl_uc_back		; Hyp.cls 3760
asm_1_2379_n_fl_uc_inf:		; Hyp.cls 3761
            ld hl, asm_1_2379_n_FL_UB + 2		; Hyp.cls 3762
            ld de, asm_1_2379_n_FL_UB + 8		; Hyp.cls 3763
            ld c, 2		; Hyp.cls 3764
            call asm_1_2379_n_fl_cjc		; Hyp.cls 3765
            jp nc, asm_1_2379_n_fp_done		; Hyp.cls 3766
            xor a		; Hyp.cls 3767
            ld b, 72		; Hyp.cls 3768
            jr asm_1_2379_n_fl_uc_back		; Hyp.cls 3769
asm_1_2379_n_fl_uc_set:		; Hyp.cls 3770
            ld a, (asm_1_2379_n_FL_UB + 1)		; Hyp.cls 3771
            call asm_1_2379_n_fl_mapa		; Hyp.cls 3772
            jp c, asm_1_2379_n_fp_done		; Hyp.cls 3773
            ld (asm_1_2379_n_fl_ue), hl		; Hyp.cls 3774
            xor a		; Hyp.cls 3775
            ld (asm_1_2379_n_fl_exv), a		; Hyp.cls 3776
            ld a, (asm_1_2379_n_FL_UB + 2)		; Hyp.cls 3777
            or a		; Hyp.cls 3778
            jr z, asm_1_2379_n_fl_us_put         ; none: the letter itself again [3779]
            cp 32		; Hyp.cls 3780
            jp nc, asm_1_2379_n_fp_done		; Hyp.cls 3781
            ld b, a		; Hyp.cls 3782
            ld hl, asm_1_2379_n_FL_UB + 3		; Hyp.cls 3783
asm_1_2379_n_fl_us_up:                           ; capitals [3784]
            ld a, (hl)		; Hyp.cls 3785
            cp 'a'		; Hyp.cls 3786
            jr c, asm_1_2379_n_fl_us_c		; Hyp.cls 3787
            cp 'z' + 1		; Hyp.cls 3788
            jr nc, asm_1_2379_n_fl_us_c		; Hyp.cls 3789
            sub 32		; Hyp.cls 3790
            ld (hl), a		; Hyp.cls 3791
asm_1_2379_n_fl_us_c:		; Hyp.cls 3792
            inc hl		; Hyp.cls 3793
            djnz asm_1_2379_n_fl_us_up		; Hyp.cls 3794
            dec hl		; Hyp.cls 3795
            ld a, (hl)		; Hyp.cls 3796
            cp ':'		; Hyp.cls 3797
            jr z, asm_1_2379_n_fl_us_ex		; Hyp.cls 3798
            cp '/'		; Hyp.cls 3799
            jr z, asm_1_2379_n_fl_us_ex		; Hyp.cls 3800
            ld a, (asm_1_2379_n_FL_UB + 2)		; Hyp.cls 3801
            cp 31		; Hyp.cls 3802
            jp nc, asm_1_2379_n_fp_done		; Hyp.cls 3803
            inc a		; Hyp.cls 3804
            ld (asm_1_2379_n_FL_UB + 2), a		; Hyp.cls 3805
            inc hl		; Hyp.cls 3806
            ld (hl), '/'		; Hyp.cls 3807
asm_1_2379_n_fl_us_ex:		; Hyp.cls 3808
            ld hl, asm_1_2379_n_FL_UB + 2        ; a folder? [3809]
            ld de, asm_1_2379_n_fl_name_s		; Hyp.cls 3810
            ld bc, 32		; Hyp.cls 3811
            ldir		; Hyp.cls 3812
            call asm_1_2379_n_fl_exdir2		; Hyp.cls 3813
            jr z, asm_1_2379_n_fl_us_put		; Hyp.cls 3814
            cp 254		; Hyp.cls 3815
            jr z, asm_1_2379_n_fl_us_put         ; (a floppy AMSDOS runs - DFA:, DFB: - can't be examined: taken) [3816]
            or a		; Hyp.cls 3817
            jr nz, asm_1_2379_n_fl_us_err		; Hyp.cls 3818
            inc a		; Hyp.cls 3819
asm_1_2379_n_fl_us_err:		; Hyp.cls 3820
            ld (asm_1_2379_n_fl_res), a		; Hyp.cls 3821
            jp asm_1_2379_n_fp_done		; Hyp.cls 3822
asm_1_2379_n_fl_us_put:		; Hyp.cls 3823
            ld hl, asm_1_2379_n_FL_UB + 2		; Hyp.cls 3824
            ld de, (asm_1_2379_n_fl_ue)		; Hyp.cls 3825
            ld bc, 32		; Hyp.cls 3826
            ldir		; Hyp.cls 3827
            jp asm_1_2379_n_fl_ok		; Hyp.cls 3828
asm_1_2379_n_fl_uc_dir:		; Hyp.cls 3829
            ld de, asm_1_2379_n_fl_name_s + 1    ; the folder's path [3830]
            ld a, (asm_1_2379_n_FL_UB + 1)		; Hyp.cls 3831
            or a		; Hyp.cls 3832
            jr z, asm_1_2379_n_fl_ud_p		; Hyp.cls 3833
            call asm_1_2379_n_fl_pfx		; Hyp.cls 3834
            jr asm_1_2379_n_fl_ud_k		; Hyp.cls 3835
asm_1_2379_n_fl_ud_p:		; Hyp.cls 3836
            ld hl, asm_1_2379_n_FL_UB + 28		; Hyp.cls 3837
            ld a, (hl)		; Hyp.cls 3838
            cp 32		; Hyp.cls 3839
            jp nc, asm_1_2379_n_fp_done		; Hyp.cls 3840
            ld c, a		; Hyp.cls 3841
            ld b, 0		; Hyp.cls 3842
            inc hl		; Hyp.cls 3843
            ldir		; Hyp.cls 3844
asm_1_2379_n_fl_ud_k:		; Hyp.cls 3845
            call asm_1_2379_n_fl_nlen		; Hyp.cls 3846
            ld hl, asm_1_2379_n_fl_name_s        ; the same folder, still the one examined, at this entry: [3847]
            ld de, asm_1_2379_n_FL_EXK           ; on from there [3848]
            ld a, (asm_1_2379_n_fl_exv)		; Hyp.cls 3849
            or a		; Hyp.cls 3850
            jr z, asm_1_2379_n_fl_ud_new		; Hyp.cls 3851
            ld a, (hl)		; Hyp.cls 3852
            inc a		; Hyp.cls 3853
            ld b, a		; Hyp.cls 3854
asm_1_2379_n_fl_ud_cmp:		; Hyp.cls 3855
            ld a, (de)		; Hyp.cls 3856
            cp (hl)		; Hyp.cls 3857
            jr nz, asm_1_2379_n_fl_ud_new		; Hyp.cls 3858
            inc hl		; Hyp.cls 3859
            inc de		; Hyp.cls 3860
            djnz asm_1_2379_n_fl_ud_cmp		; Hyp.cls 3861
            ld hl, (asm_1_2379_n_fl_exi)		; Hyp.cls 3862
            ld de, (asm_1_2379_n_FL_UB + 2)		; Hyp.cls 3863
            or a		; Hyp.cls 3864
            sbc hl, de		; Hyp.cls 3865
            jr z, asm_1_2379_n_fl_ud_next		; Hyp.cls 3866
asm_1_2379_n_fl_ud_new:		; Hyp.cls 3867
            ld hl, asm_1_2379_n_fl_name_s		; Hyp.cls 3868
            ld de, asm_1_2379_n_FL_EXK		; Hyp.cls 3869
            ld bc, 32		; Hyp.cls 3870
            ldir		; Hyp.cls 3871
            call asm_1_2379_n_fl_exdir2		; Hyp.cls 3872
            jr z, asm_1_2379_n_fl_ud_ok		; Hyp.cls 3873
            or a		; Hyp.cls 3874
            jr nz, asm_1_2379_n_fl_us_err		; Hyp.cls 3875
            inc a		; Hyp.cls 3876
            jr asm_1_2379_n_fl_us_err		; Hyp.cls 3877
asm_1_2379_n_fl_ud_ok:		; Hyp.cls 3878
            ld hl, 0		; Hyp.cls 3879
            ld (asm_1_2379_n_fl_exi), hl		; Hyp.cls 3880
            ld a, 1		; Hyp.cls 3881
            ld (asm_1_2379_n_fl_exv), a		; Hyp.cls 3882
asm_1_2379_n_fl_ud_skip:                         ; on to entry Word(2) [3883]
            ld hl, (asm_1_2379_n_fl_exi)		; Hyp.cls 3884
            ld de, (asm_1_2379_n_FL_UB + 2)		; Hyp.cls 3885
            or a		; Hyp.cls 3886
            sbc hl, de		; Hyp.cls 3887
            jr z, asm_1_2379_n_fl_ud_next		; Hyp.cls 3888
            ld hl, asm_1_2379_n_FL_TN		; Hyp.cls 3889
            ld ix, asm_1_2379_n_FL_DATE		; Hyp.cls 3890
            ld c, 13		; Hyp.cls 3891
            call asm_1_2379_n_fl_cjc		; Hyp.cls 3892
            jr nc, asm_1_2379_n_fl_ud_end		; Hyp.cls 3893
            jr nz, asm_1_2379_n_fl_ud_end		; Hyp.cls 3894
            ld hl, (asm_1_2379_n_fl_exi)		; Hyp.cls 3895
            inc hl		; Hyp.cls 3896
            ld (asm_1_2379_n_fl_exi), hl		; Hyp.cls 3897
            jr asm_1_2379_n_fl_ud_skip		; Hyp.cls 3898
asm_1_2379_n_fl_ud_next:		; Hyp.cls 3899
            ld hl, asm_1_2379_n_FL_UB + 16		; Hyp.cls 3900
            ld ix, asm_1_2379_n_FL_UB + 9		; Hyp.cls 3901
            ld c, 13		; Hyp.cls 3902
            call asm_1_2379_n_fl_cjc		; Hyp.cls 3903
            jr nc, asm_1_2379_n_fl_ud_end		; Hyp.cls 3904
            jr nz, asm_1_2379_n_fl_ud_end		; Hyp.cls 3905
            ld (asm_1_2379_n_FL_UB + 4), a		; Hyp.cls 3906
            ld (asm_1_2379_n_FL_UB + 5), de		; Hyp.cls 3907
            ld (asm_1_2379_n_FL_UB + 7), bc		; Hyp.cls 3908
            ld hl, (asm_1_2379_n_fl_exi)		; Hyp.cls 3909
            inc hl		; Hyp.cls 3910
            ld (asm_1_2379_n_fl_exi), hl		; Hyp.cls 3911
            xor a		; Hyp.cls 3912
            ld b, 28		; Hyp.cls 3913
            jp asm_1_2379_n_fl_uc_back		; Hyp.cls 3914
asm_1_2379_n_fl_ud_end:		; Hyp.cls 3915
            xor a		; Hyp.cls 3916
            ld (asm_1_2379_n_fl_exv), a		; Hyp.cls 3917
            inc a		; Hyp.cls 3918
            ld (asm_1_2379_n_fl_res), a		; Hyp.cls 3919
            jp asm_1_2379_n_fp_done		; Hyp.cls 3920
asm_1_2379_n_fp_end:		; Hyp.cls 3921
            ASSERT asm_1_2379_n_fp_end <= #6000, "FileCall's page code: below the search's cache (#6000)"		; Hyp.cls 3922
			ENDM
; ============================================================
; NTC program - generated by NTC BASIC (VB style BASIC to NTC)
; platform: cpcfw (Amstrad CPC - firmware text and keys), starts in normal mode
; ============================================================

			DEVICE AMSTRADCPC6128		; for SAVEAMSDOS at the end
			org #0040

NTC_TERM	equ 0		; Option Terminal: 0 none, 1 VT52, 2 ANSI (CP/M)
NTC_STRMAX	equ 255		; the longest string (library buffers, temps)
NTC_MEMBANKS	equ 8		; Option Memory: the most 64K banks the Memory class looks for
NTC_ROMENABLE	equ 1		; Option RomEnable (cpcfw, cpcmin): the start code starts the ROMs
NTC_ROMLIB	equ 1		; 1 = the library is the keyword ROM (Library: ROM; ntcRomAsm builds it)
NTC_WINHOLE	equ 1		; 1 = the program is built round an Option Reserve range over the window #4000-#7FFF
NTC_BUFSIZE	equ 2048		; the library's buffer (ntc_buf: FileSystem, Memory.Copy): Option Buffer
NTC_CPMGFX	equ 0		; 1 = CP/M: Graphics draws on an Amstrad CPC's screen (2.2: #C000, Plus: block 1 from common memory)

ntc_start:
			jr ntc_start2
ntc_bk_sp:		dw 0			; #0042: main RAM's SP while a bank runs
ntc_bk_out:
			out (c), c		; #0044: BC = the other side's RAM setting
			jp ntc_bk_land		; #0046: main RAM switched in
ntc_bk_land:
			ld sp, (ntc_bk_sp)
			ret				; to where main RAM handed over
			ASSERT ntc_bk_out == #0044, "the bank switch must be at #0044"
ntc_start2:
			di
			call ntc_rj_find		; Library: ROM - find the ROM, patch the jump block
			jr nc, ntc_rj_ok
			ei
			ret				; no ROM (the message is shown): back to the caller
ntc_rj_ok:
			di				; (KL ROM SELECT lets interrupts in again)
			ld hl, ntc_rj_exit
			push hl			; End comes back here: the caller's ROM selection again
			ld (ntc_csp), sp
			ld a, (#BC77)		; Option RomEnable: start the ROMs again
			cp #DF			; AMSDOS has the cassette calls: they are running
			jp z, ntc_roms_on
			ei
			ld de, #A5F0		; the lowest address the ROMs may use (the keyword ROM's RAM is below)
			ld hl, #ABFF		; the highest (as usual for AMSDOS: it takes about #A700-#ABFF)
			call #BCCB		; KL ROM WALK: every background ROM
			inc hl			; the first byte the ROMs took
			ld (ntc_roms_at), hl
			ld de, #A600
			or a
			sbc hl, de
			jp nc, ntc_roms_fit	; AMSDOS alone (or no more): as usual
			ld hl, ntc_roms_msg
			call ntc_roms_puts
			ld a, (ntc_roms_at + 1)
			call ntc_roms_hex
			ld a, (ntc_roms_at)
			call ntc_roms_hex
			ld hl, ntc_roms_msg2
			call ntc_roms_puts
			call #BB06		; KM WAIT CHAR
			rst 0			; (the machine starts again)
ntc_roms_puts:
			ld a, (hl)
			or a
			ret z
			call #BB5A		; TXT OUTPUT
			inc hl
			jr ntc_roms_puts
ntc_roms_hex:
			push af
			rrca
			rrca
			rrca
			rrca
			call ntc_roms_dig
			pop af
ntc_roms_dig:
			and 15
			add a, #90
			daa
			adc a, #40
			daa
			jp #BB5A
ntc_roms_at:	dw 0
ntc_roms_msg:	db "The ROMs' RAM reaches down to #", 0
ntc_roms_msg2:	db ": no room for this program", 13, 10, "(fewer ROMs, or a smaller program)", 13, 10, "Press a key", 13, 10, 0
ntc_roms_fit:
			di
			ASSERT ntc_free <= #A600, "Option RomEnable: the program and its arrays must end below #A600 (the ROMs take their RAM from #ABFF down)"
ntc_roms_on:
			ld a, 1
			ld (ntc_nmode), a		; normal mode: waits let interrupts in
			; Option Class Interrupt: the classes' Tick subs, run at safe points (normal mode)
			ld hl, 6		; hot: every 6 interrupts
			ld (ntc_isl + 2), hl
			ld hl, 7			; the first after one period (+ the slot, so they take turns)
			ld (ntc_isl + 0), hl
			ld hl, p_hot_tick_c
			ld (ntc_isl + 6), hl
			ld a, 1
			ld (ntc_isln), a
			ld hl, (ntc_isl_tick + 1)	; (Library: ROM: its address in the ROM - the jump block, low in RAM, is hidden by the lower ROM in the interrupt)
			ld (ntc_irqv), hl		; the interrupt handler counts for them
			ld ix, ntc_go
			jp ntc_plat_irqon		; interrupt handler for normal mode
ntc_go:
			ld sp, main_thread
			ret

			IF ($ < 32768) && (ntc_rg1_e - ntc_rg1 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg1:
; ============================================================
; Main Thread
; ============================================================

main_thread:
			dw kw_bssinit, ntc_bss, ntc_bss_size		; the arrays: do they fit, clear them

			; Main.bas 84: Mode 2
			dw kw_model, 2

			; Main.bas 85: Hyp.Vdu 0                         ' the firmware's text off (TXT VDU DISABLE): AMSDOS says "NAME.CYB not
			dw p_hyp_vdu_c, lit_0

			; Main.bas 89: k = Memory.Banks()
			dw fn_memory_banks, var_k

			; Main.bas 90: If k < 4 Then Hyp.Vdu 1 : Print "CyborgOS needs 320K (a 256K expansion) or more" : End
			dw kw_scpltvl, var_k, 4
			dw kw_goto_iffalse_n, if1_1
			dw p_hyp_vdu_c, lit_1
			dw kw_printstrvar, str0
			dw kw_printnl
			dw kw_printnl0
			dw kw_printstrvar, str1
			dw kw_waitkey
			dw kw_stop
if1_1:

			; Main.bas 91: ns = k \ 2                                      ' half the banks are slots (the first bank never:
			dw kw_divvl, var_k, 2, var_ns

			; Main.bas 92: If ns > MAXS Then ns = MAXS                     ' its pages are the hypervisor's)
			dw kw_scpgtvl, var_ns, 4
			dw kw_goto_iffalse_n, if2_1
			dw kw_ltov, 4, var_ns
if2_1:

			; Main.bas 93: Hot.Slots ns                                    ' (more than 10: Control + a number twice is 11-20)
			dw p_hot_slots_c, var_ns

			; Main.bas 97: i = Memory.AllocPage(Memory.TypeUser)           ' (page 1)
			dw fn_memory_allocpage, lit_85, var_i

			; Main.bas 98: hp = Memory.AllocPage(Memory.TypeUser)          ' bank 1's page 0 (C4): the disc buffers ...
			dw fn_memory_allocpage, lit_85, var_hp

			; Main.bas 99: Memory.SelectPage hp
			dw fn_memory_selectpage, var_hp, var_memory_selectpage_selectpage

			; Main.bas 100: Hyp.UsePage                                     ' (its RAM setting, for Hyp.FileCall)
			dw fn_hyp_usepage

			; Main.bas 101: Hyp.FontInit                                    ' (the font into it, at #5000)
			dw fn_hyp_fontinit

			; Main.bas 109: i = Hyp.FileCall(99, 0, 0, 0, 0, 0, VarPtr(rb))  ' (the bank image and FileCall's page code into it,
			dw p_hyp_filecall_c, lit_99, lit_0, lit_0, lit_0, lit_0, lit_0, vp_arr_rb
			dw kw_vtov, var_hyp_filecall_filecall, var_i

			; Main.bas 116: For i = 1 To ns
			dw kw_ltov, 1, var_i
			dw kw_vtov, var_ns, for3_l
			dw kw_forupv_n, var_i, for3_l, for3_e
for3_t:

			; Main.bas 117: bk(i) = Memory.AllocBank()
			dw fn_memory_allocbank, var_memory_allocbank_allocbank
			dw kw_aset, arr_bk, var_i, var_memory_allocbank_allocbank

			; Main.bas 118: Memory.SelectPage Memory.BankPage(bk(i), 0)
			dw kw_aget, arr_bk, var_i, tmp0
			dw p_memory_bankpage_c, tmp0, lit_0
			dw kw_vtov, var_memory_bankpage_bankpage, tmp0
			dw fn_memory_selectpage, tmp0, var_memory_selectpage_selectpage

			; Main.bas 119: sg(i) = Hyp.Setting()
			dw fn_hyp_setting, var_hyp_setting_setting
			dw kw_aset, arr_sg, var_i, var_hyp_setting_setting

			; Main.bas 120: wp(i) = (sg(i) And &HFFF8) Or 7                ' its page 3 (#C000-#FFFF: OBUF, the console) in the window
			dw kw_aget, arr_sg, var_i, tmp1
			dw kw_andvl, tmp1, -8, tmp1
			dw kw_orvl, tmp1, 7, tmp1
			dw kw_aset, arr_wp, var_i, tmp1

			; Main.bas 122: wk(i) = -1
			dw kw_asetl, arr_wk, var_i, -1

			; Main.bas 128: Next
			dw kw_next1v_n, var_i, for3_l, for3_t
for3_e:

			; Main.bas 131: ob = Space$(82)
			dw kw_strspace, stmp0, lit_82
			dw kw_strcpy, var_ob, stmp0

			; Main.bas 132: front = 1
			dw kw_ltov, 1, var_front

			; Main.bas 133: OpenSlot 1
			dw p_openslot_c, lit_1

			; Main.bas 136: a = ""
			dw kw_strcpy, var_a, str2

			; Main.bas 137: If Peek(&HBE80) = 67 And Peek(&HBE81) = 89 And Peek(&HBE82) = 66 And Peek(&HBE83) = 32 Then
			dw kw_lptrtov8, -16768, tmp0
			dw kw_cpeqvl, tmp0, 67
			dw kw_ftov, tmp0
			dw kw_lptrtov8, -16767, tmp1
			dw kw_cpeqvl, tmp1, 89
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_lptrtov8, -16766, tmp1
			dw kw_cpeqvl, tmp1, 66
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_lptrtov8, -16765, tmp1
			dw kw_cpeqvl, tmp1, 32
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if4_1

			; Main.bas 138: i = &HBE84
			dw kw_ltov, -16764, var_i

			; Main.bas 139: Do While Peek(i) <> 0 And i < &HBEC0
do5_t:
			dw kw_vptrtov8, var_i, tmp0
			dw kw_cpnevl, tmp0, 0
			dw kw_ftov, tmp0
			dw kw_scpltvl, var_i, -16704
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, do5_e

			; Main.bas 140: a = a + Chr$(Peek(i))
			dw kw_vptrtov8, var_i, tmp1
			dw kw_strchr, stmp1, tmp1
			dw kw_strcat, var_a, stmp1

			; Main.bas 141: i = i + 1
			dw kw_inc, var_i

			; Main.bas 142: Loop
			dw do5_t_go
do5_e:

			; Main.bas 143: a = UCase$(a)
			dw kw_strucase, stmp0, var_a
			dw kw_strcpy, var_a, stmp0

			; Main.bas 144: End If
if4_1:

			; Main.bas 145: i = InStr(a, " KEYREP ")
			dw kw_strinstr, lit_1, var_a, str3, var_i

			; Main.bas 146: If i > 0 Then
			dw kw_scpgtvl, var_i, 0
			dw kw_goto_iffalse_n, if6_1

			; Main.bas 147: k = Val(Mid$(a, i + 8))
			dw kw_addl, var_i, 8, tmp1
			dw kw_strmid, stmp0, var_a, tmp1, lit_255
			dw kw_strval, stmp0, var_k

			; Main.bas 148: If k > 1 Then Hyp.KeyRep k : Hot.Speed k             ' (the double tap's time too: real time, not ticks)
			dw kw_scpgtvl, var_k, 1
			dw kw_goto_iffalse_n, if7_1
			dw p_hyp_keyrep_c, var_k
			dw p_hot_speed_c, var_k
if7_1:

			; Main.bas 149: End If
if6_1:

			; Main.bas 172: Do
do8_t:

			; Main.bas 173: hk = Hot.Take()
			dw p_hot_take_c
			dw kw_vtov, var_hot_take_take, var_hk

			; Main.bas 174: If hk = Hot.TOPKEY Then
			dw kw_cpeqvl, var_hk, 99
			dw kw_goto_iffalse_n, if9_1

			; Main.bas 175: If front = 0 Then ToFront back Else ShowTop      ' Control + ESC: TOP, and again: back
			dw kw_cpeqvl, var_front, 0
			dw kw_goto_iffalse_n, if10_1
			dw p_tofront_c, var_back
			dw if9_e_go
if10_1:
			dw p_showtop_c
if10_e:

			; Main.bas 176: ElseIf hk > 0 And hk <= ns Then
			dw if9_e_go
if9_1:
			dw kw_scpgtvl, var_hk, 0
			dw kw_ftov, tmp0
			dw kw_scplevv, var_hk, var_ns
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if9_2

			; Main.bas 177: ToFront hk
			dw p_tofront_c, var_hk

			; Main.bas 178: End If
if9_2:
if9_e:

			; Main.bas 179: If pk <> 0 And wt = 0 Then                    ' (a key left by a program: after WAIT's prompt)
			dw kw_cpnevl, var_pk, 0
			dw kw_ftov, tmp0
			dw kw_cpeqvl, var_wt, 0
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if11_1

			; Main.bas 180: k = pk : pk = 0
			dw kw_vtov, var_pk, var_k
			dw kw_ztov, var_pk

			; Main.bas 181: KeyIn k
			dw p_keyin_c, var_k

			; Main.bas 182: ElseIf wt = 0 Then
			dw if11_e_go
if11_1:
			dw kw_cpeqvl, var_wt, 0
			dw kw_goto_iffalse_n, if11_2

			; Main.bas 184: If front = 0 Or st(front) <> 2 Or kq(front) = 0 Then
			dw kw_cpeqvl, var_front, 0
			dw kw_ftov, tmp0
			dw kw_aget, arr_st, var_front, tmp1
			dw kw_cpnevl, tmp1, 2
			dw kw_ftov, tmp1
			dw kw_orvv, tmp0, tmp1, tmp0
			dw kw_aget, arr_kq, var_front, tmp1
			dw kw_cpeqvl, tmp1, 0
			dw kw_ftov, tmp1
			dw kw_orvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if11_e

			; Main.bas 185: k = Inkey
			dw kw_inkey, tmp0
			dw kw_vtov, tmp0, var_k

			; Main.bas 186: If k <> 0 And (Hot.Control() = 0 Or (k < 32 And Hot.Held() = 0)) Then KeyIn k   ' (Control + a letter: the program's)
			dw kw_cpnevl, var_k, 0
			dw kw_ftov, tmp0
			dw p_hot_control_c
			dw kw_vtov, var_hot_control_control, tmp1
			dw kw_cpeqvl, tmp1, 0
			dw kw_ftov, tmp1
			dw kw_scpltvl, var_k, 32
			dw kw_ftov, tmp2
			dw p_hot_held_c
			dw kw_vtov, var_hot_held_held, tmp3
			dw kw_cpeqvl, tmp3, 0
			dw kw_ftov, tmp3
			dw kw_andvv, tmp2, tmp3, tmp2
			dw kw_orvv, tmp1, tmp2, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if11_e
			dw p_keyin_c, var_k
if13_1:

			; Main.bas 187: End If
if12_1:

			; Main.bas 188: ElseIf Running() = 0 Then
			dw if11_e_go
if11_2:
			dw p_running_c
			dw kw_vtov, var_running_running, tmp0
			dw kw_cpeqvl, tmp0, 0
			dw kw_goto_iffalse_n, if11_3

			; Main.bas 189: Prompt wt : wt = 0          ' WAIT: nothing runs any more
			dw p_prompt_c, var_wt
			dw kw_ztov, var_wt

			; Main.bas 190: End If
if11_3:
if11_e:

			; Main.bas 191: If Ticks - td >= 300 Then Roll
			dw kw_ticks, tmp0
			dw kw_subvv, tmp0, var_td, tmp0
			dw kw_scpgevl, tmp0, 300
			dw kw_goto_iffalse_n, if14_1
			dw p_roll_c
if14_1:

			; Main.bas 192: If front <> 0 Then
			dw kw_cpnevl, var_front, 0
			dw kw_goto_iffalse_n, if15_1

			; Main.bas 193: If Ticks - tc >= 150 Then tc = Ticks : Hyp.Con wp(front), 0, -3, 1   ' the cursor flashes (0.5 s)
			dw kw_ticks, tmp0
			dw kw_subvv, tmp0, var_tc, tmp0
			dw kw_scpgevl, tmp0, 150
			dw kw_goto_iffalse_n, if16_1
			dw kw_ticks, tmp0
			dw kw_vtov, tmp0, var_tc
			dw kw_aget, arr_wp, var_front, tmp0
			dw p_hyp_con_c, tmp0, lit_0, lit_m3, lit_1
if16_1:

			; Main.bas 194: End If
if15_1:

			; Main.bas 195: RunNext
			dw p_runnext_c

			; Main.bas 196: Loop Until quit
			dw kw_goto_ifzero_n, var_quit, do8_t
do8_e:

			; Main.bas 197: i = Hyp.Scr(0, 2)                 ' the CRTC as the firmware has it (80 x 25)
			dw p_hyp_scr_c, lit_0, lit_2
			dw kw_vtov, var_hyp_scr_scr, var_i

			; Main.bas 198: Hyp.Vdu 1
			dw p_hyp_vdu_c, lit_1

			; Main.bas 199: Mode 1
			dw kw_model, 1

			; Main.bas 200: Print "CyborgOS ended, "; runs; " programs ran"
			dw kw_printstrvar, str4
			dw kw_printint, var_runs
			dw kw_printstrvar, str5
			dw kw_printnl

			; Main.bas 201: End
			dw kw_printnl0
			dw kw_printstrvar, str1
			dw kw_waitkey
			dw kw_stop

ntc_rg1_e:
			IF ($ < 32768) && (ntc_rg2_e - ntc_rg2 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg2:
; ============================================================
; function running (normal mode)
; ============================================================

p_running:

			; Main.bas 205: Dim j As Integer

			; Main.bas 206: For j = 1 To ns
			dw kw_ltov, 1, var_running_j
			dw kw_vtov, var_ns, for17_l
			dw kw_forupv_n, var_running_j, for17_l, for17_e
for17_t:

			; Main.bas 207: If st(j) = 2 Then Running = Running + 1
			dw kw_aget, arr_st, var_running_j, tmp0
			dw kw_cpeqvl, tmp0, 2
			dw kw_goto_iffalse_n, if18_1
			dw kw_inc, var_running_running
if18_1:

			; Main.bas 208: Next
			dw kw_next1v_n, var_running_j, for17_l, for17_t
for17_e:
			dw p_running_r

ntc_rg2_e:
			IF ($ < 32768) && (ntc_rg3_e - ntc_rg3 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg3:
; ============================================================
; function ready (normal mode)
; ============================================================

p_ready:

			; Main.bas 214: Ready = 0
			dw kw_ztov, var_ready_ready

			; Main.bas 215: If t < 1 Then Exit Function
			dw kw_scpltvl, var_ready_t, 1
			dw kw_goto_iffalse_n, if19_1
			dw p_ready_r
if19_1:

			; Main.bas 216: If st(t) <> 2 Then Exit Function
			dw kw_aget, arr_st, var_ready_t, tmp0
			dw kw_cpnevl, tmp0, 2
			dw kw_goto_iffalse_n, if20_1
			dw p_ready_r
if20_1:

			; Main.bas 217: If wk(t) = Ticks And kq(t) = 0 Then Exit Function
			dw kw_aget, arr_wk, var_ready_t, tmp0
			dw kw_ticks, tmp1
			dw kw_cpeqvv, tmp0, tmp1
			dw kw_ftov, tmp0
			dw kw_aget, arr_kq, var_ready_t, tmp1
			dw kw_cpeqvl, tmp1, 0
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if21_1
			dw p_ready_r
if21_1:

			; Main.bas 218: Ready = -1
			dw kw_ltov, -1, var_ready_ready
			dw p_ready_r

ntc_rg3_e:
			IF ($ < 32768) && (ntc_rg4_e - ntc_rg4 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg4:
; ============================================================
; sub runnext (normal mode)
; ============================================================

p_runnext:

			; Main.bas 223: Dim n As Integer, t As Integer, r As Integer, c As Integer, q As Integer

			; Main.bas 224: fr = Not fr
			dw kw_notv, var_fr, var_fr

			; Main.bas 225: If fr Then
			dw kw_goto_ifzero_n, var_fr, if22_1

			; Main.bas 226: If Ready(front) Then t = front
			dw p_ready_c, var_front
			dw kw_goto_ifzero_n, var_ready_ready, if23_1
			dw kw_vtov, var_front, var_runnext_t
if23_1:

			; Main.bas 227: End If
if22_1:

			; Main.bas 228: If t = 0 Then
			dw kw_cpeqvl, var_runnext_t, 0
			dw kw_goto_iffalse_n, if24_1

			; Main.bas 229: For n = 1 To ns
			dw kw_ltov, 1, var_runnext_n
			dw kw_vtov, var_ns, for25_l
			dw kw_forupv_n, var_runnext_n, for25_l, for25_e
for25_t:

			; Main.bas 230: cur = cur + 1
			dw kw_inc, var_cur

			; Main.bas 231: If cur > ns Then cur = 1
			dw kw_scpgtvv, var_cur, var_ns
			dw kw_goto_iffalse_n, if26_1
			dw kw_ltov, 1, var_cur
if26_1:

			; Main.bas 232: If cur <> front Then
			dw kw_cpnevv, var_cur, var_front
			dw kw_goto_iffalse_n, if27_1

			; Main.bas 233: If Ready(cur) Then t = cur : Exit For
			dw p_ready_c, var_cur
			dw kw_goto_ifzero_n, var_ready_ready, if28_1
			dw kw_vtov, var_cur, var_runnext_t
			dw for25_e_go
if28_1:

			; Main.bas 234: End If
if27_1:

			; Main.bas 235: Next
			dw kw_next1v_n, var_runnext_n, for25_l, for25_t
for25_e:

			; Main.bas 236: End If
if24_1:

			; Main.bas 237: If t = 0 Then
			dw kw_cpeqvl, var_runnext_t, 0
			dw kw_goto_iffalse_n, if29_1

			; Main.bas 238: If Ready(front) Then t = front
			dw p_ready_c, var_front
			dw kw_goto_ifzero_n, var_ready_ready, if30_1
			dw kw_vtov, var_front, var_runnext_t
if30_1:

			; Main.bas 239: End If
if29_1:

			; Main.bas 240: If t = 0 Then
			dw kw_cpeqvl, var_runnext_t, 0
			dw kw_goto_iffalse_n, if31_1

			; Main.bas 241: If Running() = 0 Then Frame     ' nothing to run: wait a frame (a program waiting for a
			dw p_running_c
			dw kw_vtov, var_running_running, tmp0
			dw kw_cpeqvl, tmp0, 0
			dw kw_goto_iffalse_n, if32_1
			dw kw_frame
if32_1:

			; Main.bas 242: Exit Sub                        ' key looks again when the clock moves on)
			dw p_runnext_r

			; Main.bas 243: End If
if31_1:

			; Main.bas 244: n = 0
			dw kw_ztov, var_runnext_n

			; Main.bas 245: Do
do33_t:

			; Main.bas 246: Hyp.Reply ra(t), ra(t)
			dw kw_aget, arr_ra, var_runnext_t, tmp0
			dw kw_aget, arr_ra, var_runnext_t, tmp1
			dw p_hyp_reply_c, tmp0, tmp1

			; Main.bas 247: r = Hyp.Run(sg(t))
			dw kw_aget, arr_sg, var_runnext_t, tmp0
			dw p_hyp_run_c, tmp0
			dw kw_vtov, var_hyp_run_run, var_runnext_r

			; Main.bas 248: tn(t) = tn(t) + 1
			dw kw_aget, arr_tn, var_runnext_t, tmp1
			dw kw_inc, tmp1
			dw kw_aset, arr_tn, var_runnext_t, tmp1

			; Main.bas 249: If kq(t) <> 0 Then
			dw kw_aget, arr_kq, var_runnext_t, tmp0
			dw kw_cpnevl, tmp0, 0
			dw kw_goto_iffalse_n, if34_1

			; Main.bas 250: If Memory.ReadByte(Far(t, Hyp.KEY)) = 0 Then kq(t) = 0     ' the program took its key
			dw p_far_c, var_runnext_t, lit_m2431
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_readbyte, ltmp0, var_memory_readbyte_readbyte
			dw kw_vtov, var_memory_readbyte_readbyte, tmp0
			dw kw_cpeqvl, tmp0, 0
			dw kw_goto_iffalse_n, if35_1
			dw kw_asetl, arr_kq, var_runnext_t, 0
if35_1:

			; Main.bas 251: End If
if34_1:

			; Main.bas 252: c = Hyp.Count()
			dw p_hyp_count_c
			dw kw_vtov, var_hyp_count_count, var_runnext_c

			; Main.bas 253: If c > 0 Then Collected t, c
			dw kw_scpgtvl, var_runnext_c, 0
			dw kw_goto_iffalse_n, if36_1
			dw p_collected_c, var_runnext_t, var_runnext_c
if36_1:

			; Main.bas 254: If r = 0 Then
			dw kw_cpeqvl, var_runnext_r, 0
			dw kw_goto_iffalse_n, if37_1

			; Main.bas 258: q = q + 1
			dw kw_inc, var_runnext_q

			; Main.bas 259: If q >= TURNS Then Exit Do
			dw kw_scpgevl, var_runnext_q, 3
			dw kw_goto_iffalse_n, do33_t
			dw do33_e_go
if38_1:

			; Main.bas 260: ElseIf r <> 1 Then
			dw do33_t_go
if37_1:
			dw kw_cpnevl, var_runnext_r, 1
			dw kw_goto_iffalse_n, if37_2

			; Main.bas 261: Exit Do
			dw do33_e_go

			; Main.bas 262: Else
if37_2:

			; Main.bas 263: c = Hyp.Fn()
			dw p_hyp_fn_c
			dw kw_vtov, var_hyp_fn_fn, var_runnext_c

			; Main.bas 264: Bdos t
			dw p_bdos_c, var_runnext_t

			; Main.bas 269: n = n + 1
			dw kw_inc, var_runnext_n

			; Main.bas 270: If c = 131 Or c = 128 Then c = 13
			dw kw_cpeqvl, var_runnext_c, 131
			dw kw_ftov, tmp0
			dw kw_cpeqvl, var_runnext_c, 128
			dw kw_ftov, tmp1
			dw kw_orvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if39_1
			dw kw_ltov, 13, var_runnext_c
if39_1:

			; Main.bas 271: If c < 13 Or c > 36 Or n >= 32 Or st(t) <> 2 Or wk(t) <> -1 Then Exit Do   ' (asleep: a port's wait)
			dw kw_scpltvl, var_runnext_c, 13
			dw kw_ftov, tmp0
			dw kw_scpgtvl, var_runnext_c, 36
			dw kw_ftov, tmp1
			dw kw_orvv, tmp0, tmp1, tmp0
			dw kw_scpgevl, var_runnext_n, 32
			dw kw_ftov, tmp1
			dw kw_orvv, tmp0, tmp1, tmp0
			dw kw_aget, arr_st, var_runnext_t, tmp1
			dw kw_cpnevl, tmp1, 2
			dw kw_ftov, tmp1
			dw kw_orvv, tmp0, tmp1, tmp0
			dw kw_aget, arr_wk, var_runnext_t, tmp1
			dw kw_cpnevl, tmp1, -1
			dw kw_ftov, tmp1
			dw kw_orvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, do33_t
			dw do33_e_go
if40_1:

			; Main.bas 272: End If
if37_e:

			; Main.bas 273: Loop
			dw do33_t_go
do33_e:
			dw p_runnext_r

ntc_rg4_e:
			IF ($ < 32768) && (ntc_rg5_e - ntc_rg5 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg5:
; ============================================================
; sub bdos (normal mode)
; ============================================================

p_bdos:

			; Main.bas 278: Dim f As Integer, e As Integer, a As Integer

			; Main.bas 279: f = Hyp.Fn() : e = Hyp.Arg() And 255 : a = 0
			dw p_hyp_fn_c
			dw kw_vtov, var_hyp_fn_fn, var_bdos_f
			dw p_hyp_arg_c
			dw kw_vtov, var_hyp_arg_arg, tmp0
			dw kw_andvl, tmp0, 255, var_bdos_e
			dw kw_ztov, var_bdos_a

			; Main.bas 280: nb(t) = nb(t) + 1
			dw kw_aget, arr_nb, var_bdos_t, tmp1
			dw kw_inc, tmp1
			dw kw_aset, arr_nb, var_bdos_t, tmp1

			; Main.bas 281: wk(t) = -1
			dw kw_asetl, arr_wk, var_bdos_t, -1

			; Main.bas 282: If f = 40 Then f = 34           ' write random with zero fill: as 34
			dw kw_cpeqvl, var_bdos_f, 40
			dw kw_goto_iffalse_n, if41_1
			dw kw_ltov, 34, var_bdos_f
if41_1:

			; Main.bas 283: Select Case f
			dw kw_vtov, var_bdos_f, var_bdos___sel42

			; Main.bas 284: Case 0
			dw kw_cpeqvl, var_bdos___sel42, 0
			dw kw_goto_iffalse_n, sel42_1
sel42_b1:

			; Main.bas 285: EndTask t
			dw p_endtask_c, var_bdos_t

			; Main.bas 286: Exit Sub
			dw p_bdos_r

			; Main.bas 307: Case 12
sel42_1:
			dw kw_cpeqvl, var_bdos___sel42, 12
			dw kw_goto_iffalse_n, sel42_2
sel42_b2:

			; Main.bas 308: a = &H22                    ' CP/M 2.2
			dw kw_ltov, 34, var_bdos_a

			; Main.bas 309: Case 13, 32                   ' reset the discs; user number: nothing to do here
			dw sel42_e_go
sel42_2:
			dw kw_cpeqvl, var_bdos___sel42, 13
			dw kw_goto_iftrue_n, sel42_b3
			dw kw_cpeqvl, var_bdos___sel42, 32
			dw kw_goto_iffalse_n, sel42_3
sel42_b3:

			; Main.bas 310: a = 0
			dw kw_ztov, var_bdos_a

			; Main.bas 311: Case 14                       ' select a disc: the slot's drive (as CD)
			dw sel42_e_go
sel42_3:
			dw kw_cpeqvl, var_bdos___sel42, 14
			dw kw_goto_iffalse_n, sel42_4
sel42_b4:

			; Main.bas 316: Case 25
			dw sel42_e_go
sel42_4:
			dw kw_cpeqvl, var_bdos___sel42, 25
			dw kw_goto_iffalse_n, sel42_5
sel42_b5:

			; Main.bas 318: a = 0
			dw kw_ztov, var_bdos_a

			; Main.bas 322: Case 26                       ' the DMA address (CP/M's record buffer)
			dw sel42_e_go
sel42_5:
			dw kw_cpeqvl, var_bdos___sel42, 26
			dw kw_goto_iffalse_n, sel42_6
sel42_b6:

			; Main.bas 323: dm(t) = Hyp.Arg()
			dw p_hyp_arg_c
			dw kw_aset, arr_dm, var_bdos_t, var_hyp_arg_arg

			; Main.bas 324: Case 24                       ' the login vector: the slot's drive
			dw sel42_e_go
sel42_6:
			dw kw_cpeqvl, var_bdos___sel42, 24
			dw kw_goto_iffalse_n, sel42_7
sel42_b7:

			; Main.bas 326: a = 1
			dw kw_ltov, 1, var_bdos_a

			; Main.bas 335: Case 15 To 36                 ' files: Hyp.FileCall
			dw sel42_e_go
sel42_7:
			dw kw_scpltvl, var_bdos___sel42, 15
			dw kw_goto_iftrue_n, sel42_8
			dw kw_scplevl, var_bdos___sel42, 36
			dw kw_goto_iffalse_n, sel42_8
sel42_b8:

			; Main.bas 337: a = Hyp.FileCall(f, Hyp.Arg(), t, sg(t), dm(t), 0, VarPtr(rb))
			dw p_hyp_arg_c
			dw kw_vtov, var_hyp_arg_arg, tmp1
			dw kw_aget, arr_sg, var_bdos_t, tmp3
			dw kw_aget, arr_dm, var_bdos_t, tmp4
			dw p_hyp_filecall_c, var_bdos_f, tmp1, var_bdos_t, tmp3, tmp4, lit_0, vp_arr_rb
			dw kw_vtov, var_hyp_filecall_filecall, var_bdos_a

			; Main.bas 346: Case 131                      ' CyborgOS's own commands (PS, KILL, MEM ...)
			dw sel42_e_go
sel42_8:
			dw kw_cpeqvl, var_bdos___sel42, 131
			dw kw_goto_iffalse_n, sel42_9
sel42_b9:

			; Main.bas 347: a = Sys(t, Hyp.Arg())
			dw p_hyp_arg_c
			dw kw_vtov, var_hyp_arg_arg, tmp1
			dw p_sys_c, var_bdos_t, tmp1
			dw kw_vtov, var_sys_sys, var_bdos_a

			; Main.bas 348: Case 128
			dw sel42_e_go
sel42_9:
			dw kw_cpeqvl, var_bdos___sel42, 128
			dw kw_goto_iffalse_n, sel42_10
sel42_b10:

			; Main.bas 350: Case 129                      ' the stub's key wait (BDOS 1, 10, BIOS CONIN): sleep till a key
			dw sel42_e_go
sel42_10:
			dw kw_cpeqvl, var_bdos___sel42, 129
			dw kw_goto_iffalse_n, sel42_11
sel42_b11:

			; Main.bas 351: If kq(t) = 0 Then wk(t) = Ticks
			dw kw_aget, arr_kq, var_bdos_t, tmp0
			dw kw_cpeqvl, tmp0, 0
			dw kw_goto_iffalse_n, sel42_e
			dw kw_ticks, tmp1
			dw kw_aset, arr_wk, var_bdos_t, tmp1
if43_1:

			; Main.bas 352: Case Else
			dw sel42_e_go
sel42_11:

			; Main.bas 353: a = 255
			dw kw_ltov, 255, var_bdos_a

			; Main.bas 354: End Select
sel42_e:

			; Main.bas 355: ra(t) = a
			dw kw_aset, arr_ra, var_bdos_t, var_bdos_a
			dw p_bdos_r

ntc_rg5_e:
			IF ($ < 32768) && (ntc_rg6_e - ntc_rg6 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg6:
; ============================================================
; function sys (normal mode)
; ============================================================

p_sys:

			; Main.bas 467: Dim o As Integer, s As Integer, d As Integer

			; Main.bas 468: o = Memory.ReadByte(Far(t, p)) : s = Memory.ReadByte(Far(t, p + 1))
			dw p_far_c, var_sys_t, var_sys_p
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_readbyte, ltmp0, var_sys_o
			dw kw_addl, var_sys_p, 1, tmp1
			dw p_far_c, var_sys_t, tmp1
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_readbyte, ltmp0, var_sys_s

			; Main.bas 469: If o = 4 Then
			dw kw_cpeqvl, var_sys_o, 4
			dw kw_goto_iffalse_n, if44_1

			; Main.bas 470: If Running() > 1 Then wt = t
			dw p_running_c
			dw kw_vtov, var_running_running, tmp0
			dw kw_scpgtvl, tmp0, 1
			dw kw_goto_iffalse_n, if45_1
			dw kw_vtov, var_sys_t, var_wt
if45_1:

			; Main.bas 471: Exit Function
			dw p_sys_r

			; Main.bas 472: ElseIf o = 6 Then
if44_1:
			dw kw_cpeqvl, var_sys_o, 6
			dw kw_goto_iffalse_n, if44_2

			; Main.bas 473: txs = t
			dw kw_vtov, var_sys_t, var_txs

			; Main.bas 474: TopLines front, 0
			dw p_toplines_c, var_front, lit_0

			; Main.bas 475: Exit Function
			dw p_sys_r

			; Main.bas 476: ElseIf o = 9 Then                               ' MODE: s 0-4 this slot's mode (its console
if44_2:
			dw kw_cpeqvl, var_sys_o, 9
			dw kw_goto_iffalse_n, if44_3

			; Main.bas 477: If s = 255 Then Sys = Memory.ReadByte(Far(t, Hyp.CMODE)) : Exit Function   ' cleared), 255: which
			dw kw_cpeqvl, var_sys_s, 255
			dw kw_goto_iffalse_n, if46_1
			dw p_far_c, var_sys_t, lit_m2423
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_readbyte, ltmp0, var_sys_sys
			dw p_sys_r
if46_1:

			; Main.bas 478: If s > 5 Then Sys = 255 : Exit Function                                     ' it is
			dw kw_scpgtvl, var_sys_s, 5
			dw kw_goto_iffalse_n, if47_1
			dw kw_ltov, 255, var_sys_sys
			dw p_sys_r
if47_1:

			; Main.bas 479: SetMode t, s
			dw p_setmode_c, var_sys_t, var_sys_s

			; Main.bas 480: Exit Function
			dw p_sys_r

			; Main.bas 505: End If
if44_3:
if44_e:

			; Main.bas 506: If o = 2 And s = 0 Then s = t
			dw kw_cpeqvl, var_sys_o, 2
			dw kw_ftov, tmp0
			dw kw_cpeqvl, var_sys_s, 0
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if48_1
			dw kw_vtov, var_sys_t, var_sys_s
if48_1:

			; Main.bas 507: Sys = 255
			dw kw_ltov, 255, var_sys_sys

			; Main.bas 508: If s < 1 Or s > ns Then Exit Function
			dw kw_scpltvl, var_sys_s, 1
			dw kw_ftov, tmp0
			dw kw_scpgtvv, var_sys_s, var_ns
			dw kw_ftov, tmp1
			dw kw_orvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if49_1
			dw p_sys_r
if49_1:

			; Main.bas 509: Sys = 0
			dw kw_ztov, var_sys_sys

			; Main.bas 510: If o = 0 Then
			dw kw_cpeqvl, var_sys_o, 0
			dw kw_goto_iffalse_n, if50_1

			; Main.bas 511: Memory.WriteByte Far(t, p + 2), st(s)
			dw kw_addl, var_sys_p, 2, tmp1
			dw p_far_c, var_sys_t, tmp1
			dw kw_l_mov, var_far_far, ltmp0
			dw kw_aget, arr_st, var_sys_s, tmp1
			dw fn_memory_writebyte, ltmp0, tmp1

			; Main.bas 512: Memory.WriteByte Far(t, p + 3), IIf(s = front, 1, 0)
			dw kw_addl, var_sys_p, 3, tmp1
			dw p_far_c, var_sys_t, tmp1
			dw kw_l_mov, var_far_far, ltmp0
			dw kw_cpeqvv, var_sys_s, var_front
			dw kw_ftov, tmp1
			dw kw_goto_ifzero_n, tmp1, ch51_0
			dw kw_ltov, 1, tmp1
			dw ch51_e_go
ch51_0:
			dw kw_ztov, tmp1
			dw ch51_e_go
ch51_1:
			dw kw_ztov, tmp1
ch51_e:
			dw fn_memory_writebyte, ltmp0, tmp1

			; Main.bas 513: en = ""
			dw kw_strcpy, var_en, str2

			; Main.bas 514: If st(s) = 2 Then GetNm s
			dw kw_aget, arr_st, var_sys_s, tmp0
			dw kw_cpeqvl, tmp0, 2
			dw kw_goto_iffalse_n, if52_1
			dw p_getnm_c, var_sys_s
if52_1:

			; Main.bas 515: PutEn t, p + 4
			dw kw_addl, var_sys_p, 4, tmp1
			dw p_puten_c, var_sys_t, tmp1

			; Main.bas 516: ElseIf o = 1 Then
			dw if50_e_go
if50_1:
			dw kw_cpeqvl, var_sys_o, 1
			dw kw_goto_iffalse_n, if50_2

			; Main.bas 517: If st(s) = 2 Then EndTask s Else Sys = 1
			dw kw_aget, arr_st, var_sys_s, tmp0
			dw kw_cpeqvl, tmp0, 2
			dw kw_goto_iffalse_n, if53_1
			dw p_endtask_c, var_sys_s
			dw if50_e_go
if53_1:
			dw kw_ltov, 1, var_sys_sys
if53_e:

			; Main.bas 518: ElseIf o = 2 Then
			dw if50_e_go
if50_2:
			dw kw_cpeqvl, var_sys_o, 2
			dw kw_goto_iffalse_n, if50_3

			; Main.bas 519: ResetSlot s
			dw p_resetslot_c, var_sys_s

			; Main.bas 520: If s = t Then Prompt t                       ' (RESET of its own slot: the program gone)
			dw kw_cpeqvv, var_sys_s, var_sys_t
			dw kw_goto_iffalse_n, if50_e
			dw p_prompt_c, var_sys_t
if54_1:

			; Main.bas 521: ElseIf o = 3 Then
			dw if50_e_go
if50_3:
			dw kw_cpeqvl, var_sys_o, 3
			dw kw_goto_iffalse_n, if50_4

			; Main.bas 522: ToFront s
			dw p_tofront_c, var_sys_s

			; Main.bas 523: End If
if50_4:
if50_e:
			dw p_sys_r

ntc_rg6_e:
			IF ($ < 32768) && (ntc_rg7_e - ntc_rg7 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg7:
; ============================================================
; sub puten (normal mode)
; ============================================================

p_puten:

			; Main.bas 528: Memory.WriteByte Far(t, a), Len(en)
			dw p_far_c, var_puten_t, var_puten_a
			dw kw_l_mov, var_far_far, ltmp0
			dw kw_strlen, var_en, tmp1
			dw fn_memory_writebyte, ltmp0, tmp1

			; Main.bas 529: Memory.Copy NearP(VarPtr(en)), Far(t, a + 1), Len(en)
			dw p_nearp_c, vp_var_en
			dw kw_l_mov, var_nearp_nearp, ltmp0
			dw kw_addl, var_puten_a, 1, tmp2
			dw p_far_c, var_puten_t, tmp2
			dw kw_l_mov, var_far_far, ltmp1
			dw kw_strlen, var_en, tmp2
			dw fn_memory_copy, ltmp0, ltmp1, tmp2, var_memory_copy_copy
			dw p_puten_r

ntc_rg7_e:
			IF ($ < 32768) && (ntc_rg8_e - ntc_rg8 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg8:
; ============================================================
; function hopen (normal mode)
; ============================================================

p_hopen:

			; Main.bas 535: HOpen = (Hyp.FileCall(100, VarPtr(dn), 0, 0, Len(dn), 0, 0) = 0)
			dw kw_strlen, var_dn, tmp4
			dw p_hyp_filecall_c, lit_100, vp_var_dn, lit_0, lit_0, tmp4, lit_0, lit_0
			dw kw_vtov, var_hyp_filecall_filecall, tmp0
			dw kw_cpeqvl, tmp0, 0
			dw kw_ftov, var_hopen_hopen
			dw p_hopen_r

ntc_rg8_e:
			IF ($ < 32768) && (ntc_rg9_e - ntc_rg9 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg9:
; ============================================================
; sub hclose (normal mode)
; ============================================================

p_hclose:

			; Main.bas 541: Dim r As Integer

			; Main.bas 542: r = Hyp.FileCall(102, 0, 0, 0, 0, 0, 0)
			dw p_hyp_filecall_c, lit_102, lit_0, lit_0, lit_0, lit_0, lit_0, lit_0
			dw kw_vtov, var_hyp_filecall_filecall, var_hclose_r
			dw p_hclose_r

ntc_rg9_e:
			IF ($ < 32768) && (ntc_rg10_e - ntc_rg10 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg10:
; ============================================================
; sub filesshut (normal mode)
; ============================================================

p_filesshut:

			; Main.bas 547: Dim r As Integer

			; Main.bas 548: Hyp.FileShut t
			dw p_hyp_fileshut_c, var_filesshut_t
			dw p_filesshut_r

ntc_rg10_e:
			IF ($ < 32768) && (ntc_rg11_e - ntc_rg11 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg11:
; ============================================================
; sub collected (normal mode)
; ============================================================

p_collected:

			; Main.bas 561: nc(t) = nc(t) + n
			dw kw_aget, arr_nc, var_collected_t, tmp1
			dw kw_add, tmp1, var_collected_n, tmp1
			dw kw_aset, arr_nc, var_collected_t, tmp1

			; Main.bas 562: Hyp.Con wp(t), 0, n, IIf(t = front, 1, 0)       ' straight from the bank: no copy to main RAM
			dw kw_aget, arr_wp, var_collected_t, tmp0
			dw kw_cpeqvv, var_collected_t, var_front
			dw kw_ftov, tmp3
			dw kw_goto_ifzero_n, tmp3, ch55_0
			dw kw_ltov, 1, tmp3
			dw ch55_e_go
ch55_0:
			dw kw_ztov, tmp3
			dw ch55_e_go
ch55_1:
			dw kw_ztov, tmp3
ch55_e:
			dw p_hyp_con_c, tmp0, lit_0, var_collected_n, tmp3
			dw p_collected_r

ntc_rg11_e:
			IF ($ < 32768) && (ntc_rg12_e - ntc_rg12 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg12:
; ============================================================
; sub puts (normal mode)
; ============================================================

p_puts:

			; Main.bas 567: Hyp.Con wp(t), VarPtr(s), Len(s), IIf(t = front, 1, 0)
			dw kw_aget, arr_wp, var_puts_t, tmp0
			dw kw_strlen, var_puts_s, tmp2
			dw kw_cpeqvv, var_puts_t, var_front
			dw kw_ftov, tmp3
			dw kw_goto_ifzero_n, tmp3, ch56_0
			dw kw_ltov, 1, tmp3
			dw ch56_e_go
ch56_0:
			dw kw_ztov, tmp3
			dw ch56_e_go
ch56_1:
			dw kw_ztov, tmp3
ch56_e:
			dw p_hyp_con_c, tmp0, vp_var_puts_s, tmp2, tmp3
			dw p_puts_r

ntc_rg12_e:
			IF ($ < 32768) && (ntc_rg13_e - ntc_rg13 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg13:
; ============================================================
; sub putln (normal mode)
; ============================================================

p_putln:

			; Main.bas 571: PutS t, s + Chr$(13) + Chr$(10)
			dw kw_strcpy, stmp1, var_putln_s
			dw kw_strcat, stmp1, str6
			dw kw_strcat, stmp1, str7
			dw p_puts_c, var_putln_t, stmp1
			dw p_putln_r

ntc_rg13_e:
			IF ($ < 32768) && (ntc_rg14_e - ntc_rg14 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg14:
; ============================================================
; sub putc (normal mode)
; ============================================================

p_putc:

			; Main.bas 576: Hyp.Con wp(t), VarPtr(c), 1, IIf(t = front, 1, 0)   ' (the Integer's low byte is the character)
			dw kw_aget, arr_wp, var_putc_t, tmp0
			dw kw_cpeqvv, var_putc_t, var_front
			dw kw_ftov, tmp3
			dw kw_goto_ifzero_n, tmp3, ch57_0
			dw kw_ltov, 1, tmp3
			dw ch57_e_go
ch57_0:
			dw kw_ztov, tmp3
			dw ch57_e_go
ch57_1:
			dw kw_ztov, tmp3
ch57_e:
			dw p_hyp_con_c, tmp0, vp_var_putc_c, lit_1, tmp3
			dw p_putc_r

ntc_rg14_e:
			IF ($ < 32768) && (ntc_rg15_e - ntc_rg15 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg15:
; ============================================================
; function nearp (normal mode)
; ============================================================

p_nearp:

			; Main.bas 599: NearP = CLng(p)
			dw kw_l_itol, var_nearp_p, var_nearp_nearp

			; Main.bas 600: If p < 0 Then NearP = NearP + 65536
			dw kw_scpltvl, var_nearp_p, 0
			dw kw_goto_iffalse_n, if58_1
			dw kw_l_add, var_nearp_nearp, llit_65536, var_nearp_nearp
if58_1:
			dw p_nearp_r

ntc_rg15_e:
			IF ($ < 32768) && (ntc_rg16_e - ntc_rg16 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg16:
; ============================================================
; function far (normal mode)
; ============================================================

p_far:

			; Main.bas 605: Far = Hyp.FarPtr(Memory.BankPage(bk(t), ((a And &HC000) \ 16384) And 3), a)
			dw kw_aget, arr_bk, var_far_t, tmp1
			dw kw_andvl, var_far_a, -16384, tmp2
			dw kw_divvl, tmp2, 16384, tmp2
			dw kw_andvl, tmp2, 3, tmp2
			dw p_memory_bankpage_c, tmp1, tmp2
			dw kw_vtov, var_memory_bankpage_bankpage, tmp1
			dw fn_hyp_farptr, tmp1, var_far_a, var_far_far
			dw p_far_r

ntc_rg16_e:
			IF ($ < 32768) && (ntc_rg17_e - ntc_rg17 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg17:
; ============================================================
; sub clst (normal mode)
; ============================================================

p_clst:

			; Main.bas 610: PutS t, Chr$(27) + "E"
			dw kw_strcpy, stmp1, str8
			dw kw_strcat, stmp1, str9
			dw p_puts_c, var_clst_t, stmp1
			dw p_clst_r

ntc_rg17_e:
			IF ($ < 32768) && (ntc_rg18_e - ntc_rg18 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg18:
; ============================================================
; sub tofront (normal mode)
; ============================================================

p_tofront:

			; Main.bas 615: Dim r As Integer

			; Main.bas 616: front = t
			dw kw_vtov, var_tofront_t, var_front

			; Main.bas 617: If st(t) = 0 Then OpenSlot t : Exit Sub
			dw kw_aget, arr_st, var_tofront_t, tmp0
			dw kw_cpeqvl, tmp0, 0
			dw kw_goto_iffalse_n, if59_1
			dw p_openslot_c, var_tofront_t
			dw p_tofront_r
if59_1:

			; Main.bas 618: r = Hyp.Scr(Memory.ReadByte(Far(t, Hyp.CMODE)), 2)   ' the screen in its mode (cleared)
			dw p_far_c, var_tofront_t, lit_m2423
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_readbyte, ltmp0, var_memory_readbyte_readbyte
			dw kw_vtov, var_memory_readbyte_readbyte, tmp0
			dw p_hyp_scr_c, tmp0, lit_2
			dw kw_vtov, var_hyp_scr_scr, var_tofront_r

			; Main.bas 619: Hyp.Show wp(t)
			dw kw_aget, arr_wp, var_tofront_t, tmp0
			dw p_hyp_show_c, tmp0
			dw p_tofront_r

ntc_rg18_e:
			IF ($ < 32768) && (ntc_rg19_e - ntc_rg19 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg19:
; ============================================================
; sub setmode (normal mode)
; ============================================================

p_setmode:

			; Main.bas 626: Dim r As Integer

			; Main.bas 627: Memory.WriteByte Far(t, Hyp.CCOLS), Hyp.Scr(m, 0)
			dw p_far_c, var_setmode_t, lit_m2425
			dw kw_l_mov, var_far_far, ltmp0
			dw p_hyp_scr_c, var_setmode_m, lit_0
			dw kw_vtov, var_hyp_scr_scr, tmp1
			dw fn_memory_writebyte, ltmp0, tmp1

			; Main.bas 628: Memory.WriteByte Far(t, Hyp.CROWS), Hyp.Scr(m, 1)
			dw p_far_c, var_setmode_t, lit_m2424
			dw kw_l_mov, var_far_far, ltmp0
			dw p_hyp_scr_c, var_setmode_m, lit_1
			dw kw_vtov, var_hyp_scr_scr, tmp1
			dw fn_memory_writebyte, ltmp0, tmp1

			; Main.bas 629: Memory.WriteByte Far(t, Hyp.CMODE), m
			dw p_far_c, var_setmode_t, lit_m2423
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writebyte, ltmp0, var_setmode_m

			; Main.bas 630: en = Left$("[" + N(t) + "]   ", 4)
			dw p_n_c, var_setmode_t
			dw kw_strcpy, stmp1, var_n_n
			dw kw_strcpy, stmp0, str10
			dw kw_strcat, stmp0, stmp1
			dw kw_strcat, stmp0, str11
			dw kw_strleft, stmp0, stmp0, lit_4
			dw kw_strcpy, var_en, stmp0

			; Main.bas 631: Memory.Copy NearP(VarPtr(en)), Far(t, Hyp.CSTRIP), 4
			dw p_nearp_c, vp_var_en
			dw kw_l_mov, var_nearp_nearp, ltmp0
			dw p_far_c, var_setmode_t, lit_m2422
			dw kw_l_mov, var_far_far, ltmp1
			dw fn_memory_copy, ltmp0, ltmp1, lit_4, var_memory_copy_copy

			; Main.bas 632: If t = front Then r = Hyp.Scr(m, 2)
			dw kw_cpeqvv, var_setmode_t, var_front
			dw kw_goto_iffalse_n, if60_1
			dw p_hyp_scr_c, var_setmode_m, lit_2
			dw kw_vtov, var_hyp_scr_scr, var_setmode_r
if60_1:

			; Main.bas 633: ClsT t
			dw p_clst_c, var_setmode_t
			dw p_setmode_r

ntc_rg19_e:
			IF ($ < 32768) && (ntc_rg20_e - ntc_rg20 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg20:
; ============================================================
; sub showtop (normal mode)
; ============================================================

p_showtop:

			; Main.bas 796: Dim j As Integer

			; Main.bas 797: If front <> 0 Then back = front
			dw kw_cpnevl, var_front, 0
			dw kw_goto_iffalse_n, if61_1
			dw kw_vtov, var_front, var_back
if61_1:

			; Main.bas 798: front = 0
			dw kw_ztov, var_front

			; Main.bas 799: j = Hyp.Scr(0, 2)               ' TOP in MODE 2 (80 x 25), the screen cleared
			dw p_hyp_scr_c, lit_0, lit_2
			dw kw_vtov, var_hyp_scr_scr, var_showtop_j

			; Main.bas 800: txs = 0
			dw kw_ztov, var_txs

			; Main.bas 801: TopLines back, 1
			dw p_toplines_c, var_back, lit_1
			dw p_showtop_r

ntc_rg20_e:
			IF ($ < 32768) && (ntc_rg21_e - ntc_rg21 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg21:
; ============================================================
; sub toplines (normal mode)
; ============================================================

p_toplines:

			; Main.bas 807: Dim j As Integer, s As String Max 14

			; Main.bas 808: txn = 0
			dw kw_ztov, var_txn

			; Main.bas 809: TopAdd "CyborgOS TOP"
			dw p_topadd_c, str12

			; Main.bas 810: If keys Then TopAdd "Control + ESC: back, " + SK() + ": that slot" Else TopAdd ""   ' (25 rows: 20 slots)
			dw kw_goto_ifzero_n, var_toplines_keys, if62_1
			dw p_sk_c
			dw kw_strcpy, stmp1, var_sk_sk
			dw kw_strcpy, stmp0, str13
			dw kw_strcat, stmp0, stmp1
			dw kw_strcat, stmp0, str14
			dw p_topadd_c, stmp0
			dw if62_e_go
if62_1:
			dw p_topadd_c, str2
if62_e:

			; Main.bas 811: TopAdd "SLOT  STATE          PROGRAM         TURNS/S   BDOS/S  CHARS/S   (last second)"
			dw p_topadd_c, str15

			; Main.bas 812: For j = 1 To ns
			dw kw_ltov, 1, var_toplines_j
			dw kw_vtov, var_ns, for63_l
			dw kw_forupv_n, var_toplines_j, for63_l, for63_e
for63_t:

			; Main.bas 813: If st(j) = 0 Then
			dw kw_aget, arr_st, var_toplines_j, tmp0
			dw kw_cpeqvl, tmp0, 0
			dw kw_goto_iffalse_n, if64_1

			; Main.bas 814: s = "-"
			dw kw_strcpy, var_toplines_s, str16

			; Main.bas 815: ElseIf st(j) = 1 Then
			dw if64_e_go
if64_1:
			dw kw_aget, arr_st, var_toplines_j, tmp0
			dw kw_cpeqvl, tmp0, 1
			dw kw_goto_iffalse_n, if64_2

			; Main.bas 816: s = "command line"
			dw kw_strcpy, var_toplines_s, str17

			; Main.bas 817: ElseIf wk(j) >= 0 Then
			dw if64_e_go
if64_2:
			dw kw_aget, arr_wk, var_toplines_j, tmp0
			dw kw_scpgevl, tmp0, 0
			dw kw_goto_iffalse_n, if64_3

			; Main.bas 818: s = "waiting (key)"
			dw kw_strcpy, var_toplines_s, str18

			; Main.bas 819: Else
			dw if64_e_go
if64_3:

			; Main.bas 820: s = "running"
			dw kw_strcpy, var_toplines_s, str19

			; Main.bas 821: End If
if64_e:

			; Main.bas 822: en = ""
			dw kw_strcpy, var_en, str2

			; Main.bas 823: If st(j) = 2 Then GetNm j
			dw kw_aget, arr_st, var_toplines_j, tmp0
			dw kw_cpeqvl, tmp0, 2
			dw kw_goto_iffalse_n, if65_1
			dw p_getnm_c, var_toplines_j
if65_1:

			; Main.bas 824: TopAdd " " + Right$(" " + N(j), 2) + IIf(j = mark, "*", " ") + "  " + Left$(s + Space$(15), 15) + Left$(en + Space$(13), 13) + Pad(Rate(lt(j), ld)) + Pad(Rate(lb(j), ld)) + Pad(Rate(lc(j), ld))
			dw p_n_c, var_toplines_j
			dw kw_strcpy, stmp2, var_n_n
			dw kw_strcpy, stmp1, str20
			dw kw_strcat, stmp1, stmp2
			dw kw_strright, stmp1, stmp1, lit_2
			dw kw_strcpy, stmp0, str20
			dw kw_strcat, stmp0, stmp1
			dw kw_cpeqvv, var_toplines_j, var_toplines_mark
			dw kw_ftov, tmp1
			dw kw_goto_ifzero_n, tmp1, ch66_0
			dw kw_strcpy, stmp1, str21
			dw ch66_e_go
ch66_0:
			dw kw_strcpy, stmp1, str20
			dw ch66_e_go
ch66_1:
			dw kw_strcpy, stmp1, str2
ch66_e:
			dw kw_strcat, stmp0, stmp1
			dw kw_strcat, stmp0, str22
			dw kw_strspace, stmp2, lit_15
			dw kw_strcpy, stmp1, var_toplines_s
			dw kw_strcat, stmp1, stmp2
			dw kw_strleft, stmp1, stmp1, lit_15
			dw kw_strcat, stmp0, stmp1
			dw kw_strspace, stmp2, lit_13
			dw kw_strcpy, stmp1, var_en
			dw kw_strcat, stmp1, stmp2
			dw kw_strleft, stmp1, stmp1, lit_13
			dw kw_strcat, stmp0, stmp1
			dw kw_aget, arr_lt, var_toplines_j, tmp1
			dw p_rate_c, tmp1, var_ld
			dw kw_vtov, var_rate_rate, tmp1
			dw p_pad_c, tmp1
			dw kw_strcpy, stmp1, var_pad_pad
			dw kw_strcat, stmp0, stmp1
			dw kw_aget, arr_lb, var_toplines_j, tmp1
			dw p_rate_c, tmp1, var_ld
			dw kw_vtov, var_rate_rate, tmp1
			dw p_pad_c, tmp1
			dw kw_strcpy, stmp1, var_pad_pad
			dw kw_strcat, stmp0, stmp1
			dw kw_aget, arr_lc, var_toplines_j, tmp1
			dw p_rate_c, tmp1, var_ld
			dw kw_vtov, var_rate_rate, tmp1
			dw p_pad_c, tmp1
			dw kw_strcpy, stmp1, var_pad_pad
			dw kw_strcat, stmp0, stmp1
			dw p_topadd_c, stmp0

			; Main.bas 825: Next
			dw kw_next1v_n, var_toplines_j, for63_l, for63_t
for63_e:

			; Main.bas 826: TopAdd ""
			dw p_topadd_c, str2

			; Main.bas 827: Totals
			dw p_totals_c

			; Main.bas 828: TopAdd en
			dw p_topadd_c, var_en
			dw p_toplines_r

ntc_rg21_e:
			IF ($ < 32768) && (ntc_rg22_e - ntc_rg22 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg22:
; ============================================================
; sub totals (normal mode)
; ============================================================

p_totals:

			; Main.bas 833: en = "Total memory: " + N(Memory.RamSize()) + " KB   Free memory: " + N(Memory.FreePages() * 16) + " KB"
			dw fn_memory_ramsize, var_memory_ramsize_ramsize
			dw kw_vtov, var_memory_ramsize_ramsize, tmp1
			dw p_n_c, tmp1
			dw kw_strcpy, stmp1, var_n_n
			dw kw_strcpy, stmp0, str23
			dw kw_strcat, stmp0, stmp1
			dw kw_strcat, stmp0, str24
			dw fn_memory_freepages, var_memory_freepages_freepages
			dw kw_vtov, var_memory_freepages_freepages, tmp1
			dw kw_mulvl, tmp1, 16, tmp1
			dw p_n_c, tmp1
			dw kw_strcpy, stmp1, var_n_n
			dw kw_strcat, stmp0, stmp1
			dw kw_strcpy, var_en, stmp0
			dw kw_strcat, var_en, str25
			dw p_totals_r

ntc_rg22_e:
			IF ($ < 32768) && (ntc_rg23_e - ntc_rg23 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg23:
; ============================================================
; sub topadd (normal mode)
; ============================================================

p_topadd:

			; Main.bas 841: If txs = 0 Then
			dw kw_cpeqvl, var_txs, 0
			dw kw_goto_iffalse_n, if67_1

			; Main.bas 842: Hyp.Say VarPtr(s), Len(s), 0, txn          ' straight into screen memory (Print took ~0.7 s)
			dw kw_strlen, var_topadd_s, tmp1
			dw p_hyp_say_c, vp_var_topadd_s, tmp1, lit_0, var_txn

			; Main.bas 843: Else
			dw if67_e_go
if67_1:

			; Main.bas 844: PutLn txs, s
			dw p_putln_c, var_txs, var_topadd_s

			; Main.bas 845: End If
if67_e:

			; Main.bas 846: txn = txn + 1
			dw kw_inc, var_txn
			dw p_topadd_r

ntc_rg23_e:
			IF ($ < 32768) && (ntc_rg24_e - ntc_rg24 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg24:
; ============================================================
; sub roll (normal mode)
; ============================================================

p_roll:

			; Main.bas 851: Dim j As Integer

			; Main.bas 852: ld = Ticks - td
			dw kw_ticks, tmp0
			dw kw_subvv, tmp0, var_td, var_ld

			; Main.bas 853: td = Ticks
			dw kw_ticks, tmp0
			dw kw_vtov, tmp0, var_td

			; Main.bas 854: For j = 1 To ns
			dw kw_ltov, 1, var_roll_j
			dw kw_vtov, var_ns, for68_l
			dw kw_forupv_n, var_roll_j, for68_l, for68_e
for68_t:

			; Main.bas 855: lt(j) = tn(j) : lb(j) = nb(j) : lc(j) = nc(j)
			dw kw_aget, arr_tn, var_roll_j, tmp1
			dw kw_aset, arr_lt, var_roll_j, tmp1
			dw kw_aget, arr_nb, var_roll_j, tmp1
			dw kw_aset, arr_lb, var_roll_j, tmp1
			dw kw_aget, arr_nc, var_roll_j, tmp1
			dw kw_aset, arr_lc, var_roll_j, tmp1

			; Main.bas 856: tn(j) = 0 : nb(j) = 0 : nc(j) = 0
			dw kw_asetl, arr_tn, var_roll_j, 0
			dw kw_asetl, arr_nb, var_roll_j, 0
			dw kw_asetl, arr_nc, var_roll_j, 0

			; Main.bas 857: Next
			dw kw_next1v_n, var_roll_j, for68_l, for68_t
for68_e:
			dw p_roll_r

ntc_rg24_e:
			IF ($ < 32768) && (ntc_rg25_e - ntc_rg25 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg25:
; ============================================================
; function pad (normal mode)
; ============================================================

p_pad:

			; Main.bas 862: Pad = Right$(Space$(9) + N(v), 9)
			dw kw_strspace, stmp1, lit_9
			dw p_n_c, var_pad_v
			dw kw_strcpy, stmp2, var_n_n
			dw kw_strcat, stmp1, stmp2
			dw kw_strright, var_pad_pad, stmp1, lit_9
			dw p_pad_r

ntc_rg25_e:
			IF ($ < 32768) && (ntc_rg26_e - ntc_rg26 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg26:
; ============================================================
; function rate (normal mode)
; ============================================================

p_rate:

			; Main.bas 867: If n > 1000 Then Rate = n \ (d \ 300 + 1) Else Rate = n * 30 \ (d \ 10 + 1)
			dw kw_scpgtvl, var_rate_n, 1000
			dw kw_goto_iffalse_n, if69_1
			dw kw_divvl, var_rate_d, 300, tmp2
			dw kw_inc, tmp2
			dw kw_divvv, var_rate_n, tmp2, var_rate_rate
			dw if69_e_go
if69_1:
			dw kw_mulvl, var_rate_n, 30, tmp1
			dw kw_divvl, var_rate_d, 10, tmp2
			dw kw_inc, tmp2
			dw kw_divvv, tmp1, tmp2, var_rate_rate
if69_e:
			dw p_rate_r

ntc_rg26_e:
			IF ($ < 32768) && (ntc_rg27_e - ntc_rg27 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg27:
; ============================================================
; sub install (normal mode)
; ============================================================

p_install:

			; Main.bas 874: Dim p As Integer, n As Integer

			; Main.bas 875: p = Hyp.Info(0) : n = Hyp.Info(1)             ' (one Info result each: it is one variable)
			dw fn_hyp_info, lit_0, var_install_p
			dw fn_hyp_info, lit_1, var_install_n

			; Main.bas 876: Memory.Copy Hyp.FarPtr(hp, p), Far(t, 0), n   ' (from the hypervisor's page)
			dw fn_hyp_farptr, var_hp, var_install_p, var_hyp_farptr_farptr
			dw kw_l_mov, var_hyp_farptr_farptr, ltmp0
			dw p_far_c, var_install_t, lit_0
			dw kw_l_mov, var_far_far, ltmp1
			dw fn_memory_copy, ltmp0, ltmp1, var_install_n, var_memory_copy_copy

			; Main.bas 877: p = Hyp.Info(2) : n = Hyp.Info(3)
			dw fn_hyp_info, lit_2, var_install_p
			dw fn_hyp_info, lit_3, var_install_n

			; Main.bas 878: Memory.Copy Hyp.FarPtr(hp, p), Far(t, Hyp.STUB), n
			dw fn_hyp_farptr, var_hp, var_install_p, var_hyp_farptr_farptr
			dw kw_l_mov, var_hyp_farptr_farptr, ltmp0
			dw p_far_c, var_install_t, lit_m4352
			dw kw_l_mov, var_far_far, ltmp1
			dw fn_memory_copy, ltmp0, ltmp1, var_install_n, var_memory_copy_copy

			; Main.bas 879: Memory.Copy Hyp.FarPtr(hp, Hyp.HFONT), Far(t, Hyp.FONT), 768   ' the font (Con draws from it)
			dw fn_hyp_farptr, var_hp, lit_4096, var_hyp_farptr_farptr
			dw kw_l_mov, var_hyp_farptr_farptr, ltmp0
			dw p_far_c, var_install_t, lit_m3328
			dw kw_l_mov, var_far_far, ltmp1
			dw fn_memory_copy, ltmp0, ltmp1, lit_768, var_memory_copy_copy

			; Main.bas 880: Memory.WriteByte Far(t, Hyp.OBUF + 128), 0      ' no characters collected
			dw p_far_c, var_install_t, lit_m2432
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writebyte, ltmp0, lit_0

			; Main.bas 881: Memory.WriteByte Far(t, Hyp.KEY), 0             ' no key waiting
			dw p_far_c, var_install_t, lit_m2431
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writebyte, ltmp0, lit_0

			; Main.bas 882: kq(t) = 0
			dw kw_asetl, arr_kq, var_install_t, 0
			dw p_install_r

ntc_rg27_e:
			IF ($ < 32768) && (ntc_rg28_e - ntc_rg28 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg28:
; ============================================================
; sub resetslot (normal mode)
; ============================================================

p_resetslot:

			; Main.bas 894: FilesShut s
			dw p_filesshut_c, var_resetslot_s

			; Main.bas 899: st(s) = 0
			dw kw_asetl, arr_st, var_resetslot_s, 0

			; Main.bas 904: kq(s) = 0
			dw kw_asetl, arr_kq, var_resetslot_s, 0

			; Main.bas 905: wk(s) = -1
			dw kw_asetl, arr_wk, var_resetslot_s, -1

			; Main.bas 906: tn(s) = 0 : nb(s) = 0 : nc(s) = 0
			dw kw_asetl, arr_tn, var_resetslot_s, 0
			dw kw_asetl, arr_nb, var_resetslot_s, 0
			dw kw_asetl, arr_nc, var_resetslot_s, 0

			; Main.bas 907: lt(s) = 0 : lb(s) = 0 : lc(s) = 0
			dw kw_asetl, arr_lt, var_resetslot_s, 0
			dw kw_asetl, arr_lb, var_resetslot_s, 0
			dw kw_asetl, arr_lc, var_resetslot_s, 0

			; Main.bas 908: If s = front Then
			dw kw_cpeqvv, var_resetslot_s, var_front
			dw kw_goto_iffalse_n, if70_1

			; Main.bas 909: Install s
			dw p_install_c, var_resetslot_s

			; Main.bas 910: st(s) = 1
			dw kw_asetl, arr_st, var_resetslot_s, 1

			; Main.bas 911: SetMode s, 1
			dw p_setmode_c, var_resetslot_s, lit_1

			; Main.bas 912: PutLn s, "CyborgOS slot " + N(s) + " of " + N(ns) + " - " + SK() + ", Control + ESC TOP, HELP"
			dw p_n_c, var_resetslot_s
			dw kw_strcpy, stmp2, var_n_n
			dw kw_strcpy, stmp1, str26
			dw kw_strcat, stmp1, stmp2
			dw kw_strcat, stmp1, str27
			dw p_n_c, var_ns
			dw kw_strcpy, stmp2, var_n_n
			dw kw_strcat, stmp1, stmp2
			dw kw_strcat, stmp1, str28
			dw p_sk_c
			dw kw_strcpy, stmp2, var_sk_sk
			dw kw_strcat, stmp1, stmp2
			dw kw_strcat, stmp1, str29
			dw p_putln_c, var_resetslot_s, stmp1

			; Main.bas 913: PutLn s, ""                   ' a blank line under the title
			dw p_putln_c, var_resetslot_s, str2

			; Main.bas 914: End If                          ' (the prompt: the command line puts it after the command)
if70_1:
			dw p_resetslot_r

ntc_rg28_e:
			IF ($ < 32768) && (ntc_rg29_e - ntc_rg29 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg29:
; ============================================================
; sub openslot (normal mode)
; ============================================================

p_openslot:

			; Main.bas 918: Install t
			dw p_install_c, var_openslot_t

			; Main.bas 919: st(t) = 1
			dw kw_asetl, arr_st, var_openslot_t, 1

			; Main.bas 920: SetMode t, 1                    ' MODE S: 80 x 24 and the status strip
			dw p_setmode_c, var_openslot_t, lit_1

			; Main.bas 921: PutLn t, "CyborgOS slot " + N(t) + " of " + N(ns) + " - " + SK() + ", Control + ESC TOP, HELP"
			dw p_n_c, var_openslot_t
			dw kw_strcpy, stmp2, var_n_n
			dw kw_strcpy, stmp1, str26
			dw kw_strcat, stmp1, stmp2
			dw kw_strcat, stmp1, str27
			dw p_n_c, var_ns
			dw kw_strcpy, stmp2, var_n_n
			dw kw_strcat, stmp1, stmp2
			dw kw_strcat, stmp1, str28
			dw p_sk_c
			dw kw_strcpy, stmp2, var_sk_sk
			dw kw_strcat, stmp1, stmp2
			dw kw_strcat, stmp1, str29
			dw p_putln_c, var_openslot_t, stmp1

			; Main.bas 922: PutLn t, ""                     ' a blank line under the title
			dw p_putln_c, var_openslot_t, str2

			; Main.bas 923: Prompt t
			dw p_prompt_c, var_openslot_t
			dw p_openslot_r

ntc_rg29_e:
			IF ($ < 32768) && (ntc_rg30_e - ntc_rg30 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg30:
; ============================================================
; function sk (normal mode)
; ============================================================

p_sk:

			; Main.bas 928: If ns <= 9 Then
			dw kw_scplevl, var_ns, 9
			dw kw_goto_iffalse_n, if71_1

			; Main.bas 929: SK = "Control + 1-" + N(ns)
			dw p_n_c, var_ns
			dw kw_strcpy, stmp3, var_n_n
			dw kw_strcpy, var_sk_sk, str30
			dw kw_strcat, var_sk_sk, stmp3

			; Main.bas 930: ElseIf ns = 10 Then
			dw if71_e_go
if71_1:
			dw kw_cpeqvl, var_ns, 10
			dw kw_goto_iffalse_n, if71_2

			; Main.bas 931: SK = "Control + 1-9, 0"
			dw kw_strcpy, var_sk_sk, str31

			; Main.bas 932: Else
			dw if71_e_go
if71_2:

			; Main.bas 933: SK = "Control + 1-9, 0 (twice 11-" + N(ns) + ")"
			dw p_n_c, var_ns
			dw kw_strcpy, stmp3, var_n_n
			dw kw_strcpy, stmp2, str32
			dw kw_strcat, stmp2, stmp3
			dw kw_strcpy, var_sk_sk, stmp2
			dw kw_strcat, var_sk_sk, str33

			; Main.bas 934: End If
if71_e:
			dw p_sk_r

ntc_rg30_e:
			IF ($ < 32768) && (ntc_rg31_e - ntc_rg31 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg31:
; ============================================================
; sub getnm (normal mode)
; ============================================================

p_getnm:

			; Main.bas 941: Dim n As Integer

			; Main.bas 942: n = Memory.ReadByte(Far(t, NMLEN))
			dw p_far_c, var_getnm_t, lit_m2344
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_readbyte, ltmp0, var_getnm_n

			; Main.bas 943: en = Space$(12)
			dw kw_strspace, stmp0, lit_12
			dw kw_strcpy, var_en, stmp0

			; Main.bas 944: Memory.Copy Far(t, NMBUF), NearP(VarPtr(en)), n
			dw p_far_c, var_getnm_t, lit_m2343
			dw kw_l_mov, var_far_far, ltmp0
			dw p_nearp_c, vp_var_en
			dw kw_l_mov, var_nearp_nearp, ltmp1
			dw fn_memory_copy, ltmp0, ltmp1, var_getnm_n, var_memory_copy_copy

			; Main.bas 945: en = Left$(en, n)
			dw kw_strleft, stmp0, var_en, var_getnm_n
			dw kw_strcpy, var_en, stmp0
			dw p_getnm_r

ntc_rg31_e:
			IF ($ < 32768) && (ntc_rg32_e - ntc_rg32 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg32:
; ============================================================
; function n (normal mode)
; ============================================================

p_n:

			; Main.bas 949: N = Trim$(Str$(v))
			dw kw_strstr, stmp3, var_n_v
			dw kw_strtrim, var_n_n, stmp3
			dw p_n_r

ntc_rg32_e:
			IF ($ < 32768) && (ntc_rg33_e - ntc_rg33 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg33:
; ============================================================
; sub prompt (normal mode)
; ============================================================

p_prompt:

			; Main.bas 953: Memory.WriteByte Far(t, LNLEN), 0                ' an empty command line
			dw p_far_c, var_prompt_t, lit_m2417
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writebyte, ltmp0, lit_0

			; Main.bas 954: PutS t, N(t) + "> "
			dw p_n_c, var_prompt_t
			dw kw_strcpy, stmp1, var_n_n
			dw kw_strcat, stmp1, str34
			dw p_puts_c, var_prompt_t, stmp1
			dw p_prompt_r

ntc_rg33_e:
			IF ($ < 32768) && (ntc_rg34_e - ntc_rg34 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg34:
; ============================================================
; sub keyin (normal mode)
; ============================================================

p_keyin:

			; Main.bas 959: Dim t As Integer, n As Integer

			; Main.bas 960: If front = 0 Then
			dw kw_cpeqvl, var_front, 0
			dw kw_goto_iffalse_n, if72_1

			; Main.bas 961: Exit Sub                      ' TOP stays until Control + ESC or Control + a slot
			dw p_keyin_r

			; Main.bas 962: End If
if72_1:

			; Main.bas 963: t = front
			dw kw_vtov, var_front, var_keyin_t

			; Main.bas 967: If st(t) = 2 Then
			dw kw_aget, arr_st, var_keyin_t, tmp0
			dw kw_cpeqvl, tmp0, 2
			dw kw_goto_iffalse_n, if73_1

			; Main.bas 968: If k = &HFC Then k = 27                       ' (ESC: the firmware's #FC - CP/M's #1B, as Amstrad's CP/M)
			dw kw_cpeqvl, var_keyin_k, 252
			dw kw_goto_iffalse_n, if74_1
			dw kw_ltov, 27, var_keyin_k
if74_1:

			; Main.bas 969: kq(t) = k                                     ' the key into its bank: its BDOS answers from it
			dw kw_aset, arr_kq, var_keyin_t, var_keyin_k

			; Main.bas 970: Memory.WriteByte Far(t, Hyp.KEY), k
			dw p_far_c, var_keyin_t, lit_m2431
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writebyte, ltmp0, var_keyin_k

			; Main.bas 971: Exit Sub
			dw p_keyin_r

			; Main.bas 972: End If
if73_1:

			; Main.bas 973: n = Memory.ReadByte(Far(t, LNLEN))             ' the command line so far (in the slot's bank)
			dw p_far_c, var_keyin_t, lit_m2417
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_readbyte, ltmp0, var_keyin_n

			; Main.bas 974: If k = 13 Then
			dw kw_cpeqvl, var_keyin_k, 13
			dw kw_goto_iffalse_n, if75_1

			; Main.bas 975: PutLn t, ""
			dw p_putln_c, var_keyin_t, str2

			; Main.bas 976: Command t
			dw p_command_c, var_keyin_t

			; Main.bas 977: If st(t) = 1 And wt = 0 And front = t Then Prompt t
			dw kw_aget, arr_st, var_keyin_t, tmp0
			dw kw_cpeqvl, tmp0, 1
			dw kw_ftov, tmp0
			dw kw_cpeqvl, var_wt, 0
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_cpeqvv, var_front, var_keyin_t
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if75_e
			dw p_prompt_c, var_keyin_t
if76_1:

			; Main.bas 978: ElseIf k = 127 Or k = 8 Then
			dw if75_e_go
if75_1:
			dw kw_cpeqvl, var_keyin_k, 127
			dw kw_ftov, tmp0
			dw kw_cpeqvl, var_keyin_k, 8
			dw kw_ftov, tmp1
			dw kw_orvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if75_2

			; Main.bas 979: If n > 0 Then
			dw kw_scpgtvl, var_keyin_n, 0
			dw kw_goto_iffalse_n, if75_e

			; Main.bas 980: Memory.WriteByte Far(t, LNLEN), n - 1
			dw p_far_c, var_keyin_t, lit_m2417
			dw kw_l_mov, var_far_far, ltmp0
			dw kw_addl, var_keyin_n, -1, tmp1
			dw fn_memory_writebyte, ltmp0, tmp1

			; Main.bas 981: PutC t, 8 : PutC t, 32 : PutC t, 8
			dw p_putc_c, var_keyin_t, lit_8
			dw p_putc_c, var_keyin_t, lit_32
			dw p_putc_c, var_keyin_t, lit_8

			; Main.bas 982: End If
if77_1:

			; Main.bas 983: ElseIf k >= 32 And k < 127 And n < 70 Then
			dw if75_e_go
if75_2:
			dw kw_scpgevl, var_keyin_k, 32
			dw kw_ftov, tmp0
			dw kw_scpltvl, var_keyin_k, 127
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_scpltvl, var_keyin_n, 70
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if75_3

			; Main.bas 984: Memory.WriteByte Far(t, LNBUF + n), k
			dw kw_addl, var_keyin_n, -2416, tmp1
			dw p_far_c, var_keyin_t, tmp1
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writebyte, ltmp0, var_keyin_k

			; Main.bas 985: Memory.WriteByte Far(t, LNLEN), n + 1
			dw p_far_c, var_keyin_t, lit_m2417
			dw kw_l_mov, var_far_far, ltmp0
			dw kw_addl, var_keyin_n, 1, tmp1
			dw fn_memory_writebyte, ltmp0, tmp1

			; Main.bas 986: PutC t, k
			dw p_putc_c, var_keyin_t, var_keyin_k

			; Main.bas 987: End If
if75_3:
if75_e:
			dw p_keyin_r

ntc_rg34_e:
			IF ($ < 32768) && (ntc_rg35_e - ntc_rg35 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg35:
; ============================================================
; sub command (normal mode)
; ============================================================

p_command:

			; Main.bas 991: Dim c As String Max 72, p As Integer, s As Integer

			; Main.bas 992: p = Memory.ReadByte(Far(t, LNLEN))              ' the command line, from the slot's bank
			dw p_far_c, var_command_t, lit_m2417
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_readbyte, ltmp0, var_command_p

			; Main.bas 993: Memory.Copy Far(t, LNBUF), NearP(VarPtr(ob)), p
			dw p_far_c, var_command_t, lit_m2416
			dw kw_l_mov, var_far_far, ltmp0
			dw p_nearp_c, vp_var_ob
			dw kw_l_mov, var_nearp_nearp, ltmp1
			dw fn_memory_copy, ltmp0, ltmp1, var_command_p, var_memory_copy_copy

			; Main.bas 994: c = UCase$(Trim$(Left$(ob, p)))
			dw kw_strleft, stmp0, var_ob, var_command_p
			dw kw_strtrim, stmp0, stmp0
			dw kw_strucase, stmp0, stmp0
			dw kw_strcpy, var_command_c, stmp0

			; Main.bas 995: a = "" : b = ""
			dw kw_strcpy, var_a, str2
			dw kw_strcpy, var_b, str2

			; Main.bas 996: p = InStr(c, " ")
			dw kw_strinstr, lit_1, var_command_c, str20, var_command_p

			; Main.bas 997: If p > 0 Then
			dw kw_scpgtvl, var_command_p, 0
			dw kw_goto_iffalse_n, if78_1

			; Main.bas 998: a = Trim$(Mid$(c, p + 1))
			dw kw_addl, var_command_p, 1, tmp1
			dw kw_strmid, stmp0, var_command_c, tmp1, lit_255
			dw kw_strtrim, stmp0, stmp0
			dw kw_strcpy, var_a, stmp0

			; Main.bas 999: c = Left$(c, p - 1)
			dw kw_addl, var_command_p, -1, tmp1
			dw kw_strleft, stmp0, var_command_c, tmp1
			dw kw_strcpy, var_command_c, stmp0

			; Main.bas 1000: End If
if78_1:

			; Main.bas 1001: p = InStr(a, " ")
			dw kw_strinstr, lit_1, var_a, str20, var_command_p

			; Main.bas 1002: If p > 0 Then
			dw kw_scpgtvl, var_command_p, 0
			dw kw_goto_iffalse_n, if79_1

			; Main.bas 1003: b = Trim$(Mid$(a, p + 1))
			dw kw_addl, var_command_p, 1, tmp1
			dw kw_strmid, stmp0, var_a, tmp1, lit_255
			dw kw_strtrim, stmp0, stmp0
			dw kw_strcpy, var_b, stmp0

			; Main.bas 1004: a = Left$(a, p - 1)
			dw kw_addl, var_command_p, -1, tmp1
			dw kw_strleft, stmp0, var_a, tmp1
			dw kw_strcpy, var_a, stmp0

			; Main.bas 1005: End If
if79_1:

			; Main.bas 1006: If Right$(c, 1) = ":" And a = "" Then a = c : c = "CV"   ' B: or IDE: alone: CV B:, CV IDE: (CV.CYB)
			dw kw_strright, stmp0, var_command_c, lit_1
			dw kw_strcmpeq, stmp0, str35
			dw kw_ftov, tmp0
			dw kw_strcmpeq, var_a, str2
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if80_1
			dw kw_strcpy, var_a, var_command_c
			dw kw_strcpy, var_command_c, str36
if80_1:

			; Main.bas 1007: Select Case c
			dw kw_strcpy, var_command___sel81, var_command_c

			; Main.bas 1008: Case ""
			dw kw_strcmpeq, var_command___sel81, str2
			dw kw_goto_iffalse_n, sel81_1
sel81_b1:

			; Main.bas 1009: Case "CLS"
			dw sel81_e_go
sel81_1:
			dw kw_strcmpeq, var_command___sel81, str37
			dw kw_goto_iffalse_n, sel81_2
sel81_b2:

			; Main.bas 1010: ClsT t
			dw p_clst_c, var_command_t

			; Main.bas 1011: Case "RUN"                                 ' RUN [slot] name [tail]: the program on the disc even
			dw sel81_e_go
sel81_2:
			dw kw_strcmpeq, var_command___sel81, str38
			dw kw_goto_iffalse_n, sel81_3
sel81_b3:

			; Main.bas 1012: s = t                                    ' when a command has its name; with a slot: in that one
			dw kw_vtov, var_command_t, var_command_s

			; Main.bas 1013: If a <> "" And N(Val(a)) = a Then
			dw kw_strcmpne, var_a, str2
			dw kw_ftov, tmp0
			dw kw_strval, var_a, tmp1
			dw p_n_c, tmp1
			dw kw_strcpy, stmp1, var_n_n
			dw kw_strcmpeq, stmp1, var_a
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if82_1

			; Main.bas 1014: s = Val(a) : a = b : b = ""
			dw kw_strval, var_a, var_command_s
			dw kw_strcpy, var_a, var_b
			dw kw_strcpy, var_b, str2

			; Main.bas 1015: p = InStr(a, " ")
			dw kw_strinstr, lit_1, var_a, str20, var_command_p

			; Main.bas 1016: If p > 0 Then b = Trim$(Mid$(a, p + 1)) : a = Left$(a, p - 1)
			dw kw_scpgtvl, var_command_p, 0
			dw kw_goto_iffalse_n, if83_1
			dw kw_addl, var_command_p, 1, tmp1
			dw kw_strmid, stmp0, var_a, tmp1, lit_255
			dw kw_strtrim, stmp0, stmp0
			dw kw_strcpy, var_b, stmp0
			dw kw_addl, var_command_p, -1, tmp1
			dw kw_strleft, stmp0, var_a, tmp1
			dw kw_strcpy, var_a, stmp0
if83_1:

			; Main.bas 1017: End If
if82_1:

			; Main.bas 1018: If s < 1 Or s > ns Then PutLn t, "no slot" + Str$(s) : Exit Sub
			dw kw_scpltvl, var_command_s, 1
			dw kw_ftov, tmp0
			dw kw_scpgtvv, var_command_s, var_ns
			dw kw_ftov, tmp1
			dw kw_orvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if84_1
			dw kw_strstr, stmp2, var_command_s
			dw kw_strcpy, stmp1, str39
			dw kw_strcat, stmp1, stmp2
			dw p_putln_c, var_command_t, stmp1
			dw p_command_r
if84_1:

			; Main.bas 1019: If st(s) = 2 Then PutLn t, "slot" + Str$(s) + " is busy" : Exit Sub
			dw kw_aget, arr_st, var_command_s, tmp0
			dw kw_cpeqvl, tmp0, 2
			dw kw_goto_iffalse_n, if85_1
			dw kw_strstr, stmp2, var_command_s
			dw kw_strcpy, stmp1, str40
			dw kw_strcat, stmp1, stmp2
			dw kw_strcat, stmp1, str41
			dw p_putln_c, var_command_t, stmp1
			dw p_command_r
if85_1:

			; Main.bas 1020: StartTask t, s
			dw p_starttask_c, var_command_t, var_command_s

			; Main.bas 1021: Case "QUIT"
			dw sel81_e_go
sel81_3:
			dw kw_strcmpeq, var_command___sel81, str42
			dw kw_goto_iffalse_n, sel81_4
sel81_b4:

			; Main.bas 1022: quit = -1
			dw kw_ltov, -1, var_quit

			; Main.bas 1023: Case Else                                  ' the rest are programs (the system drive Z's, else
			dw sel81_e_go
sel81_4:

			; Main.bas 1024: b = Trim$(a + " " + b)                   ' the slot's drive, else A): PS, MEM, CD, DIR ... and
			dw kw_strcpy, stmp0, var_a
			dw kw_strcat, stmp0, str20
			dw kw_strcat, stmp0, var_b
			dw kw_strtrim, stmp0, stmp0
			dw kw_strcpy, var_b, stmp0

			; Main.bas 1025: a = c                                    ' any other, the rest of the line their tail
			dw kw_strcpy, var_a, var_command_c

			; Main.bas 1026: bare = -1
			dw kw_ltov, -1, var_bare

			; Main.bas 1027: StartTask t, t
			dw p_starttask_c, var_command_t, var_command_t

			; Main.bas 1028: bare = 0
			dw kw_ztov, var_bare

			; Main.bas 1029: End Select
sel81_e:
			dw p_command_r

ntc_rg35_e:
			IF ($ < 32768) && (ntc_rg36_e - ntc_rg36 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg36:
; ============================================================
; sub starttask (normal mode)
; ============================================================

p_starttask:

			; Main.bas 1037: Dim h As Integer, n As Integer, rest As Integer, com As Integer, w As String Max 72, d As Integer

			; Main.bas 1038: If a = "" Then PutLn t, "RUN what?" : Exit Sub
			dw kw_strcmpeq, var_a, str2
			dw kw_goto_iffalse_n, if86_1
			dw p_putln_c, var_starttask_t, str43
			dw p_starttask_r
if86_1:

			; Main.bas 1039: w = a
			dw kw_strcpy, var_starttask_w, var_a

			; Main.bas 1040: d = 0                                          ' the drive looked on: Z (-1, the system drive: the
			dw kw_ztov, var_starttask_d

			; Main.bas 1045: Do
do87_t:

			; Main.bas 1054: a = w : h = 0 : com = 0
			dw kw_strcpy, var_a, var_starttask_w
			dw kw_ztov, var_starttask_h
			dw kw_ztov, var_starttask_com

			; Main.bas 1055: If InStr(a, ".") = 0 Then
			dw kw_strinstr, lit_1, var_a, str44, tmp0
			dw kw_cpeqvl, tmp0, 0
			dw kw_goto_iffalse_n, if88_1

			; Main.bas 1056: dn = a + ".CYB"
			dw kw_strcpy, var_dn, var_a
			dw kw_strcat, var_dn, str45

			; Main.bas 1057: h = HOpen()
			dw p_hopen_c
			dw kw_vtov, var_hopen_hopen, var_starttask_h

			; Main.bas 1058: If h Then a = dn Else com = -1
			dw kw_goto_ifzero_n, var_starttask_h, if89_1
			dw kw_strcpy, var_a, var_dn
			dw if88_e_go
if89_1:
			dw kw_ltov, -1, var_starttask_com
if89_e:

			; Main.bas 1059: ElseIf Right$(a, 4) = ".COM" Then
			dw if88_e_go
if88_1:
			dw kw_strright, stmp0, var_a, lit_4
			dw kw_strcmpeq, stmp0, str46
			dw kw_goto_iffalse_n, if88_2

			; Main.bas 1060: com = -1
			dw kw_ltov, -1, var_starttask_com

			; Main.bas 1061: Else
			dw if88_e_go
if88_2:

			; Main.bas 1062: dn = a
			dw kw_strcpy, var_dn, var_a

			; Main.bas 1063: h = HOpen()
			dw p_hopen_c
			dw kw_vtov, var_hopen_hopen, var_starttask_h

			; Main.bas 1064: End If
if88_e:

			; Main.bas 1065: rest = &HEE00                                ' #0100 to the stub (#EF00)
			dw kw_ltov, -4608, var_starttask_rest

			; Main.bas 1066: If com Then dn = a : h = HOpen()             ' (a .COM: UniDOS, a RAM disc read it to its end)
			dw kw_goto_ifzero_n, var_starttask_com, if90_1
			dw kw_strcpy, var_dn, var_a
			dw p_hopen_c
			dw kw_vtov, var_hopen_hopen, var_starttask_h
if90_1:

			; Main.bas 1067: If h Then Exit Do
			dw kw_goto_ifzero_n, var_starttask_h, do87_e
			dw do87_e_go
if91_1:

			; Main.bas 1069: Exit Do
			dw do87_e_go

			; Main.bas 1074: Loop
do87_e:

			; Main.bas 1075: If h = 0 Then
			dw kw_cpeqvl, var_starttask_h, 0
			dw kw_goto_iffalse_n, if92_1

			; Main.bas 1076: a = w
			dw kw_strcpy, var_a, var_starttask_w

			; Main.bas 1081: NotFound t
			dw p_notfound_c, var_starttask_t

			; Main.bas 1082: Exit Sub
			dw p_starttask_r

			; Main.bas 1083: End If
if92_1:

			; Main.bas 1084: If st(s) = 0 Then OpenSlot s
			dw kw_aget, arr_st, var_starttask_s, tmp0
			dw kw_cpeqvl, tmp0, 0
			dw kw_goto_iffalse_n, if93_1
			dw p_openslot_c, var_starttask_s
if93_1:

			; Main.bas 1085: If s <> t Then PutLn s, "RUN " + a
			dw kw_cpnevv, var_starttask_s, var_starttask_t
			dw kw_goto_iffalse_n, if94_1
			dw kw_strcpy, stmp1, str47
			dw kw_strcat, stmp1, var_a
			dw p_putln_c, var_starttask_s, stmp1
if94_1:

			; Main.bas 1086: Install s
			dw p_install_c, var_starttask_s

			; Main.bas 1087: n = Hyp.FileCall(103, rest, s, sg(s), &H100, 0, VarPtr(rb))  ' at #0100, rest bytes at most
			dw kw_aget, arr_sg, var_starttask_s, tmp3
			dw p_hyp_filecall_c, lit_103, var_starttask_rest, var_starttask_s, tmp3, lit_256, lit_0, vp_arr_rb
			dw kw_vtov, var_hyp_filecall_filecall, var_starttask_n

			; Main.bas 1088: HClose
			dw p_hclose_c

			; Main.bas 1096: Memory.WriteWord Far(s, &HF2FC), Hyp.Info(4)
			dw p_far_c, var_starttask_s, lit_m3332
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_hyp_info, lit_4, var_hyp_info_info
			dw kw_vtov, var_hyp_info_info, tmp1
			dw fn_memory_writeword, ltmp0, tmp1

			; Main.bas 1097: Memory.WriteWord Far(s, &HF2FE), 0
			dw p_far_c, var_starttask_s, lit_m3330
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writeword, ltmp0, lit_0

			; Main.bas 1098: Memory.WriteWord Far(s, &HFFFE), &HF2FC
			dw p_far_c, var_starttask_s, lit_m2
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writeword, ltmp0, lit_m3332

			; Main.bas 1100: If b = "" Then
			dw kw_strcmpeq, var_b, str2
			dw kw_goto_iffalse_n, if95_1

			; Main.bas 1101: Memory.WriteByte Far(s, &H80), 0
			dw p_far_c, var_starttask_s, lit_128
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writebyte, ltmp0, lit_0

			; Main.bas 1102: Else
			dw if95_e_go
if95_1:

			; Main.bas 1103: b = " " + b
			dw kw_strcpy, stmp0, str20
			dw kw_strcat, stmp0, var_b
			dw kw_strcpy, var_b, stmp0

			; Main.bas 1104: Memory.Copy NearP(VarPtr(b)), Far(s, &H81), Len(b)
			dw p_nearp_c, vp_var_b
			dw kw_l_mov, var_nearp_nearp, ltmp0
			dw p_far_c, var_starttask_s, lit_129
			dw kw_l_mov, var_far_far, ltmp1
			dw kw_strlen, var_b, tmp2
			dw fn_memory_copy, ltmp0, ltmp1, tmp2, var_memory_copy_copy

			; Main.bas 1105: Memory.WriteByte Far(s, &H80), Len(b)
			dw p_far_c, var_starttask_s, lit_128
			dw kw_l_mov, var_far_far, ltmp0
			dw kw_strlen, var_b, tmp1
			dw fn_memory_writebyte, ltmp0, tmp1

			; Main.bas 1106: Memory.WriteByte Far(s, &H81 + Len(b)), 0
			dw kw_strlen, var_b, tmp2
			dw kw_addl, tmp2, 129, tmp1
			dw p_far_c, var_starttask_s, tmp1
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writebyte, ltmp0, lit_0

			; Main.bas 1107: End If
if95_e:

			; Main.bas 1108: Memory.WriteByte Far(s, NMLEN), Len(a)
			dw p_far_c, var_starttask_s, lit_m2344
			dw kw_l_mov, var_far_far, ltmp0
			dw kw_strlen, var_a, tmp1
			dw fn_memory_writebyte, ltmp0, tmp1

			; Main.bas 1109: Memory.Copy NearP(VarPtr(a)), Far(s, NMBUF), Len(a)
			dw p_nearp_c, vp_var_a
			dw kw_l_mov, var_nearp_nearp, ltmp0
			dw p_far_c, var_starttask_s, lit_m2343
			dw kw_l_mov, var_far_far, ltmp1
			dw kw_strlen, var_a, tmp2
			dw fn_memory_copy, ltmp0, ltmp1, tmp2, var_memory_copy_copy

			; Main.bas 1110: kq(s) = 0
			dw kw_asetl, arr_kq, var_starttask_s, 0

			; Main.bas 1111: Memory.WriteByte Far(s, &HF685), 0             ' no escape sequence rest half done
			dw p_far_c, var_starttask_s, lit_m2427
			dw kw_l_mov, var_far_far, ltmp0
			dw fn_memory_writebyte, ltmp0, lit_0

			; Main.bas 1112: wk(s) = -1
			dw kw_asetl, arr_wk, var_starttask_s, -1

			; Main.bas 1113: dm(s) = &H80                                   ' CP/M's record buffer to start with
			dw kw_asetl, arr_dm, var_starttask_s, 128

			; Main.bas 1114: st(s) = 2
			dw kw_asetl, arr_st, var_starttask_s, 2

			; Main.bas 1115: If s <> t Then PutLn t, a + " runs in slot" + Str$(s)
			dw kw_cpnevv, var_starttask_s, var_starttask_t
			dw kw_goto_iffalse_n, if96_1
			dw kw_strcpy, stmp1, var_a
			dw kw_strcat, stmp1, str48
			dw kw_strstr, stmp2, var_starttask_s
			dw kw_strcat, stmp1, stmp2
			dw p_putln_c, var_starttask_t, stmp1
if96_1:
			dw p_starttask_r

ntc_rg36_e:
			IF ($ < 32768) && (ntc_rg37_e - ntc_rg37 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg37:
; ============================================================
; sub notfound (normal mode)
; ============================================================

p_notfound:

			; Main.bas 1119: If bare Then PutLn t, "? " + a + " (HELP)" Else PutLn t, a + ": not found"
			dw kw_goto_ifzero_n, var_bare, if97_1
			dw kw_strcpy, stmp1, str49
			dw kw_strcat, stmp1, var_a
			dw kw_strcat, stmp1, str50
			dw p_putln_c, var_notfound_t, stmp1
			dw if97_e_go
if97_1:
			dw kw_strcpy, stmp1, var_a
			dw kw_strcat, stmp1, str51
			dw p_putln_c, var_notfound_t, stmp1
if97_e:
			dw p_notfound_r

ntc_rg37_e:
			IF ($ < 32768) && (ntc_rg38_e - ntc_rg38 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg38:
; ============================================================
; sub endtask (normal mode)
; ============================================================

p_endtask:

			; Main.bas 1133: Dim c As Integer

			; Main.bas 1134: FilesShut t
			dw p_filesshut_c, var_endtask_t

			; Main.bas 1139: st(t) = 1
			dw kw_asetl, arr_st, var_endtask_t, 1

			; Main.bas 1140: runs = runs + 1
			dw kw_inc, var_runs

			; Main.bas 1141: PutLn t, ""
			dw p_putln_c, var_endtask_t, str2

			; Main.bas 1142: GetNm t
			dw p_getnm_c, var_endtask_t

			; Main.bas 1143: PutLn t, "[" + en + " ended]"
			dw kw_strcpy, stmp1, str10
			dw kw_strcat, stmp1, var_en
			dw kw_strcat, stmp1, str52
			dw p_putln_c, var_endtask_t, stmp1

			; Main.bas 1144: If wt <> t Then Prompt t                       ' (WAIT: the prompt when nothing runs)
			dw kw_cpnevv, var_wt, var_endtask_t
			dw kw_goto_iffalse_n, if98_1
			dw p_prompt_c, var_endtask_t
if98_1:

			; Main.bas 1145: c = kq(t) : kq(t) = 0
			dw kw_aget, arr_kq, var_endtask_t, var_endtask_c
			dw kw_asetl, arr_kq, var_endtask_t, 0

			; Main.bas 1146: If c <> 0 And t = front Then pk = c    ' a key typed for it after its last look: the command line's
			dw kw_cpnevl, var_endtask_c, 0
			dw kw_ftov, tmp0
			dw kw_cpeqvv, var_endtask_t, var_front
			dw kw_ftov, tmp1
			dw kw_andvv, tmp0, tmp1, tmp0
			dw kw_goto_ifzero_n, tmp0, if99_1
			dw kw_vtov, var_endtask_c, var_pk
if99_1:
			dw p_endtask_r

ntc_rg38_e:
			IF ($ < 32768) && (ntc_rg39_e - ntc_rg39 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg39:
; ============================================================
; sub con (normal mode)
; ============================================================

p_hyp_con:

			; Hyp.cls 283: #asm
			dw asm_1_283_n
			dw p_hyp_con_r

ntc_rg39_e:
			IF ($ < 32768) && (ntc_rg40_e - ntc_rg40 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg40:
; ============================================================
; sub say (normal mode)
; ============================================================

p_hyp_say:

			; Hyp.cls 1414: #asm
			dw asm_1_1414_n
			dw p_hyp_say_r

ntc_rg40_e:
			IF ($ < 32768) && (ntc_rg41_e - ntc_rg41 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg41:
; ============================================================
; function scr (normal mode)
; ============================================================

p_hyp_scr:

			; Hyp.cls 1508: #asm
			dw asm_1_1508_n
			dw p_hyp_scr_r

ntc_rg41_e:
			IF ($ < 32768) && (ntc_rg42_e - ntc_rg42 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg42:
; ============================================================
; sub keyrep (normal mode)
; ============================================================

p_hyp_keyrep:

			; Hyp.cls 1610: #asm
			dw asm_1_1610_n
			dw p_hyp_keyrep_r

ntc_rg42_e:
			IF ($ < 32768) && (ntc_rg43_e - ntc_rg43 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg43:
; ============================================================
; sub show (normal mode)
; ============================================================

p_hyp_show:

			; Hyp.cls 1650: Con pg, 0, -1, 1
			dw p_hyp_con_c, var_hyp_show_pg, lit_0, lit_m1, lit_1
			dw p_hyp_show_r

ntc_rg43_e:
			IF ($ < 32768) && (ntc_rg44_e - ntc_rg44 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg44:
; ============================================================
; sub reply (normal mode)
; ============================================================

p_hyp_reply:

			; Hyp.cls 1656: ra = a : rhl = hl
			dw kw_vtov, var_hyp_reply_a, var_hyp_ra
			dw kw_vtov, var_hyp_reply_hl, var_hyp_rhl
			dw p_hyp_reply_r

ntc_rg44_e:
			IF ($ < 32768) && (ntc_rg45_e - ntc_rg45 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg45:
; ============================================================
; function fn (normal mode)
; ============================================================

p_hyp_fn:

			; Hyp.cls 1660: Fn = rfn And 255
			dw kw_andvl, var_hyp_rfn, 255, var_hyp_fn_fn
			dw p_hyp_fn_r

ntc_rg45_e:
			IF ($ < 32768) && (ntc_rg46_e - ntc_rg46 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg46:
; ============================================================
; function arg (normal mode)
; ============================================================

p_hyp_arg:

			; Hyp.cls 1664: Arg = rde
			dw kw_vtov, var_hyp_rde, var_hyp_arg_arg
			dw p_hyp_arg_r

ntc_rg46_e:
			IF ($ < 32768) && (ntc_rg47_e - ntc_rg47 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg47:
; ============================================================
; function count (normal mode)
; ============================================================

p_hyp_count:

			; Hyp.cls 1669: Count = rcnt
			dw kw_vtov, var_hyp_rcnt, var_hyp_count_count
			dw p_hyp_count_r

ntc_rg47_e:
			IF ($ < 32768) && (ntc_rg48_e - ntc_rg48 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg48:
; ============================================================
; function run (normal mode)
; ============================================================

p_hyp_run:

			; Hyp.cls 1674: #asm
			dw asm_1_1674_n
			dw p_hyp_run_r

ntc_rg48_e:
			IF ($ < 32768) && (ntc_rg49_e - ntc_rg49 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg49:
; ============================================================
; sub vdu (normal mode)
; ============================================================

p_hyp_vdu:

			; Hyp.cls 2347: #asm
			dw asm_1_2347_n
			dw p_hyp_vdu_r

ntc_rg49_e:
			IF ($ < 32768) && (ntc_rg50_e - ntc_rg50 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg50:
; ============================================================
; function filecall (normal mode)
; ============================================================

p_hyp_filecall:

			; Hyp.cls 2379: #asm
			dw asm_1_2379_n
			dw p_hyp_filecall_r

ntc_rg50_e:
			IF ($ < 32768) && (ntc_rg51_e - ntc_rg51 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg51:
; ============================================================
; sub fileshut (normal mode)
; ============================================================

p_hyp_fileshut:

			; Hyp.cls 3930: #asm
			dw asm_1_3930_n
			dw p_hyp_fileshut_r

ntc_rg51_e:
			IF ($ < 32768) && (ntc_rg52_e - ntc_rg52 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg52:
; ============================================================
; sub speed (normal mode)
; ============================================================

p_hot_speed:

			; Hot.cls 19: If f < 1 Then f = 1
			dw kw_scpltvl, var_hot_speed_f, 1
			dw kw_goto_iffalse_n, if100_1
			dw kw_ltov, 1, var_hot_speed_f
if100_1:

			; Hot.cls 20: If f > 40 Then f = 40
			dw kw_scpgtvl, var_hot_speed_f, 40
			dw kw_goto_iffalse_n, if101_1
			dw kw_ltov, 40, var_hot_speed_f
if101_1:

			; Hot.cls 21: dbl = DOUBLE * f
			dw kw_mulvl, var_hot_speed_f, 15, var_hot_dbl
			dw p_hot_speed_r

ntc_rg52_e:
			IF ($ < 32768) && (ntc_rg53_e - ntc_rg53 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg53:
; ============================================================
; sub slots (normal mode)
; ============================================================

p_hot_slots:

			; Hot.cls 25: ns = n
			dw kw_vtov, var_hot_slots_n, var_hot_ns
			dw p_hot_slots_r

ntc_rg53_e:
			IF ($ < 32768) && (ntc_rg54_e - ntc_rg54 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg54:
; ============================================================
; sub tick (normal mode)
; ============================================================

p_hot_tick:

			; Hot.cls 29: Dim k As Integer

			; Hot.cls 30: ctl = Keys.Down(Keys.KeyControl)
			dw fn_keys_down, lit_23, var_hot_ctl

			; Hot.cls 31: If ctl Then
			dw kw_goto_ifzero_n, var_hot_ctl, if102_1

			; Hot.cls 32: If Keys.Down(64) Then k = 1
			dw fn_keys_down, lit_64, var_keys_down_down
			dw kw_goto_ifzero_n, var_keys_down_down, if103_1
			dw kw_ltov, 1, var_hot_tick_k
if103_1:

			; Hot.cls 33: If Keys.Down(65) Then k = 2
			dw fn_keys_down, lit_65, var_keys_down_down
			dw kw_goto_ifzero_n, var_keys_down_down, if104_1
			dw kw_ltov, 2, var_hot_tick_k
if104_1:

			; Hot.cls 34: If Keys.Down(57) Then k = 3
			dw fn_keys_down, lit_57, var_keys_down_down
			dw kw_goto_ifzero_n, var_keys_down_down, if105_1
			dw kw_ltov, 3, var_hot_tick_k
if105_1:

			; Hot.cls 35: If Keys.Down(56) Then k = 4
			dw fn_keys_down, lit_56, var_keys_down_down
			dw kw_goto_ifzero_n, var_keys_down_down, if106_1
			dw kw_ltov, 4, var_hot_tick_k
if106_1:

			; Hot.cls 36: If Keys.Down(49) Then k = 5
			dw fn_keys_down, lit_49, var_keys_down_down
			dw kw_goto_ifzero_n, var_keys_down_down, if107_1
			dw kw_ltov, 5, var_hot_tick_k
if107_1:

			; Hot.cls 37: If Keys.Down(48) Then k = 6
			dw fn_keys_down, lit_48, var_keys_down_down
			dw kw_goto_ifzero_n, var_keys_down_down, if108_1
			dw kw_ltov, 6, var_hot_tick_k
if108_1:

			; Hot.cls 38: If Keys.Down(41) Then k = 7
			dw fn_keys_down, lit_41, var_keys_down_down
			dw kw_goto_ifzero_n, var_keys_down_down, if109_1
			dw kw_ltov, 7, var_hot_tick_k
if109_1:

			; Hot.cls 39: If Keys.Down(40) Then k = 8
			dw fn_keys_down, lit_40, var_keys_down_down
			dw kw_goto_ifzero_n, var_keys_down_down, if110_1
			dw kw_ltov, 8, var_hot_tick_k
if110_1:

			; Hot.cls 40: If Keys.Down(33) Then k = 9
			dw fn_keys_down, lit_33, var_keys_down_down
			dw kw_goto_ifzero_n, var_keys_down_down, if111_1
			dw kw_ltov, 9, var_hot_tick_k
if111_1:

			; Hot.cls 41: If Keys.Down(32) Then k = 10
			dw fn_keys_down, lit_32, var_keys_down_down
			dw kw_goto_ifzero_n, var_keys_down_down, if112_1
			dw kw_ltov, 10, var_hot_tick_k
if112_1:

			; Hot.cls 42: If Keys.Down(Keys.KeyEsc) Then k = TOPKEY
			dw fn_keys_down, lit_66, var_keys_down_down
			dw kw_goto_ifzero_n, var_keys_down_down, if113_1
			dw kw_ltov, 99, var_hot_tick_k
if113_1:

			; Hot.cls 43: End If
if102_1:

			; Hot.cls 44: If k <> 0 And k <> last Then
			dw kw_cpnevl, var_hot_tick_k, 0
			dw kw_ftov, tmp5
			dw kw_cpnevv, var_hot_tick_k, var_hot_last
			dw kw_ftov, tmp6
			dw kw_andvv, tmp5, tmp6, tmp5
			dw kw_goto_ifzero_n, tmp5, if114_1

			; Hot.cls 45: If k = TOPKEY Or ns <= 10 Then
			dw kw_cpeqvl, var_hot_tick_k, 99
			dw kw_ftov, tmp5
			dw kw_scplevl, var_hot_ns, 10
			dw kw_ftov, tmp6
			dw kw_orvv, tmp5, tmp6, tmp5
			dw kw_goto_ifzero_n, tmp5, if115_1

			; Hot.cls 46: If one <> 0 Then one = 0
			dw kw_cpnevl, var_hot_one, 0
			dw kw_goto_iffalse_n, if116_1
			dw kw_ztov, var_hot_one
if116_1:

			; Hot.cls 47: pend = k                          ' at once (no double taps to wait for)
			dw kw_vtov, var_hot_tick_k, var_hot_pend

			; Hot.cls 48: ElseIf one = k Then
			dw if115_e_go
if115_1:
			dw kw_cpeqvv, var_hot_one, var_hot_tick_k
			dw kw_goto_iffalse_n, if115_2

			; Hot.cls 49: one = 0
			dw kw_ztov, var_hot_one

			; Hot.cls 50: If k + 10 <= ns Then pend = k + 10 Else pend = k  ' the second press: slot 11-20
			dw kw_addl, var_hot_tick_k, 10, tmp5
			dw kw_scplevv, tmp5, var_hot_ns
			dw kw_goto_iffalse_n, if117_1
			dw kw_addl, var_hot_tick_k, 10, var_hot_pend
			dw if115_e_go
if117_1:
			dw kw_vtov, var_hot_tick_k, var_hot_pend
if117_e:

			; Hot.cls 51: Else
			dw if115_e_go
if115_2:

			; Hot.cls 52: If one <> 0 Then pend = one       ' another number: the waiting one counts now
			dw kw_cpnevl, var_hot_one, 0
			dw kw_goto_iffalse_n, if118_1
			dw kw_vtov, var_hot_one, var_hot_pend
if118_1:

			; Hot.cls 53: one = k : age = 0
			dw kw_vtov, var_hot_tick_k, var_hot_one
			dw kw_ztov, var_hot_age

			; Hot.cls 54: End If
if115_e:

			; Hot.cls 55: End If
if114_1:

			; Hot.cls 56: If one <> 0 Then
			dw kw_cpnevl, var_hot_one, 0
			dw kw_goto_iffalse_n, if119_1

			; Hot.cls 57: age = age + 1
			dw kw_inc, var_hot_age

			; Hot.cls 58: If dbl = 0 Then dbl = DOUBLE
			dw kw_cpeqvl, var_hot_dbl, 0
			dw kw_goto_iffalse_n, if120_1
			dw kw_ltov, 15, var_hot_dbl
if120_1:

			; Hot.cls 59: If age > dbl Or ctl = 0 Then pend = one : one = 0       ' no second press (or Control let go)
			dw kw_scpgtvv, var_hot_age, var_hot_dbl
			dw kw_ftov, tmp5
			dw kw_cpeqvl, var_hot_ctl, 0
			dw kw_ftov, tmp6
			dw kw_orvv, tmp5, tmp6, tmp5
			dw kw_goto_ifzero_n, tmp5, if121_1
			dw kw_vtov, var_hot_one, var_hot_pend
			dw kw_ztov, var_hot_one
if121_1:

			; Hot.cls 60: End If
if119_1:

			; Hot.cls 61: last = k
			dw kw_vtov, var_hot_tick_k, var_hot_last
			dw p_hot_tick_r

ntc_rg54_e:
			IF ($ < 32768) && (ntc_rg55_e - ntc_rg55 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg55:
; ============================================================
; function take (normal mode)
; ============================================================

p_hot_take:

			; Hot.cls 65: Take = pend
			dw kw_vtov, var_hot_pend, var_hot_take_take

			; Hot.cls 66: pend = 0
			dw kw_ztov, var_hot_pend
			dw p_hot_take_r

ntc_rg55_e:
			IF ($ < 32768) && (ntc_rg56_e - ntc_rg56 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg56:
; ============================================================
; function control (normal mode)
; ============================================================

p_hot_control:

			; Hot.cls 71: Control = ctl
			dw kw_vtov, var_hot_ctl, var_hot_control_control
			dw p_hot_control_r

ntc_rg56_e:
			IF ($ < 32768) && (ntc_rg57_e - ntc_rg57 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg57:
; ============================================================
; function held (normal mode)
; ============================================================

p_hot_held:

			; Hot.cls 77: Held = last
			dw kw_vtov, var_hot_last, var_hot_held_held
			dw p_hot_held_r

ntc_rg57_e:
			IF ($ < 32768) && (ntc_rg58_e - ntc_rg58 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg58:
; ============================================================
; function bankpage (normal mode)
; ============================================================

p_memory_bankpage:

			; Memory.cls 452: BankPage = 4 * bank - 2 + n
			dw kw_4x, var_memory_bankpage_bank, tmp1
			dw kw_addl, tmp1, -2, tmp1
			dw kw_add, tmp1, var_memory_bankpage_n, var_memory_bankpage_bankpage
			dw p_memory_bankpage_r

; ============================================================
; Jump stubs (code, ROMable)
;   label_go: GOTO label
;   label_gs: GOSUB label, return point -> label_rs (RAM)
;   label_rt: RETURN from label
;   p_name_c: call a procedure, p_name_r: end of it
;   turbo mode ends with ret, normal mode with jp ntc_xn
; ============================================================

do5_t_go:			ld sp, do5_t
			jp ntc_xn
if9_e_go:			ld sp, if9_e
			jp ntc_xn
if11_e_go:			ld sp, if11_e
			jp ntc_xn
for25_e_go:			ld sp, for25_e
			jp ntc_xn
do33_e_go:			ld sp, do33_e
			jp ntc_xn
do33_t_go:			ld sp, do33_t
			jp ntc_xn
sel42_e_go:			ld sp, sel42_e
			jp ntc_xn
ch51_e_go:			ld sp, ch51_e
			jp ntc_xn
if50_e_go:			ld sp, if50_e
			jp ntc_xn
ch55_e_go:			ld sp, ch55_e
			jp ntc_xn
ch56_e_go:			ld sp, ch56_e
			jp ntc_xn
ch57_e_go:			ld sp, ch57_e
			jp ntc_xn
if62_e_go:			ld sp, if62_e
			jp ntc_xn
if64_e_go:			ld sp, if64_e
			jp ntc_xn
ch66_e_go:			ld sp, ch66_e
			jp ntc_xn
if67_e_go:			ld sp, if67_e
			jp ntc_xn
if69_e_go:			ld sp, if69_e
			jp ntc_xn
if71_e_go:			ld sp, if71_e
			jp ntc_xn
if75_e_go:			ld sp, if75_e
			jp ntc_xn
sel81_e_go:			ld sp, sel81_e
			jp ntc_xn
if88_e_go:			ld sp, if88_e
			jp ntc_xn
do87_e_go:			ld sp, do87_e
			jp ntc_xn
if95_e_go:			ld sp, if95_e
			jp ntc_xn
if97_e_go:			ld sp, if97_e
			jp ntc_xn
if115_e_go:			ld sp, if115_e
			jp ntc_xn

p_running_c:		; call running (normal)
			ld hl, 0
			ld (var_running_running), hl
			ld hl, 0
			ld (var_running_j), hl
			ld (p_running_rs), sp
			ld sp, p_running
			jp ntc_xn
p_running_r:		; end of running
			ld sp, (p_running_rs)
			jp ntc_xn
p_ready_c:		; call ready (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_ready_t), de
			ld hl, 0
			ld (var_ready_ready), hl
			ld (p_ready_rs), sp
			ld sp, p_ready
			jp ntc_xn
p_ready_r:		; end of ready
			ld sp, (p_ready_rs)
			jp ntc_xn
p_runnext_c:		; call runnext (normal)
			ld hl, 0
			ld (var_runnext_n), hl
			ld hl, 0
			ld (var_runnext_t), hl
			ld hl, 0
			ld (var_runnext_r), hl
			ld hl, 0
			ld (var_runnext_c), hl
			ld hl, 0
			ld (var_runnext_q), hl
			ld (p_runnext_rs), sp
			ld sp, p_runnext
			jp ntc_xn
p_runnext_r:		; end of runnext
			ld sp, (p_runnext_rs)
			jp ntc_xn
p_bdos_c:		; call bdos (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_bdos_t), de
			ld hl, 0
			ld (var_bdos_f), hl
			ld hl, 0
			ld (var_bdos_e), hl
			ld hl, 0
			ld (var_bdos_a), hl
			ld (p_bdos_rs), sp
			ld sp, p_bdos
			jp ntc_xn
p_bdos_r:		; end of bdos
			ld sp, (p_bdos_rs)
			jp ntc_xn
p_sys_c:		; call sys (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_sys_t), de
			pop hl			; p
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_sys_p), de
			ld hl, 0
			ld (var_sys_sys), hl
			ld hl, 0
			ld (var_sys_o), hl
			ld hl, 0
			ld (var_sys_s), hl
			ld hl, 0
			ld (var_sys_d), hl
			ld (p_sys_rs), sp
			ld sp, p_sys
			jp ntc_xn
p_sys_r:		; end of sys
			ld sp, (p_sys_rs)
			jp ntc_xn
p_puten_c:		; call puten (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_puten_t), de
			pop hl			; a
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_puten_a), de
			ld (p_puten_rs), sp
			ld sp, p_puten
			jp ntc_xn
p_puten_r:		; end of puten
			ld sp, (p_puten_rs)
			jp ntc_xn
p_hopen_c:		; call hopen (normal)
			ld hl, 0
			ld (var_hopen_hopen), hl
			ld (p_hopen_rs), sp
			ld sp, p_hopen
			jp ntc_xn
p_hopen_r:		; end of hopen
			ld sp, (p_hopen_rs)
			jp ntc_xn
p_hclose_c:		; call hclose (normal)
			ld hl, 0
			ld (var_hclose_r), hl
			ld (p_hclose_rs), sp
			ld sp, p_hclose
			jp ntc_xn
p_hclose_r:		; end of hclose
			ld sp, (p_hclose_rs)
			jp ntc_xn
p_filesshut_c:		; call filesshut (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_filesshut_t), de
			ld hl, 0
			ld (var_filesshut_r), hl
			ld (p_filesshut_rs), sp
			ld sp, p_filesshut
			jp ntc_xn
p_filesshut_r:		; end of filesshut
			ld sp, (p_filesshut_rs)
			jp ntc_xn
p_collected_c:		; call collected (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_collected_t), de
			pop hl			; n
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_collected_n), de
			ld (p_collected_rs), sp
			ld sp, p_collected
			jp ntc_xn
p_collected_r:		; end of collected
			ld sp, (p_collected_rs)
			jp ntc_xn
p_puts_c:		; call puts (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_puts_t), de
			pop hl			; s
			ld de, var_puts_s
			ld b, 255
p_puts_si1:
			ld a, (hl)
			ld (de), a
			or a
			jr z, p_puts_si1_e
			inc hl
			inc de
			djnz p_puts_si1
			xor a
			ld (de), a
p_puts_si1_e:
			ld (p_puts_rs), sp
			ld sp, p_puts
			jp ntc_xn
p_puts_r:		; end of puts
			ld sp, (p_puts_rs)
			jp ntc_xn
p_putln_c:		; call putln (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_putln_t), de
			pop hl			; s
			ld de, var_putln_s
			ld b, 255
p_putln_si1:
			ld a, (hl)
			ld (de), a
			or a
			jr z, p_putln_si1_e
			inc hl
			inc de
			djnz p_putln_si1
			xor a
			ld (de), a
p_putln_si1_e:
			ld (p_putln_rs), sp
			ld sp, p_putln
			jp ntc_xn
p_putln_r:		; end of putln
			ld sp, (p_putln_rs)
			jp ntc_xn
p_putc_c:		; call putc (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_putc_t), de
			pop hl			; c
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_putc_c), de
			ld (p_putc_rs), sp
			ld sp, p_putc
			jp ntc_xn
p_putc_r:		; end of putc
			ld sp, (p_putc_rs)
			jp ntc_xn
p_nearp_c:		; call nearp (normal)
			pop hl			; p
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_nearp_p), de
			ld hl, 0
			ld (var_nearp_nearp), hl
			ld (var_nearp_nearp+2), hl
			ld (p_nearp_rs), sp
			ld sp, p_nearp
			jp ntc_xn
p_nearp_r:		; end of nearp
			ld sp, (p_nearp_rs)
			jp ntc_xn
p_far_c:		; call far (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_far_t), de
			pop hl			; a
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_far_a), de
			ld hl, 0
			ld (var_far_far), hl
			ld (var_far_far+2), hl
			ld (p_far_rs), sp
			ld sp, p_far
			jp ntc_xn
p_far_r:		; end of far
			ld sp, (p_far_rs)
			jp ntc_xn
p_clst_c:		; call clst (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_clst_t), de
			ld (p_clst_rs), sp
			ld sp, p_clst
			jp ntc_xn
p_clst_r:		; end of clst
			ld sp, (p_clst_rs)
			jp ntc_xn
p_tofront_c:		; call tofront (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_tofront_t), de
			ld hl, 0
			ld (var_tofront_r), hl
			ld (p_tofront_rs), sp
			ld sp, p_tofront
			jp ntc_xn
p_tofront_r:		; end of tofront
			ld sp, (p_tofront_rs)
			jp ntc_xn
p_setmode_c:		; call setmode (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_setmode_t), de
			pop hl			; m
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_setmode_m), de
			ld hl, 0
			ld (var_setmode_r), hl
			ld (p_setmode_rs), sp
			ld sp, p_setmode
			jp ntc_xn
p_setmode_r:		; end of setmode
			ld sp, (p_setmode_rs)
			jp ntc_xn
p_showtop_c:		; call showtop (normal)
			ld hl, 0
			ld (var_showtop_j), hl
			ld (p_showtop_rs), sp
			ld sp, p_showtop
			jp ntc_xn
p_showtop_r:		; end of showtop
			ld sp, (p_showtop_rs)
			jp ntc_xn
p_toplines_c:		; call toplines (normal)
			pop hl			; mark
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_toplines_mark), de
			pop hl			; keys
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_toplines_keys), de
			ld hl, 0
			ld (var_toplines_j), hl
			xor a
			ld (var_toplines_s), a
			ld (p_toplines_rs), sp
			ld sp, p_toplines
			jp ntc_xn
p_toplines_r:		; end of toplines
			ld sp, (p_toplines_rs)
			jp ntc_xn
p_totals_c:		; call totals (normal)
			ld (p_totals_rs), sp
			ld sp, p_totals
			jp ntc_xn
p_totals_r:		; end of totals
			ld sp, (p_totals_rs)
			jp ntc_xn
p_topadd_c:		; call topadd (normal)
			pop hl			; s
			ld de, var_topadd_s
			ld b, 255
p_topadd_si0:
			ld a, (hl)
			ld (de), a
			or a
			jr z, p_topadd_si0_e
			inc hl
			inc de
			djnz p_topadd_si0
			xor a
			ld (de), a
p_topadd_si0_e:
			ld (p_topadd_rs), sp
			ld sp, p_topadd
			jp ntc_xn
p_topadd_r:		; end of topadd
			ld sp, (p_topadd_rs)
			jp ntc_xn
p_roll_c:		; call roll (normal)
			ld hl, 0
			ld (var_roll_j), hl
			ld (p_roll_rs), sp
			ld sp, p_roll
			jp ntc_xn
p_roll_r:		; end of roll
			ld sp, (p_roll_rs)
			jp ntc_xn
p_pad_c:		; call pad (normal)
			pop hl			; v
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_pad_v), de
			xor a
			ld (var_pad_pad), a
			ld (p_pad_rs), sp
			ld sp, p_pad
			jp ntc_xn
p_pad_r:		; end of pad
			ld sp, (p_pad_rs)
			jp ntc_xn
p_rate_c:		; call rate (normal)
			pop hl			; n
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_rate_n), de
			pop hl			; d
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_rate_d), de
			ld hl, 0
			ld (var_rate_rate), hl
			ld (p_rate_rs), sp
			ld sp, p_rate
			jp ntc_xn
p_rate_r:		; end of rate
			ld sp, (p_rate_rs)
			jp ntc_xn
p_install_c:		; call install (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_install_t), de
			ld hl, 0
			ld (var_install_p), hl
			ld hl, 0
			ld (var_install_n), hl
			ld (p_install_rs), sp
			ld sp, p_install
			jp ntc_xn
p_install_r:		; end of install
			ld sp, (p_install_rs)
			jp ntc_xn
p_resetslot_c:		; call resetslot (normal)
			pop hl			; s
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_resetslot_s), de
			ld (p_resetslot_rs), sp
			ld sp, p_resetslot
			jp ntc_xn
p_resetslot_r:		; end of resetslot
			ld sp, (p_resetslot_rs)
			jp ntc_xn
p_openslot_c:		; call openslot (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_openslot_t), de
			ld (p_openslot_rs), sp
			ld sp, p_openslot
			jp ntc_xn
p_openslot_r:		; end of openslot
			ld sp, (p_openslot_rs)
			jp ntc_xn
p_sk_c:		; call sk (normal)
			xor a
			ld (var_sk_sk), a
			ld (p_sk_rs), sp
			ld sp, p_sk
			jp ntc_xn
p_sk_r:		; end of sk
			ld sp, (p_sk_rs)
			jp ntc_xn
p_getnm_c:		; call getnm (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_getnm_t), de
			ld hl, 0
			ld (var_getnm_n), hl
			ld (p_getnm_rs), sp
			ld sp, p_getnm
			jp ntc_xn
p_getnm_r:		; end of getnm
			ld sp, (p_getnm_rs)
			jp ntc_xn
p_n_c:		; call n (normal)
			pop hl			; v
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_n_v), de
			xor a
			ld (var_n_n), a
			ld (p_n_rs), sp
			ld sp, p_n
			jp ntc_xn
p_n_r:		; end of n
			ld sp, (p_n_rs)
			jp ntc_xn
p_prompt_c:		; call prompt (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_prompt_t), de
			ld (p_prompt_rs), sp
			ld sp, p_prompt
			jp ntc_xn
p_prompt_r:		; end of prompt
			ld sp, (p_prompt_rs)
			jp ntc_xn
p_keyin_c:		; call keyin (normal)
			pop hl			; k
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_keyin_k), de
			ld hl, 0
			ld (var_keyin_t), hl
			ld hl, 0
			ld (var_keyin_n), hl
			ld (p_keyin_rs), sp
			ld sp, p_keyin
			jp ntc_xn
p_keyin_r:		; end of keyin
			ld sp, (p_keyin_rs)
			jp ntc_xn
p_command_c:		; call command (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_command_t), de
			xor a
			ld (var_command_c), a
			ld hl, 0
			ld (var_command_p), hl
			ld hl, 0
			ld (var_command_s), hl
			ld (p_command_rs), sp
			ld sp, p_command
			jp ntc_xn
p_command_r:		; end of command
			ld sp, (p_command_rs)
			jp ntc_xn
p_starttask_c:		; call starttask (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_starttask_t), de
			pop hl			; s
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_starttask_s), de
			ld hl, 0
			ld (var_starttask_h), hl
			ld hl, 0
			ld (var_starttask_n), hl
			ld hl, 0
			ld (var_starttask_rest), hl
			ld hl, 0
			ld (var_starttask_com), hl
			xor a
			ld (var_starttask_w), a
			ld hl, 0
			ld (var_starttask_d), hl
			ld (p_starttask_rs), sp
			ld sp, p_starttask
			jp ntc_xn
p_starttask_r:		; end of starttask
			ld sp, (p_starttask_rs)
			jp ntc_xn
p_notfound_c:		; call notfound (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_notfound_t), de
			ld (p_notfound_rs), sp
			ld sp, p_notfound
			jp ntc_xn
p_notfound_r:		; end of notfound
			ld sp, (p_notfound_rs)
			jp ntc_xn
p_endtask_c:		; call endtask (normal)
			pop hl			; t
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_endtask_t), de
			ld hl, 0
			ld (var_endtask_c), hl
			ld (p_endtask_rs), sp
			ld sp, p_endtask
			jp ntc_xn
p_endtask_r:		; end of endtask
			ld sp, (p_endtask_rs)
			jp ntc_xn
p_hyp_con_c:		; call con (normal)
			pop hl			; pg
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_con_pg), de
			pop hl			; src
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_con_src), de
			pop hl			; n
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_con_n), de
			pop hl			; front
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_con_front), de
			ld (p_hyp_con_rs), sp
			ld sp, p_hyp_con
			jp ntc_xn
p_hyp_con_r:		; end of con
			ld sp, (p_hyp_con_rs)
			jp ntc_xn
p_hyp_say_c:		; call say (normal)
			pop hl			; p
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_say_p), de
			pop hl			; n
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_say_n), de
			pop hl			; col
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_say_col), de
			pop hl			; row
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_say_row), de
			ld (p_hyp_say_rs), sp
			ld sp, p_hyp_say
			jp ntc_xn
p_hyp_say_r:		; end of say
			ld sp, (p_hyp_say_rs)
			jp ntc_xn
p_hyp_scr_c:		; call scr (normal)
			pop hl			; m
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_scr_m), de
			pop hl			; k
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_scr_k), de
			ld hl, 0
			ld (var_hyp_scr_scr), hl
			ld (p_hyp_scr_rs), sp
			ld sp, p_hyp_scr
			jp ntc_xn
p_hyp_scr_r:		; end of scr
			ld sp, (p_hyp_scr_rs)
			jp ntc_xn
p_hyp_keyrep_c:		; call keyrep (normal)
			pop hl			; f
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_keyrep_f), de
			ld (p_hyp_keyrep_rs), sp
			ld sp, p_hyp_keyrep
			jp ntc_xn
p_hyp_keyrep_r:		; end of keyrep
			ld sp, (p_hyp_keyrep_rs)
			jp ntc_xn
p_hyp_show_c:		; call show (normal)
			pop hl			; pg
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_show_pg), de
			ld (p_hyp_show_rs), sp
			ld sp, p_hyp_show
			jp ntc_xn
p_hyp_show_r:		; end of show
			ld sp, (p_hyp_show_rs)
			jp ntc_xn
p_hyp_reply_c:		; call reply (normal)
			pop hl			; a
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_reply_a), de
			pop hl			; hl
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_reply_hl), de
			ld (p_hyp_reply_rs), sp
			ld sp, p_hyp_reply
			jp ntc_xn
p_hyp_reply_r:		; end of reply
			ld sp, (p_hyp_reply_rs)
			jp ntc_xn
p_hyp_fn_c:		; call fn (normal)
			ld hl, 0
			ld (var_hyp_fn_fn), hl
			ld (p_hyp_fn_rs), sp
			ld sp, p_hyp_fn
			jp ntc_xn
p_hyp_fn_r:		; end of fn
			ld sp, (p_hyp_fn_rs)
			jp ntc_xn
p_hyp_arg_c:		; call arg (normal)
			ld hl, 0
			ld (var_hyp_arg_arg), hl
			ld (p_hyp_arg_rs), sp
			ld sp, p_hyp_arg
			jp ntc_xn
p_hyp_arg_r:		; end of arg
			ld sp, (p_hyp_arg_rs)
			jp ntc_xn
p_hyp_count_c:		; call count (normal)
			ld hl, 0
			ld (var_hyp_count_count), hl
			ld (p_hyp_count_rs), sp
			ld sp, p_hyp_count
			jp ntc_xn
p_hyp_count_r:		; end of count
			ld sp, (p_hyp_count_rs)
			jp ntc_xn
p_hyp_run_c:		; call run (normal)
			pop hl			; setting
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_run_setting), de
			ld hl, 0
			ld (var_hyp_run_run), hl
			ld (p_hyp_run_rs), sp
			ld sp, p_hyp_run
			jp ntc_xn
p_hyp_run_r:		; end of run
			ld sp, (p_hyp_run_rs)
			jp ntc_xn
p_hyp_vdu_c:		; call vdu (normal)
			pop hl			; on
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_vdu_on), de
			ld (p_hyp_vdu_rs), sp
			ld sp, p_hyp_vdu
			jp ntc_xn
p_hyp_vdu_r:		; end of vdu
			ld sp, (p_hyp_vdu_rs)
			jp ntc_xn
p_hyp_filecall_c:		; call filecall (normal)
			pop hl			; f
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_filecall_f), de
			pop hl			; fcb
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_filecall_fcb), de
			pop hl			; slot
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_filecall_slot), de
			pop hl			; setting
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_filecall_setting), de
			pop hl			; dma
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_filecall_dma), de
			pop hl			; drive
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_filecall_drive), de
			pop hl			; buf
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_filecall_buf), de
			ld hl, 0
			ld (var_hyp_filecall_filecall), hl
			ld (p_hyp_filecall_rs), sp
			ld sp, p_hyp_filecall
			jp ntc_xn
p_hyp_filecall_r:		; end of filecall
			ld sp, (p_hyp_filecall_rs)
			jp ntc_xn
p_hyp_fileshut_c:		; call fileshut (normal)
			pop hl			; slot
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hyp_fileshut_slot), de
			ld (p_hyp_fileshut_rs), sp
			ld sp, p_hyp_fileshut
			jp ntc_xn
p_hyp_fileshut_r:		; end of fileshut
			ld sp, (p_hyp_fileshut_rs)
			jp ntc_xn
p_hot_speed_c:		; call speed (normal)
			pop hl			; f
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hot_speed_f), de
			ld (p_hot_speed_rs), sp
			ld sp, p_hot_speed
			jp ntc_xn
p_hot_speed_r:		; end of speed
			ld sp, (p_hot_speed_rs)
			jp ntc_xn
p_hot_slots_c:		; call slots (normal)
			pop hl			; n
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_hot_slots_n), de
			ld (p_hot_slots_rs), sp
			ld sp, p_hot_slots
			jp ntc_xn
p_hot_slots_r:		; end of slots
			ld sp, (p_hot_slots_rs)
			jp ntc_xn
p_hot_tick_c:		; call tick (normal)
			ld hl, 0
			ld (var_hot_tick_k), hl
			ld (p_hot_tick_rs), sp
			ld sp, p_hot_tick
			jp ntc_xn
p_hot_tick_r:		; end of tick
			xor a			; Tick done: it may run again
			ld (ntc_isl + 4), a
			ld sp, (p_hot_tick_rs)
			jp ntc_xn
p_hot_take_c:		; call take (normal)
			ld hl, 0
			ld (var_hot_take_take), hl
			ld (p_hot_take_rs), sp
			ld sp, p_hot_take
			jp ntc_xn
p_hot_take_r:		; end of take
			ld sp, (p_hot_take_rs)
			jp ntc_xn
p_hot_control_c:		; call control (normal)
			ld hl, 0
			ld (var_hot_control_control), hl
			ld (p_hot_control_rs), sp
			ld sp, p_hot_control
			jp ntc_xn
p_hot_control_r:		; end of control
			ld sp, (p_hot_control_rs)
			jp ntc_xn
p_hot_held_c:		; call held (normal)
			ld hl, 0
			ld (var_hot_held_held), hl
			ld (p_hot_held_rs), sp
			ld sp, p_hot_held
			jp ntc_xn
p_hot_held_r:		; end of held
			ld sp, (p_hot_held_rs)
			jp ntc_xn
p_memory_bankpage_c:		; call bankpage (normal)
			pop hl			; bank
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_memory_bankpage_bank), de
			pop hl			; n
			ld e, (hl)
			inc hl
			ld d, (hl)
			ld (var_memory_bankpage_n), de
			ld hl, 0
			ld (var_memory_bankpage_bankpage), hl
			ld (p_memory_bankpage_rs), sp
			ld sp, p_memory_bankpage
			jp ntc_xn
p_memory_bankpage_r:		; end of bankpage
			ld sp, (p_memory_bankpage_rs)
			jp ntc_xn

ntc_rg58_e:
			IF ($ < 32768) && (ntc_rg59_e - ntc_rg59 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg59:
; ============================================================
; Inline assembly (#asm ... #endasm)
; ============================================================

fn_hyp_usepage:		; sub usepage (asm keyword), Hyp.cls line 50
            ld hl, (ntc_rampt)		; Hyp.cls 51
            ld (var_hyp_hps), hl		; Hyp.cls 52
			ret			; end of #asm

fn_hyp_setting:		; function setting (asm keyword), Hyp.cls line 98
            ld de, (ntc_rampt)		; Hyp.cls 99
            ld a, e		; Hyp.cls 100
            and #F8		; Hyp.cls 101
            or 2		; Hyp.cls 102
            ld e, a		; Hyp.cls 103
            pop hl		; Hyp.cls 104
            ld (hl), e		; Hyp.cls 105
            inc hl		; Hyp.cls 106
            ld (hl), d		; Hyp.cls 107
			ret			; end of #asm

fn_hyp_farptr:		; function farptr (asm keyword), Hyp.cls line 114
            pop hl		; Hyp.cls 115
            ld c, (hl)		; Hyp.cls 116
            inc hl		; Hyp.cls 117
            ld b, (hl)              ; BC = page [118]
            pop hl		; Hyp.cls 119
            ld e, (hl)		; Hyp.cls 120
            inc hl		; Hyp.cls 121
            ld a, (hl)		; Hyp.cls 122
            and #3F		; Hyp.cls 123
            or #40		; Hyp.cls 124
            ld d, a                 ; DE = #4000 + the address's low 14 bits [125]
            pop hl		; Hyp.cls 126
            ld (hl), e		; Hyp.cls 127
            inc hl		; Hyp.cls 128
            ld (hl), d		; Hyp.cls 129
            inc hl		; Hyp.cls 130
            ld (hl), c		; Hyp.cls 131
            inc hl		; Hyp.cls 132
            ld (hl), b		; Hyp.cls 133
			ret			; end of #asm

fn_hyp_fontinit:		; sub fontinit (asm keyword), Hyp.cls line 167
            ld (var_hyp_hsp), sp		; Hyp.cls 168
            ld sp, (ntc_csp)		; Hyp.cls 169
            ld bc, (var_hyp_hps)		; Hyp.cls 170
            out (c), c		; Hyp.cls 171
            ld de, 32               ; D = 0: a table, E = its first character [172]
            ld hl, #4000 + 4096		; Hyp.cls 173
            call #BBAB              ; TXT SET M TABLE (the matrices from 32 on, copied there) [174]
            di		; Hyp.cls 175
            ld de, #FF00            ; D <> 0: no table of its own any more [176]
            call #BBAB		; Hyp.cls 177
            di		; Hyp.cls 178
            ld bc, (ntc_rampt)		; Hyp.cls 179
            out (c), c		; Hyp.cls 180
            ld sp, (var_hyp_hsp)		; Hyp.cls 181
			ret			; end of #asm

asm_1_283_n:		; #asm, Hyp.cls line 283 (normal)
; CN_SB 1: the scrollback (Shift + Up / Down: 48 rows a slot, kept in a 16K page Main gives - #If
; SCROLLBACK in Main.bas, set the two together). Off for now: 526 bytes of main RAM (2026-10-16)
asm_1_283_n_CN_SB:      equ 0		; Hyp.cls 286
            ld (var_hyp_hsp), sp		; Hyp.cls 287
            ld sp, (ntc_csp)		; Hyp.cls 288
            ld bc, (var_hyp_con_pg)		; Hyp.cls 289
            out (c), c              ; the slot's page 3 at #4000: OBUF #7600, state #7682, page #7700 [290]
            IF asm_1_283_n_CN_SB		; Hyp.cls 291
            ld (asm_1_283_n_cn_pg), bc		; Hyp.cls 292
            ENDIF		; Hyp.cls 293
            xor a		; Hyp.cls 294
            ld (asm_1_283_n_cn_pv), a		; Hyp.cls 295
            ld a, (var_hyp_con_front)		; Hyp.cls 296
            ld (asm_1_283_n_cn_front), a		; Hyp.cls 297
            ld a, (#7687)           ; its columns and rows (MODE) [298]
            ld (asm_1_283_n_cn_c), a		; Hyp.cls 299
            ld a, (#7688)		; Hyp.cls 300
            ld (asm_1_283_n_cn_r), a		; Hyp.cls 301
            ld a, (var_hyp_ccu)           ; the cursor off first, whatever comes (it was on: cn_was) [302]
            ld (asm_1_283_n_cn_was), a		; Hyp.cls 303
            or a		; Hyp.cls 304
            call nz, asm_1_283_n_cn_cuxor		; Hyp.cls 305
            ld hl, (var_hyp_con_n)		; Hyp.cls 306
            bit 7, h		; Hyp.cls 307
            jp nz, asm_1_283_n_cn_neg		; Hyp.cls 308
            ld (asm_1_283_n_cn_left), hl		; Hyp.cls 309
            IF asm_1_283_n_CN_SB		; Hyp.cls 310
            ld a, (asm_1_283_n_cn_front)        ; in front and looking back (scrollback): the page again first [311]
            or a		; Hyp.cls 312
            jr z, asm_1_283_n_cn_live		; Hyp.cls 313
            ld a, (#7F26)		; Hyp.cls 314
            or a		; Hyp.cls 315
            jr z, asm_1_283_n_cn_live		; Hyp.cls 316
            xor a		; Hyp.cls 317
            ld (#7F26), a		; Hyp.cls 318
            call asm_1_283_n_cn_cls		; Hyp.cls 319
            call asm_1_283_n_cn_strip		; Hyp.cls 320
            call asm_1_283_n_cn_draw		; Hyp.cls 321
            ld hl, (asm_1_283_n_cn_left)		; Hyp.cls 322
asm_1_283_n_cn_live:		; Hyp.cls 323
            ENDIF		; Hyp.cls 324
            ld hl, (var_hyp_con_src)		; Hyp.cls 325
            ld a, h		; Hyp.cls 326
            or l		; Hyp.cls 327
            jr nz, asm_1_283_n_cn_src		; Hyp.cls 328
            ld hl, #7600            ; src 0: the characters the program collected (OBUF) [329]
asm_1_283_n_cn_src:		; Hyp.cls 330
            ld (asm_1_283_n_cn_ptr), hl		; Hyp.cls 331
asm_1_283_n_cn_lp:		; Hyp.cls 332
            ld hl, (asm_1_283_n_cn_left)		; Hyp.cls 333
            ld a, h		; Hyp.cls 334
            or l		; Hyp.cls 335
            jr z, asm_1_283_n_cn_done		; Hyp.cls 336
            dec hl		; Hyp.cls 337
            ld (asm_1_283_n_cn_left), hl		; Hyp.cls 338
            ld hl, (asm_1_283_n_cn_ptr)		; Hyp.cls 339
            ld a, (hl)		; Hyp.cls 340
            inc hl		; Hyp.cls 341
            ld (asm_1_283_n_cn_ptr), hl		; Hyp.cls 342
            call asm_1_283_n_cn_char		; Hyp.cls 343
            jr asm_1_283_n_cn_lp		; Hyp.cls 344
asm_1_283_n_cn_done:		; Hyp.cls 345
            ld bc, (ntc_rampt)      ; the window's page back [346]
            out (c), c		; Hyp.cls 347
            ld sp, (var_hyp_hsp)		; Hyp.cls 348
            jp asm_1_283_n_cn_end		; Hyp.cls 349

; n < 0: -1 the whole page to the screen (it was cleared: Show), not looking back any more; -2
; the scrollback (src: the key - #F4 Shift + Up a screen back, #F5 Shift + Down one on), drawn
asm_1_283_n_cn_neg:		; Hyp.cls 353
            ld a, l		; Hyp.cls 354
            cp #FD                  ; -3: the cursor flashes - on (it was off), an underline XORed [355]
            jr nz, asm_1_283_n_cn_neg1          ; where the next character goes; off (it was on: done above) [356]
            ld a, (asm_1_283_n_cn_front)		; Hyp.cls 357
            or a		; Hyp.cls 358
            jr z, asm_1_283_n_cn_done		; Hyp.cls 359
            ld a, (var_hyp_nta)           ; the network blink: advance it (0.5s) while there's traffic [360]
            or a		; Hyp.cls 361
            jr z, asm_1_283_n_cn_nt1		; Hyp.cls 362
            dec a		; Hyp.cls 363
            ld (var_hyp_nta), a		; Hyp.cls 364
            ld a, (var_hyp_ntb)		; Hyp.cls 365
            xor 1		; Hyp.cls 366
            ld (var_hyp_ntb), a		; Hyp.cls 367
asm_1_283_n_cn_nt1:		; Hyp.cls 368
            call asm_1_283_n_cn_net		; Hyp.cls 369
            ld a, (asm_1_283_n_cn_was)		; Hyp.cls 370
            or a		; Hyp.cls 371
            jr nz, asm_1_283_n_cn_done		; Hyp.cls 372
            ld a, (#7682)		; Hyp.cls 373
            ld d, a		; Hyp.cls 374
            ld a, (#7683)		; Hyp.cls 375
            ld e, a		; Hyp.cls 376
            call asm_1_283_n_cn_scr		; Hyp.cls 377
            ld a, h		; Hyp.cls 378
            add a, #38              ; (its cell's last pixel line) [379]
            ld h, a		; Hyp.cls 380
            ld (asm_1_283_n_cn_ca), hl		; Hyp.cls 381
            call asm_1_283_n_cn_cuxor		; Hyp.cls 382
            jr asm_1_283_n_cn_done		; Hyp.cls 383
asm_1_283_n_cn_neg1:		; Hyp.cls 384
            IF asm_1_283_n_CN_SB		; Hyp.cls 385
            inc hl		; Hyp.cls 386
            ld a, h		; Hyp.cls 387
            or l		; Hyp.cls 388
            jr nz, asm_1_283_n_cn_view		; Hyp.cls 389
            ld (#7F26), a		; Hyp.cls 390
            ENDIF		; Hyp.cls 391
asm_1_283_n_cn_show:		; Hyp.cls 392
            call asm_1_283_n_cn_strip		; Hyp.cls 393
            call asm_1_283_n_cn_draw		; Hyp.cls 394
            jr asm_1_283_n_cn_done		; Hyp.cls 395
            IF asm_1_283_n_CN_SB		; Hyp.cls 396
asm_1_283_n_cn_view:		; Hyp.cls 397
            ld a, (#7F21)           ; (no history page: nothing) [398]
            or a		; Hyp.cls 399
            jr z, asm_1_283_n_cn_done		; Hyp.cls 400
            ld a, (asm_1_283_n_cn_r)		; Hyp.cls 401
            dec a		; Hyp.cls 402
            ld b, a                 ; a screen: its rows - 1 [403]
            ld a, (var_hyp_con_src)		; Hyp.cls 404
            cp #F4		; Hyp.cls 405
            ld a, (#7F26)		; Hyp.cls 406
            jr nz, asm_1_283_n_cn_vw_dn		; Hyp.cls 407
            add a, b		; Hyp.cls 408
            ld hl, #7F25		; Hyp.cls 409
            cp (hl)		; Hyp.cls 410
            jr c, asm_1_283_n_cn_vw_set		; Hyp.cls 411
            ld a, (hl)              ; (not past the oldest row kept) [412]
            jr asm_1_283_n_cn_vw_set		; Hyp.cls 413
asm_1_283_n_cn_vw_dn:		; Hyp.cls 414
            sub b		; Hyp.cls 415
            jr nc, asm_1_283_n_cn_vw_set		; Hyp.cls 416
            xor a		; Hyp.cls 417
asm_1_283_n_cn_vw_set:		; Hyp.cls 418
            ld hl, #7F26		; Hyp.cls 419
            cp (hl)		; Hyp.cls 420
            jr z, asm_1_283_n_cn_done		; Hyp.cls 421
            ld (hl), a		; Hyp.cls 422
            call asm_1_283_n_cn_cls		; Hyp.cls 423
            jr asm_1_283_n_cn_show		; Hyp.cls 424

            ENDIF		; Hyp.cls 426

; the screen's rows: the page's - or, looking back (#FF26 rows), the history's first, then the
; page's. Row e shows line count + e - back of history + page (count the rows kept, #FF25)
asm_1_283_n_cn_draw:		; Hyp.cls 430
            ld e, 0		; Hyp.cls 431
            IF asm_1_283_n_CN_SB		; Hyp.cls 432
asm_1_283_n_cn_dr_row:		; Hyp.cls 433
            push de		; Hyp.cls 434
            ld a, (#7F25)		; Hyp.cls 435
            add a, e		; Hyp.cls 436
            ld hl, #7F26		; Hyp.cls 437
            sub (hl)                ; the line: count + e - back [438]
            ld hl, #7F25		; Hyp.cls 439
            sub (hl)		; Hyp.cls 440
            jr c, asm_1_283_n_cn_dr_h		; Hyp.cls 441
            call asm_1_283_n_cn_rowa            ; HL = row (line - count) of the page [442]
            ld a, (asm_1_283_n_cn_c)		; Hyp.cls 443
            jr asm_1_283_n_cn_dr_go		; Hyp.cls 444
asm_1_283_n_cn_dr_h:		; Hyp.cls 445
            add a, (hl)		; Hyp.cls 446
            call asm_1_283_n_cn_hget            ; HL = the history's row (copied in), 80 characters at most [447]
            ld a, (asm_1_283_n_cn_c)		; Hyp.cls 448
            cp asm_1_283_n_HW		; Hyp.cls 449
            jr c, asm_1_283_n_cn_dr_go		; Hyp.cls 450
            ld a, asm_1_283_n_HW		; Hyp.cls 451
asm_1_283_n_cn_dr_go:		; Hyp.cls 452
            ld b, a		; Hyp.cls 453
            pop de		; Hyp.cls 454
            push de		; Hyp.cls 455
            ld d, 0		; Hyp.cls 456
asm_1_283_n_cn_dr_col:		; Hyp.cls 457
            ld a, (hl)		; Hyp.cls 458
            inc hl		; Hyp.cls 459
            cp 33		; Hyp.cls 460
            jr c, asm_1_283_n_cn_dr_sk		; Hyp.cls 461
            push hl		; Hyp.cls 462
            push de		; Hyp.cls 463
            push bc		; Hyp.cls 464
            call asm_1_283_n_cn_glyph		; Hyp.cls 465
            pop bc		; Hyp.cls 466
            pop de		; Hyp.cls 467
            pop hl		; Hyp.cls 468
asm_1_283_n_cn_dr_sk:		; Hyp.cls 469
            inc d		; Hyp.cls 470
            djnz asm_1_283_n_cn_dr_col		; Hyp.cls 471
            pop de		; Hyp.cls 472
            inc e		; Hyp.cls 473
            ld a, (asm_1_283_n_cn_r)		; Hyp.cls 474
            dec a		; Hyp.cls 475
            cp e		; Hyp.cls 476
            jr nc, asm_1_283_n_cn_dr_row		; Hyp.cls 477
            ret		; Hyp.cls 478
            ELSE		; Hyp.cls 479
asm_1_283_n_cn_sh_row:                          ; (no scrollback: the page's rows as they are) [480]
            push de		; Hyp.cls 481
            ld a, e		; Hyp.cls 482
            call asm_1_283_n_cn_rowa            ; HL = row e of the page [483]
            pop de		; Hyp.cls 484
            ld d, 0		; Hyp.cls 485
asm_1_283_n_cn_sh_col:		; Hyp.cls 486
            ld a, (hl)		; Hyp.cls 487
            inc hl		; Hyp.cls 488
            cp 33		; Hyp.cls 489
            jr c, asm_1_283_n_cn_sh_skip		; Hyp.cls 490
            push hl		; Hyp.cls 491
            push de		; Hyp.cls 492
            call asm_1_283_n_cn_glyph		; Hyp.cls 493
            pop de		; Hyp.cls 494
            pop hl		; Hyp.cls 495
asm_1_283_n_cn_sh_skip:		; Hyp.cls 496
            inc d		; Hyp.cls 497
            ld a, (asm_1_283_n_cn_c)		; Hyp.cls 498
            dec a		; Hyp.cls 499
            cp d		; Hyp.cls 500
            jr nc, asm_1_283_n_cn_sh_col		; Hyp.cls 501
            inc e		; Hyp.cls 502
            ld a, (asm_1_283_n_cn_r)		; Hyp.cls 503
            dec a		; Hyp.cls 504
            cp e		; Hyp.cls 505
            jr nc, asm_1_283_n_cn_sh_row		; Hyp.cls 506
            ret		; Hyp.cls 507
            ENDIF		; Hyp.cls 508

            IF asm_1_283_n_CN_SB		; Hyp.cls 510
; the scrollback: each row that scrolls off the top of the page - its first HW characters - goes
; to the slot's history: HROWS rows (a ring) in a 16K page of its own that Main gave it (#FF20:
; its RAM setting, 0 none; #FF22 where in it; #FF24 the next row written, #FF25 how many, #FF26
; how far back the screen looks). Copied 8 bytes at a time through the stack - only the window
; changes, so no main RAM for a buffer
asm_1_283_n_HW:         equ 80		; Hyp.cls 516
asm_1_283_n_HROWS:      equ 48		; Hyp.cls 517
asm_1_283_n_cn_hput:                            ; HL = the row going (the page) [518]
            ld a, (#7F21)		; Hyp.cls 519
            or a		; Hyp.cls 520
            ret z		; Hyp.cls 521
            ld (asm_1_283_n_cn_hs), hl		; Hyp.cls 522
            ld hl, (asm_1_283_n_cn_pg)		; Hyp.cls 523
            ld (asm_1_283_n_cn_h1), hl		; Hyp.cls 524
            ld hl, (#7F20)		; Hyp.cls 525
            ld (asm_1_283_n_cn_h2), hl		; Hyp.cls 526
            ld a, (#7F24)		; Hyp.cls 527
            call asm_1_283_n_cn_haddr		; Hyp.cls 528
            ld (asm_1_283_n_cn_hd), hl		; Hyp.cls 529
            ld hl, #7F24            ; the next row on, one more kept [530]
            ld a, (hl)		; Hyp.cls 531
            inc a		; Hyp.cls 532
            cp asm_1_283_n_HROWS		; Hyp.cls 533
            jr c, asm_1_283_n_cn_hp_h		; Hyp.cls 534
            xor a		; Hyp.cls 535
asm_1_283_n_cn_hp_h:		; Hyp.cls 536
            ld (hl), a		; Hyp.cls 537
            inc hl		; Hyp.cls 538
            ld a, (hl)		; Hyp.cls 539
            cp asm_1_283_n_HROWS		; Hyp.cls 540
            jr nc, asm_1_283_n_cn_hcp		; Hyp.cls 541
            inc (hl)		; Hyp.cls 542
; cn_hcp: HW bytes from cn_hs in RAM setting cn_h1 to cn_hd in cn_h2, then the slot's page back
asm_1_283_n_cn_hcp:		; Hyp.cls 544
            ld a, asm_1_283_n_HW / 8		; Hyp.cls 545
asm_1_283_n_cn_hc_lp:		; Hyp.cls 546
            ld (asm_1_283_n_cn_hn), a		; Hyp.cls 547
            ld bc, (asm_1_283_n_cn_h1)		; Hyp.cls 548
            out (c), c		; Hyp.cls 549
            ld hl, (asm_1_283_n_cn_hs)		; Hyp.cls 550
            ld b, 4		; Hyp.cls 551
asm_1_283_n_cn_hc_in:		; Hyp.cls 552
            ld e, (hl)		; Hyp.cls 553
            inc hl		; Hyp.cls 554
            ld d, (hl)		; Hyp.cls 555
            inc hl		; Hyp.cls 556
            push de		; Hyp.cls 557
            djnz asm_1_283_n_cn_hc_in		; Hyp.cls 558
            ld (asm_1_283_n_cn_hs), hl		; Hyp.cls 559
            ld bc, (asm_1_283_n_cn_h2)		; Hyp.cls 560
            out (c), c		; Hyp.cls 561
            ld hl, (asm_1_283_n_cn_hd)		; Hyp.cls 562
            ld de, 8		; Hyp.cls 563
            add hl, de		; Hyp.cls 564
            ld (asm_1_283_n_cn_hd), hl		; Hyp.cls 565
            ld b, 4		; Hyp.cls 566
asm_1_283_n_cn_hc_out:		; Hyp.cls 567
            pop de		; Hyp.cls 568
            dec hl		; Hyp.cls 569
            ld (hl), d		; Hyp.cls 570
            dec hl		; Hyp.cls 571
            ld (hl), e		; Hyp.cls 572
            djnz asm_1_283_n_cn_hc_out		; Hyp.cls 573
            ld a, (asm_1_283_n_cn_hn)		; Hyp.cls 574
            dec a		; Hyp.cls 575
            jr nz, asm_1_283_n_cn_hc_lp		; Hyp.cls 576
            ld bc, (asm_1_283_n_cn_pg)		; Hyp.cls 577
            out (c), c		; Hyp.cls 578
            ret		; Hyp.cls 579
asm_1_283_n_cn_hget:                            ; A = a line of the history (0 the oldest kept): copied to [580]
            ld hl, #7F24            ; #FF30 in the slot's page (HL) [581]
            add a, (hl)		; Hyp.cls 582
            inc hl		; Hyp.cls 583
            sub (hl)		; Hyp.cls 584
            jr nc, asm_1_283_n_cn_hg_r		; Hyp.cls 585
            add a, asm_1_283_n_HROWS		; Hyp.cls 586
asm_1_283_n_cn_hg_r:		; Hyp.cls 587
            call asm_1_283_n_cn_haddr		; Hyp.cls 588
            ld (asm_1_283_n_cn_hs), hl		; Hyp.cls 589
            ld hl, (#7F20)		; Hyp.cls 590
            ld (asm_1_283_n_cn_h1), hl		; Hyp.cls 591
            ld hl, (asm_1_283_n_cn_pg)		; Hyp.cls 592
            ld (asm_1_283_n_cn_h2), hl		; Hyp.cls 593
            ld hl, #7F30		; Hyp.cls 594
            ld (asm_1_283_n_cn_hd), hl		; Hyp.cls 595
            call asm_1_283_n_cn_hcp		; Hyp.cls 596
            ld hl, #7F30		; Hyp.cls 597
            ret		; Hyp.cls 598
asm_1_283_n_cn_haddr:                           ; A = a history row: HL = its address in the history page [599]
            ld e, a		; Hyp.cls 600
            ld a, asm_1_283_n_HW		; Hyp.cls 601
            call asm_1_283_n_cn_mul		; Hyp.cls 602
            ld de, (#7F22)		; Hyp.cls 603
            add hl, de		; Hyp.cls 604
            ret		; Hyp.cls 605
; cn_cls: the screen cleared (written only: the Library: ROM build's keyword ROM may be over it)
asm_1_283_n_cn_cls:		; Hyp.cls 607
            ld hl, #C000		; Hyp.cls 608
            ld bc, #4000		; Hyp.cls 609
asm_1_283_n_cn_cl_lp:		; Hyp.cls 610
            ld (hl), 0		; Hyp.cls 611
            inc hl		; Hyp.cls 612
            dec bc		; Hyp.cls 613
            ld a, b		; Hyp.cls 614
            or c		; Hyp.cls 615
            jr nz, asm_1_283_n_cn_cl_lp		; Hyp.cls 616
            ret		; Hyp.cls 617
            ENDIF		; Hyp.cls 618

; cn_char: A = one character
asm_1_283_n_cn_char:		; Hyp.cls 621
            ld b, a		; Hyp.cls 622
            ld a, (#7685)           ; in an escape sequence? [623]
            or a		; Hyp.cls 624
            jr nz, asm_1_283_n_cn_esc0		; Hyp.cls 625
            ld a, b		; Hyp.cls 626
            cp 32		; Hyp.cls 627
            jp nc, asm_1_283_n_cn_print		; Hyp.cls 628
            ld hl, asm_1_283_n_cn_pv            ; a control code: the cursor may move (the pointers redone) [629]
            ld (hl), 0		; Hyp.cls 630
            cp 27		; Hyp.cls 631
            jr z, asm_1_283_n_cn_setesc		; Hyp.cls 632
            cp 13		; Hyp.cls 633
            jr z, asm_1_283_n_cn_cr		; Hyp.cls 634
            cp 10		; Hyp.cls 635
            jp z, asm_1_283_n_cn_nl		; Hyp.cls 636
            cp 9		; Hyp.cls 637
            jr z, asm_1_283_n_cn_tab		; Hyp.cls 638
            cp 8		; Hyp.cls 639
            ret nz                  ; other control codes: nothing [640]
            ld a, (#7682)           ; BS: back one (not past the start of the row) [641]
            or a		; Hyp.cls 642
            ret z		; Hyp.cls 643
            dec a		; Hyp.cls 644
            ld (#7682), a		; Hyp.cls 645
            ret		; Hyp.cls 646
asm_1_283_n_cn_tab:                             ; TAB: spaces to the next column of 8 [647]
            ld b, ' '		; Hyp.cls 648
            call asm_1_283_n_cn_print		; Hyp.cls 649
            ld a, (#7682)		; Hyp.cls 650
            and 7		; Hyp.cls 651
            jr nz, asm_1_283_n_cn_tab		; Hyp.cls 652
            ret		; Hyp.cls 653
asm_1_283_n_cn_setesc:		; Hyp.cls 654
            ld a, 1		; Hyp.cls 655
            ld (#7685), a		; Hyp.cls 656
            ret		; Hyp.cls 657
asm_1_283_n_cn_cr:		; Hyp.cls 658
            xor a		; Hyp.cls 659
            ld (#7682), a		; Hyp.cls 660
            ret		; Hyp.cls 661
asm_1_283_n_cn_esc0:		; Hyp.cls 662
            ld hl, asm_1_283_n_cn_pv		; Hyp.cls 663
            ld (hl), 0		; Hyp.cls 664
asm_1_283_n_cn_esc:		; Hyp.cls 665
            cp 1		; Hyp.cls 666
            jr nz, asm_1_283_n_cn_esc2		; Hyp.cls 667
            xor a                   ; ESC x [668]
            ld (#7685), a		; Hyp.cls 669
            ld a, b		; Hyp.cls 670
            cp 'E'		; Hyp.cls 671
            jp z, asm_1_283_n_cn_clear		; Hyp.cls 672
            cp 'H'		; Hyp.cls 673
            jr z, asm_1_283_n_cn_home		; Hyp.cls 674
            cp 'I'		; Hyp.cls 675
            jp z, asm_1_283_n_cn_rev		; Hyp.cls 676
            cp 'Y'		; Hyp.cls 677
            jr z, asm_1_283_n_cn_sety		; Hyp.cls 678
            cp 'A'		; Hyp.cls 679
            jr z, asm_1_283_n_cn_up		; Hyp.cls 680
            cp 'B'		; Hyp.cls 681
            jr z, asm_1_283_n_cn_down		; Hyp.cls 682
            cp 'C'		; Hyp.cls 683
            jr z, asm_1_283_n_cn_right		; Hyp.cls 684
            cp 'D'		; Hyp.cls 685
            jr z, asm_1_283_n_cn_lft		; Hyp.cls 686
            cp 'K'		; Hyp.cls 687
            jp z, asm_1_283_n_cn_eol		; Hyp.cls 688
            cp 'J'		; Hyp.cls 689
            jp z, asm_1_283_n_cn_eos		; Hyp.cls 690
            cp 'l'		; Hyp.cls 691
            jp z, asm_1_283_n_cn_eln		; Hyp.cls 692
            cp 'o'		; Hyp.cls 693
            jp z, asm_1_283_n_cn_sol		; Hyp.cls 694
            cp 'd'		; Hyp.cls 695
            jp z, asm_1_283_n_cn_sos		; Hyp.cls 696
            cp 'M'		; Hyp.cls 697
            jp z, asm_1_283_n_cn_dell		; Hyp.cls 698
            cp 'L'		; Hyp.cls 699
            jp z, asm_1_283_n_cn_insl		; Hyp.cls 700
            ret                     ; (the rest - e f j k p q ...: nothing) [701]
asm_1_283_n_cn_sety:		; Hyp.cls 702
            ld a, 2		; Hyp.cls 703
            ld (#7685), a		; Hyp.cls 704
            ret		; Hyp.cls 705
asm_1_283_n_cn_up:                              ; ESC A, B, C, D: up, down, right, left (not past the edge) [706]
            ld hl, #7683		; Hyp.cls 707
            jr asm_1_283_n_cn_dec		; Hyp.cls 708
asm_1_283_n_cn_lft:		; Hyp.cls 709
            ld hl, #7682		; Hyp.cls 710
asm_1_283_n_cn_dec:		; Hyp.cls 711
            ld a, (hl)		; Hyp.cls 712
            or a		; Hyp.cls 713
            ret z		; Hyp.cls 714
            dec (hl)		; Hyp.cls 715
            ret		; Hyp.cls 716
asm_1_283_n_cn_down:		; Hyp.cls 717
            ld de, #7683		; Hyp.cls 718
            ld hl, asm_1_283_n_cn_r		; Hyp.cls 719
            jr asm_1_283_n_cn_inc		; Hyp.cls 720
asm_1_283_n_cn_right:		; Hyp.cls 721
            ld de, #7682		; Hyp.cls 722
            ld hl, asm_1_283_n_cn_c		; Hyp.cls 723
asm_1_283_n_cn_inc:		; Hyp.cls 724
            ld a, (de)		; Hyp.cls 725
            inc a		; Hyp.cls 726
            cp (hl)		; Hyp.cls 727
            ret nc		; Hyp.cls 728
            ld (de), a		; Hyp.cls 729
            ret		; Hyp.cls 730
asm_1_283_n_cn_home:		; Hyp.cls 731
            xor a		; Hyp.cls 732
            ld (#7682), a		; Hyp.cls 733
            ld (#7683), a		; Hyp.cls 734
            ret		; Hyp.cls 735
asm_1_283_n_cn_esc2:		; Hyp.cls 736
            cp 2		; Hyp.cls 737
            jr nz, asm_1_283_n_cn_esc3		; Hyp.cls 738
            ld a, b                 ; ESC Y row [739]
            sub 32		; Hyp.cls 740
            ld (#7686), a		; Hyp.cls 741
            ld a, 3		; Hyp.cls 742
            ld (#7685), a		; Hyp.cls 743
            ret		; Hyp.cls 744
asm_1_283_n_cn_esc3:		; Hyp.cls 745
            xor a                   ; ESC Y row col [746]
            ld (#7685), a		; Hyp.cls 747
            ld a, b		; Hyp.cls 748
            sub 32		; Hyp.cls 749
            ld hl, asm_1_283_n_cn_c		; Hyp.cls 750
            cp (hl)		; Hyp.cls 751
            jr c, asm_1_283_n_cn_e3_col		; Hyp.cls 752
            xor a		; Hyp.cls 753
asm_1_283_n_cn_e3_col:		; Hyp.cls 754
            ld (#7682), a		; Hyp.cls 755
            ld a, (#7686)		; Hyp.cls 756
            ld hl, asm_1_283_n_cn_r		; Hyp.cls 757
            cp (hl)		; Hyp.cls 758
            jr c, asm_1_283_n_cn_e3_row		; Hyp.cls 759
            xor a		; Hyp.cls 760
asm_1_283_n_cn_e3_row:		; Hyp.cls 761
            ld (#7683), a		; Hyp.cls 762
            ret		; Hyp.cls 763

; a printable character (B): into the page, on the screen if in front, the column on. The page
; and screen pointers are worked out at the first character after the cursor moved (cn_pv 0),
; then just stepped on - a run of characters costs the 8 screen bytes each, not a sum each
asm_1_283_n_cn_print:		; Hyp.cls 768
            ld a, (asm_1_283_n_cn_pv)		; Hyp.cls 769
            or a		; Hyp.cls 770
            jr nz, asm_1_283_n_cn_pr_have		; Hyp.cls 771
            ld a, (#7683)		; Hyp.cls 772
            call asm_1_283_n_cn_rowa		; Hyp.cls 773
            ld a, (#7682)		; Hyp.cls 774
            ld e, a		; Hyp.cls 775
            ld d, 0		; Hyp.cls 776
            add hl, de		; Hyp.cls 777
            ld (asm_1_283_n_cn_pp), hl		; Hyp.cls 778
            ld a, (asm_1_283_n_cn_front)		; Hyp.cls 779
            or a		; Hyp.cls 780
            jr z, asm_1_283_n_cn_pr_set		; Hyp.cls 781
            ld a, (#7682)		; Hyp.cls 782
            ld d, a		; Hyp.cls 783
            ld a, (#7683)		; Hyp.cls 784
            ld e, a		; Hyp.cls 785
            push bc                 ; (B: the character) [786]
            call asm_1_283_n_cn_scr		; Hyp.cls 787
            pop bc		; Hyp.cls 788
            ld (asm_1_283_n_cn_sp), hl		; Hyp.cls 789
asm_1_283_n_cn_pr_set:		; Hyp.cls 790
            ld a, 1		; Hyp.cls 791
            ld (asm_1_283_n_cn_pv), a		; Hyp.cls 792
asm_1_283_n_cn_pr_have:		; Hyp.cls 793
            ld hl, (asm_1_283_n_cn_pp)          ; the page [794]
            ld (hl), b		; Hyp.cls 795
            inc hl		; Hyp.cls 796
            ld (asm_1_283_n_cn_pp), hl		; Hyp.cls 797
            ld a, (asm_1_283_n_cn_front)		; Hyp.cls 798
            or a		; Hyp.cls 799
            jr z, asm_1_283_n_cn_pr_adv		; Hyp.cls 800
            ld hl, (asm_1_283_n_cn_sp)          ; the screen [801]
            push hl		; Hyp.cls 802
            ld a, b		; Hyp.cls 803
            call asm_1_283_n_cn_glyph8		; Hyp.cls 804
            pop hl		; Hyp.cls 805
            call asm_1_283_n_cn_next		; Hyp.cls 806
            ld (asm_1_283_n_cn_sp), hl		; Hyp.cls 807
asm_1_283_n_cn_pr_adv:		; Hyp.cls 808
            ld hl, #7682		; Hyp.cls 809
            inc (hl)		; Hyp.cls 810
            ld a, (hl)		; Hyp.cls 811
            ld hl, asm_1_283_n_cn_c		; Hyp.cls 812
            cp (hl)		; Hyp.cls 813
            ret c		; Hyp.cls 814
            xor a                   ; past the last column: the next row [815]
            ld (#7682), a		; Hyp.cls 816
            ld (asm_1_283_n_cn_pv), a		; Hyp.cls 817
; a line feed: the next row, or the page (and the screen) scroll
asm_1_283_n_cn_nl:		; Hyp.cls 819
            ld a, (#7683)		; Hyp.cls 820
            inc a		; Hyp.cls 821
            ld hl, asm_1_283_n_cn_r		; Hyp.cls 822
            cp (hl)		; Hyp.cls 823
            jr nc, asm_1_283_n_cn_scroll		; Hyp.cls 824
            ld (#7683), a		; Hyp.cls 825
            ret		; Hyp.cls 826
asm_1_283_n_cn_scroll:		; Hyp.cls 827
            ld a, (#7684)           ; the ring's top row moves on (no copy) [828]
            inc a		; Hyp.cls 829
            cp (hl)		; Hyp.cls 830
            jr c, asm_1_283_n_cn_sc_top		; Hyp.cls 831
            xor a		; Hyp.cls 832
asm_1_283_n_cn_sc_top:		; Hyp.cls 833
            ld (#7684), a		; Hyp.cls 834
            ld a, (asm_1_283_n_cn_r)		; Hyp.cls 835
            dec a		; Hyp.cls 836
            call asm_1_283_n_cn_rowa            ; the new last row cleared (the old top row: kept first) [837]
            IF asm_1_283_n_CN_SB		; Hyp.cls 838
            push hl		; Hyp.cls 839
            call asm_1_283_n_cn_hput		; Hyp.cls 840
            pop hl		; Hyp.cls 841
            ENDIF		; Hyp.cls 842
            ld a, (asm_1_283_n_cn_c)		; Hyp.cls 843
            ld b, a		; Hyp.cls 844
asm_1_283_n_cn_sc_cl:		; Hyp.cls 845
            ld (hl), ' '		; Hyp.cls 846
            inc hl		; Hyp.cls 847
            djnz asm_1_283_n_cn_sc_cl		; Hyp.cls 848
            ld a, (asm_1_283_n_cn_front)		; Hyp.cls 849
            or a		; Hyp.cls 850
            ret z		; Hyp.cls 851
            ld hl, (var_hyp_sco)          ; the screen: its start a row on (R12, R13), the new last row [852]
            ld de, (var_hyp_scc)          ; cleared, the status strip again (it went off the top) [853]
            add hl, de		; Hyp.cls 854
            ld a, h		; Hyp.cls 855
            and #07		; Hyp.cls 856
            ld h, a		; Hyp.cls 857
            ld (var_hyp_sco), hl		; Hyp.cls 858
            call asm_1_283_n_cn_crtc		; Hyp.cls 859
            ld a, (asm_1_283_n_cn_r)		; Hyp.cls 860
            dec a		; Hyp.cls 861
            ld e, a		; Hyp.cls 862
asm_1_283_n_cn_sc_clr:                          ; E = a screen row: cleared, then the status strip again [863]
            ld d, 0		; Hyp.cls 864
            call asm_1_283_n_cn_scr		; Hyp.cls 865
            ld b, 8		; Hyp.cls 866
asm_1_283_n_cn_sc_ln:		; Hyp.cls 867
            push bc		; Hyp.cls 868
            push hl		; Hyp.cls 869
            ld a, (var_hyp_scc)		; Hyp.cls 870
            ld b, a		; Hyp.cls 871
asm_1_283_n_cn_sc_b:		; Hyp.cls 872
            ld (hl), 0		; Hyp.cls 873
            call asm_1_283_n_cn_next		; Hyp.cls 874
            djnz asm_1_283_n_cn_sc_b		; Hyp.cls 875
            pop hl		; Hyp.cls 876
            ld a, h		; Hyp.cls 877
            add a, 8		; Hyp.cls 878
            ld h, a		; Hyp.cls 879
            pop bc		; Hyp.cls 880
            djnz asm_1_283_n_cn_sc_ln		; Hyp.cls 881
            jp asm_1_283_n_cn_strip		; Hyp.cls 882

; ESC I (reverse line feed): the row before, or on the top row the page (and the screen) scroll
; back: the ring's top row a row back, the new top row cleared; on the screen its start a row
; back (R12, R13) and the new top row cleared - the line feed's scroll the other way
asm_1_283_n_cn_rev:		; Hyp.cls 887
            ld a, (#7683)		; Hyp.cls 888
            or a		; Hyp.cls 889
            jr z, asm_1_283_n_cn_rv_sc		; Hyp.cls 890
            dec a		; Hyp.cls 891
            ld (#7683), a		; Hyp.cls 892
            ret		; Hyp.cls 893
asm_1_283_n_cn_rv_sc:		; Hyp.cls 894
            ld a, (#7684)		; Hyp.cls 895
            or a		; Hyp.cls 896
            jr nz, asm_1_283_n_cn_rv_top		; Hyp.cls 897
            ld a, (asm_1_283_n_cn_r)		; Hyp.cls 898
asm_1_283_n_cn_rv_top:		; Hyp.cls 899
            dec a		; Hyp.cls 900
            ld (#7684), a		; Hyp.cls 901
            xor a		; Hyp.cls 902
            call asm_1_283_n_cn_rowa            ; (row 0 of the page now) [903]
            ld a, (asm_1_283_n_cn_c)		; Hyp.cls 904
            ld b, a		; Hyp.cls 905
asm_1_283_n_cn_rv_cl:		; Hyp.cls 906
            ld (hl), ' '		; Hyp.cls 907
            inc hl		; Hyp.cls 908
            djnz asm_1_283_n_cn_rv_cl		; Hyp.cls 909
            ld a, (asm_1_283_n_cn_front)		; Hyp.cls 910
            or a		; Hyp.cls 911
            ret z		; Hyp.cls 912
            ld hl, (var_hyp_sco)		; Hyp.cls 913
            ld de, (var_hyp_scc)		; Hyp.cls 914
            or a		; Hyp.cls 915
            sbc hl, de		; Hyp.cls 916
            ld a, h		; Hyp.cls 917
            and #07		; Hyp.cls 918
            ld h, a		; Hyp.cls 919
            ld (var_hyp_sco), hl		; Hyp.cls 920
            call asm_1_283_n_cn_crtc		; Hyp.cls 921
            ld e, 0		; Hyp.cls 922
            jp asm_1_283_n_cn_sc_clr		; Hyp.cls 923

; ESC K the row from the cursor on cleared, J the rest of the page too, l the whole row, o the
; row up to the cursor, d the page up to it; M the cursor's row deleted (those below up a row, a
; blank one at the end), L a blank one put in (those below down, the last gone) - the column 0.
; The page changed first, then its rows drawn again on the screen when in front
asm_1_283_n_cn_eol:		; Hyp.cls 929
            ld a, (asm_1_283_n_cn_c)		; Hyp.cls 930
            ld hl, #7682		; Hyp.cls 931
            sub (hl)		; Hyp.cls 932
            ld b, a		; Hyp.cls 933
            ld d, (hl)		; Hyp.cls 934
            ld a, (#7683)		; Hyp.cls 935
            ld e, a		; Hyp.cls 936
            jp asm_1_283_n_cn_wipen		; Hyp.cls 937
asm_1_283_n_cn_eos:		; Hyp.cls 938
            call asm_1_283_n_cn_eol		; Hyp.cls 939
            ld a, (#7683)		; Hyp.cls 940
asm_1_283_n_cn_eos_lp:		; Hyp.cls 941
            inc a		; Hyp.cls 942
            ld hl, asm_1_283_n_cn_r		; Hyp.cls 943
            cp (hl)		; Hyp.cls 944
            ret nc		; Hyp.cls 945
            push af		; Hyp.cls 946
            ld e, a		; Hyp.cls 947
            call asm_1_283_n_cn_wrow		; Hyp.cls 948
            pop af		; Hyp.cls 949
            jr asm_1_283_n_cn_eos_lp		; Hyp.cls 950
asm_1_283_n_cn_eln:		; Hyp.cls 951
            ld a, (#7683)		; Hyp.cls 952
            ld e, a		; Hyp.cls 953
            jp asm_1_283_n_cn_wrow		; Hyp.cls 954
asm_1_283_n_cn_sol:		; Hyp.cls 955
            ld a, (#7682)		; Hyp.cls 956
            inc a		; Hyp.cls 957
            ld b, a		; Hyp.cls 958
            ld d, 0		; Hyp.cls 959
            ld a, (#7683)		; Hyp.cls 960
            ld e, a		; Hyp.cls 961
            jp asm_1_283_n_cn_wipen		; Hyp.cls 962
asm_1_283_n_cn_sos:		; Hyp.cls 963
            call asm_1_283_n_cn_sol		; Hyp.cls 964
            ld a, (#7683)		; Hyp.cls 965
asm_1_283_n_cn_sos_lp:		; Hyp.cls 966
            or a		; Hyp.cls 967
            ret z		; Hyp.cls 968
            dec a		; Hyp.cls 969
            push af		; Hyp.cls 970
            ld e, a		; Hyp.cls 971
            call asm_1_283_n_cn_wrow		; Hyp.cls 972
            pop af		; Hyp.cls 973
            jr asm_1_283_n_cn_sos_lp		; Hyp.cls 974
asm_1_283_n_cn_dell:		; Hyp.cls 975
            xor a		; Hyp.cls 976
            ld (#7682), a		; Hyp.cls 977
            ld a, (#7683)		; Hyp.cls 978
            ld b, a                 ; B: the row filled from the one below [979]
asm_1_283_n_cn_dl_lp:		; Hyp.cls 980
            ld a, (asm_1_283_n_cn_r)		; Hyp.cls 981
            dec a		; Hyp.cls 982
            cp b		; Hyp.cls 983
            jr z, asm_1_283_n_cn_dl_end		; Hyp.cls 984
            ld c, b		; Hyp.cls 985
            inc c		; Hyp.cls 986
            ld a, b		; Hyp.cls 987
            push bc		; Hyp.cls 988
            call asm_1_283_n_cn_cpr		; Hyp.cls 989
            pop bc		; Hyp.cls 990
            inc b		; Hyp.cls 991
            jr asm_1_283_n_cn_dl_lp		; Hyp.cls 992
asm_1_283_n_cn_dl_end:		; Hyp.cls 993
            ld e, b		; Hyp.cls 994
            call asm_1_283_n_cn_wrow            ; the last row blank [995]
            ld a, (asm_1_283_n_cn_r)		; Hyp.cls 996
            dec a		; Hyp.cls 997
            ld c, a		; Hyp.cls 998
            ld a, (#7683)		; Hyp.cls 999
            jr asm_1_283_n_cn_redr		; Hyp.cls 1000
asm_1_283_n_cn_insl:		; Hyp.cls 1001
            xor a		; Hyp.cls 1002
            ld (#7682), a		; Hyp.cls 1003
            ld a, (asm_1_283_n_cn_r)		; Hyp.cls 1004
            dec a		; Hyp.cls 1005
            ld b, a                 ; B: the row filled from the one above [1006]
asm_1_283_n_cn_il_lp:		; Hyp.cls 1007
            ld a, (#7683)		; Hyp.cls 1008
            cp b		; Hyp.cls 1009
            jr z, asm_1_283_n_cn_il_end		; Hyp.cls 1010
            ld c, b		; Hyp.cls 1011
            dec c		; Hyp.cls 1012
            ld a, b		; Hyp.cls 1013
            push bc		; Hyp.cls 1014
            call asm_1_283_n_cn_cpr		; Hyp.cls 1015
            pop bc		; Hyp.cls 1016
            dec b		; Hyp.cls 1017
            jr asm_1_283_n_cn_il_lp		; Hyp.cls 1018
asm_1_283_n_cn_il_end:		; Hyp.cls 1019
            ld e, b		; Hyp.cls 1020
            call asm_1_283_n_cn_wrow            ; the cursor's row blank [1021]
            ld a, (asm_1_283_n_cn_r)		; Hyp.cls 1022
            ld c, a		; Hyp.cls 1023
            ld a, (#7683)		; Hyp.cls 1024
            inc a		; Hyp.cls 1025
; cn_redr: rows A to C - 1 drawn again from the page
asm_1_283_n_cn_redr:		; Hyp.cls 1027
            cp c		; Hyp.cls 1028
            ret nc		; Hyp.cls 1029
            push af		; Hyp.cls 1030
            push bc		; Hyp.cls 1031
            ld e, a		; Hyp.cls 1032
            ld d, 0		; Hyp.cls 1033
            ld a, (asm_1_283_n_cn_c)		; Hyp.cls 1034
            ld b, a		; Hyp.cls 1035
            call asm_1_283_n_cn_drwn		; Hyp.cls 1036
            pop bc		; Hyp.cls 1037
            pop af		; Hyp.cls 1038
            inc a		; Hyp.cls 1039
            jr asm_1_283_n_cn_redr		; Hyp.cls 1040
; cn_cpr: the page's row C copied to its row A
asm_1_283_n_cn_cpr:		; Hyp.cls 1042
            push af		; Hyp.cls 1043
            ld a, c		; Hyp.cls 1044
            call asm_1_283_n_cn_rowa		; Hyp.cls 1045
            pop af		; Hyp.cls 1046
            push hl		; Hyp.cls 1047
            call asm_1_283_n_cn_rowa		; Hyp.cls 1048
            ex de, hl		; Hyp.cls 1049
            pop hl		; Hyp.cls 1050
            ld a, (asm_1_283_n_cn_c)		; Hyp.cls 1051
            ld c, a		; Hyp.cls 1052
            ld b, 0		; Hyp.cls 1053
            ldir		; Hyp.cls 1054
            ret		; Hyp.cls 1055
; cn_wrow: row E blank; cn_wipen: B characters of row E from column D blank (B > 0) - in the page,
; then drawn (cn_drwn: B characters of row E from column D, from the page, when in front)
asm_1_283_n_cn_wrow:		; Hyp.cls 1058
            ld d, 0		; Hyp.cls 1059
            ld a, (asm_1_283_n_cn_c)		; Hyp.cls 1060
            ld b, a		; Hyp.cls 1061
asm_1_283_n_cn_wipen:		; Hyp.cls 1062
            push de		; Hyp.cls 1063
            push bc		; Hyp.cls 1064
            ld a, e		; Hyp.cls 1065
            call asm_1_283_n_cn_rowa		; Hyp.cls 1066
            pop bc		; Hyp.cls 1067
            pop de		; Hyp.cls 1068
            push bc		; Hyp.cls 1069
            ld a, l		; Hyp.cls 1070
            add a, d		; Hyp.cls 1071
            ld l, a		; Hyp.cls 1072
            jr nc, asm_1_283_n_cn_wn_lp		; Hyp.cls 1073
            inc h		; Hyp.cls 1074
asm_1_283_n_cn_wn_lp:		; Hyp.cls 1075
            ld (hl), ' '		; Hyp.cls 1076
            inc hl		; Hyp.cls 1077
            djnz asm_1_283_n_cn_wn_lp		; Hyp.cls 1078
            pop bc		; Hyp.cls 1079
asm_1_283_n_cn_drwn:		; Hyp.cls 1080
            ld a, (asm_1_283_n_cn_front)		; Hyp.cls 1081
            or a		; Hyp.cls 1082
            ret z		; Hyp.cls 1083
            push de		; Hyp.cls 1084
            push bc		; Hyp.cls 1085
            ld a, e		; Hyp.cls 1086
            call asm_1_283_n_cn_rowa		; Hyp.cls 1087
            pop bc		; Hyp.cls 1088
            pop de		; Hyp.cls 1089
            ld a, l		; Hyp.cls 1090
            add a, d		; Hyp.cls 1091
            ld l, a		; Hyp.cls 1092
            jr nc, asm_1_283_n_cn_dw_p		; Hyp.cls 1093
            inc h		; Hyp.cls 1094
asm_1_283_n_cn_dw_p:                            ; the screen address worked out once, then stepped on (as [1095]
            push hl                 ; cn_print: a sum each character was a fifth of the time [1096]
            push bc                 ; a screen of text took - ESC K's) [1097]
            call asm_1_283_n_cn_scr		; Hyp.cls 1098
            pop bc		; Hyp.cls 1099
            pop de                  ; DE: the page's characters, HL the screen [1100]
asm_1_283_n_cn_dw_lp:		; Hyp.cls 1101
            ld a, (de)		; Hyp.cls 1102
            inc de		; Hyp.cls 1103
            push hl		; Hyp.cls 1104
            push de		; Hyp.cls 1105
            push bc		; Hyp.cls 1106
            call asm_1_283_n_cn_glyph8		; Hyp.cls 1107
            pop bc		; Hyp.cls 1108
            pop de		; Hyp.cls 1109
            pop hl		; Hyp.cls 1110
            call asm_1_283_n_cn_next		; Hyp.cls 1111
            djnz asm_1_283_n_cn_dw_lp		; Hyp.cls 1112
            ret		; Hyp.cls 1113

; ESC E: the page cleared, column, row and ring back to 0; the screen too if in front (written,
; not copied: the Library: ROM build may have the keyword ROM over it for reads)
asm_1_283_n_cn_clear:		; Hyp.cls 1117
            ld hl, #7700		; Hyp.cls 1118
            ld de, #7701		; Hyp.cls 1119
            ld (hl), ' '		; Hyp.cls 1120
            ld bc, 2047		; Hyp.cls 1121
            ldir		; Hyp.cls 1122
            xor a		; Hyp.cls 1123
            ld (#7682), a		; Hyp.cls 1124
            ld (#7683), a		; Hyp.cls 1125
            ld (#7684), a		; Hyp.cls 1126
            ld a, (asm_1_283_n_cn_front)		; Hyp.cls 1127
            or a		; Hyp.cls 1128
            ret z		; Hyp.cls 1129
            ld hl, 0		; Hyp.cls 1130
            ld (var_hyp_sco), hl		; Hyp.cls 1131
            ld (var_hyp_pon), hl          ; (no pointer on the cleared screen) [1132]
            call asm_1_283_n_cn_crtc		; Hyp.cls 1133
            xor a		; Hyp.cls 1134
            ld hl, #C000		; Hyp.cls 1135
            ld c, #40		; Hyp.cls 1136
asm_1_283_n_cn_cl_l:		; Hyp.cls 1137
            ld b, 0		; Hyp.cls 1138
asm_1_283_n_cn_cl_b:		; Hyp.cls 1139
            ld (hl), a		; Hyp.cls 1140
            inc hl		; Hyp.cls 1141
            djnz asm_1_283_n_cn_cl_b		; Hyp.cls 1142
            dec c		; Hyp.cls 1143
            jr nz, asm_1_283_n_cn_cl_l		; Hyp.cls 1144
; cn_strip: MODE S (the screen wider than the console): the status strip's 4 characters (#F68A)
; at the top of the columns right of the console
asm_1_283_n_cn_strip:		; Hyp.cls 1147
            ld a, (asm_1_283_n_cn_front)		; Hyp.cls 1148
            or a		; Hyp.cls 1149
            ret z		; Hyp.cls 1150
            ld a, (asm_1_283_n_cn_c)		; Hyp.cls 1151
            ld d, a		; Hyp.cls 1152
            ld a, (var_hyp_scc)		; Hyp.cls 1153
            cp d		; Hyp.cls 1154
            ret z		; Hyp.cls 1155
            ret c		; Hyp.cls 1156
            ld e, 0		; Hyp.cls 1157
            ld hl, #768A		; Hyp.cls 1158
            ld b, 4		; Hyp.cls 1159
asm_1_283_n_cn_st_lp:		; Hyp.cls 1160
            ld a, (hl)		; Hyp.cls 1161
            push hl		; Hyp.cls 1162
            push de		; Hyp.cls 1163
            push bc		; Hyp.cls 1164
            call asm_1_283_n_cn_glyph		; Hyp.cls 1165
            pop bc		; Hyp.cls 1166
            pop de		; Hyp.cls 1167
            pop hl		; Hyp.cls 1168
            inc hl		; Hyp.cls 1169
            inc d		; Hyp.cls 1170
            djnz asm_1_283_n_cn_st_lp		; Hyp.cls 1171
            jp asm_1_283_n_cn_net                       ; then the network indicator, two rows down [1172]

; cn_net: the network indicator - the status strip's row 2 (row 1 left blank under [1]). 'N' when
; the network's up and idle; it blinks N / blank while there's traffic (nta, counted down by the
; 0.5s cursor-flash tick); the cell is left BLANK when the network's off, so nothing shows until a
; network is turned on (the screen is unchanged from before this feature). The cell is system-wide
; (not a slot's), so its state is in class vars (ntu / nta / ntb), reachable from the NET service
asm_1_283_n_cn_net:		; Hyp.cls 1179
            ld a, (asm_1_283_n_cn_front)		; Hyp.cls 1180
            or a		; Hyp.cls 1181
            ret z		; Hyp.cls 1182
            ld a, (asm_1_283_n_cn_c)		; Hyp.cls 1183
            ld d, a		; Hyp.cls 1184
            ld a, (var_hyp_scc)		; Hyp.cls 1185
            cp d		; Hyp.cls 1186
            ret z		; Hyp.cls 1187
            ret c		; Hyp.cls 1188
            ld hl, asm_1_283_n_cn_nblk                  ; the network's off: a blank cell (nothing shown) [1189]
            ld a, (var_hyp_ntu)		; Hyp.cls 1190
            or a		; Hyp.cls 1191
            jr z, asm_1_283_n_cn_net_draw		; Hyp.cls 1192
            ld a, (var_hyp_nta)                   ; up: steady 'N', or blank on the odd blink while busy [1193]
            or a		; Hyp.cls 1194
            ld a, 78		; Hyp.cls 1195
            jr z, asm_1_283_n_cn_net_put		; Hyp.cls 1196
            ld a, (var_hyp_ntb)		; Hyp.cls 1197
            and 1		; Hyp.cls 1198
            ld a, 78		; Hyp.cls 1199
            jr z, asm_1_283_n_cn_net_put		; Hyp.cls 1200
            ld a, 32		; Hyp.cls 1201
asm_1_283_n_cn_net_put:		; Hyp.cls 1202
            ld (asm_1_283_n_cn_nbuf + 1), a		; Hyp.cls 1203
            ld hl, asm_1_283_n_cn_nbuf		; Hyp.cls 1204
asm_1_283_n_cn_net_draw:		; Hyp.cls 1205
            ld a, (asm_1_283_n_cn_c)		; Hyp.cls 1206
            ld d, a                         ; the first strip column [1207]
            ld e, 2                         ; row 2 (row 1 blank, under [1] at row 0) [1208]
            ld b, 4		; Hyp.cls 1209
asm_1_283_n_cn_net_lp:		; Hyp.cls 1210
            ld a, (hl)		; Hyp.cls 1211
            push hl		; Hyp.cls 1212
            push de		; Hyp.cls 1213
            push bc		; Hyp.cls 1214
            call asm_1_283_n_cn_glyph		; Hyp.cls 1215
            pop bc		; Hyp.cls 1216
            pop de		; Hyp.cls 1217
            pop hl		; Hyp.cls 1218
            inc hl		; Hyp.cls 1219
            inc d		; Hyp.cls 1220
            djnz asm_1_283_n_cn_net_lp		; Hyp.cls 1221
            ret		; Hyp.cls 1222
asm_1_283_n_cn_nbuf:    db 91, 78, 93, 32               ; "[N] " when up; +1 overwritten with N / blank (blink) [1223]
asm_1_283_n_cn_nblk:    db 32, 32, 32, 32               ; a blank cell (network off: nothing shown) [1224]

; cn_crtc: the screen's start (sco, bytes) to the CRTC: R12 = #30 + its words' high 2 bits, R13
; the low 8 (#C000, MA10 / MA11 clear: kept within 2K, never the carry into the next 16K)
asm_1_283_n_cn_crtc:		; Hyp.cls 1228
            ld hl, (var_hyp_sco)		; Hyp.cls 1229
            srl h		; Hyp.cls 1230
            rr l		; Hyp.cls 1231
            ld a, h		; Hyp.cls 1232
            and 3		; Hyp.cls 1233
            or #30		; Hyp.cls 1234
            ld bc, #BC0C		; Hyp.cls 1235
            out (c), c		; Hyp.cls 1236
            inc b		; Hyp.cls 1237
            out (c), a		; Hyp.cls 1238
            ld bc, #BC0D		; Hyp.cls 1239
            out (c), c		; Hyp.cls 1240
            inc b		; Hyp.cls 1241
            out (c), l		; Hyp.cls 1242
            ret		; Hyp.cls 1243

; cn_rowa: A = row of the screen -> HL = its row in the page ring (#7700 + ((top + A) mod rows)
; * columns)
asm_1_283_n_cn_rowa:		; Hyp.cls 1247
            ld hl, #7684		; Hyp.cls 1248
            add a, (hl)		; Hyp.cls 1249
            ld hl, asm_1_283_n_cn_r		; Hyp.cls 1250
            cp (hl)		; Hyp.cls 1251
            jr c, asm_1_283_n_cn_ra_in		; Hyp.cls 1252
            sub (hl)		; Hyp.cls 1253
asm_1_283_n_cn_ra_in:		; Hyp.cls 1254
            ld e, a		; Hyp.cls 1255
            ld a, (asm_1_283_n_cn_c)		; Hyp.cls 1256
            call asm_1_283_n_cn_mul		; Hyp.cls 1257
            ld de, #7700		; Hyp.cls 1258
            add hl, de		; Hyp.cls 1259
            ret		; Hyp.cls 1260

; cn_mul: HL = A * E (BC kept; D = 0 after)
asm_1_283_n_cn_mul:		; Hyp.cls 1263
            push bc		; Hyp.cls 1264
            ld hl, 0		; Hyp.cls 1265
            ld d, 0		; Hyp.cls 1266
            ld b, 8		; Hyp.cls 1267
asm_1_283_n_cn_mu_lp:		; Hyp.cls 1268
            add hl, hl		; Hyp.cls 1269
            rlca		; Hyp.cls 1270
            jr nc, asm_1_283_n_cn_mu_n		; Hyp.cls 1271
            add hl, de		; Hyp.cls 1272
asm_1_283_n_cn_mu_n:		; Hyp.cls 1273
            djnz asm_1_283_n_cn_mu_lp		; Hyp.cls 1274
            pop bc		; Hyp.cls 1275
            ret		; Hyp.cls 1276

; cn_next: HL = the next screen byte: + 1 within its 2K line block (BC kept)
asm_1_283_n_cn_next:		; Hyp.cls 1279
            inc l		; Hyp.cls 1280
            ret nz		; Hyp.cls 1281
            ld a, h		; Hyp.cls 1282
            inc a		; Hyp.cls 1283
            and #07		; Hyp.cls 1284
            push bc		; Hyp.cls 1285
            ld c, a		; Hyp.cls 1286
            ld a, h		; Hyp.cls 1287
            and #F8		; Hyp.cls 1288
            or c		; Hyp.cls 1289
            ld h, a		; Hyp.cls 1290
            pop bc		; Hyp.cls 1291
            ret		; Hyp.cls 1292

; cn_glyph: A = character, D = column, E = row: drawn (cn_show)
asm_1_283_n_cn_glyph:		; Hyp.cls 1295
            push af		; Hyp.cls 1296
            call asm_1_283_n_cn_scr		; Hyp.cls 1297
            pop af		; Hyp.cls 1298
; cn_glyph8: A = character, HL = its screen address: its 8 bytes into screen memory (mode 2, pen
; 1 on paper 0), one per pixel line (#800 apart; unrolled)
asm_1_283_n_cn_glyph8:		; Hyp.cls 1301
            sub 32		; Hyp.cls 1302
            cp 96		; Hyp.cls 1303
            jr c, asm_1_283_n_cn_gl_ok		; Hyp.cls 1304
            ld a, '?' - 32		; Hyp.cls 1305
asm_1_283_n_cn_gl_ok:		; Hyp.cls 1306
            push hl		; Hyp.cls 1307
            ld l, a		; Hyp.cls 1308
            ld h, 0		; Hyp.cls 1309
            add hl, hl		; Hyp.cls 1310
            add hl, hl		; Hyp.cls 1311
            add hl, hl		; Hyp.cls 1312
            ld de, 62208 - #8000   ; (the bank's page 3 in the window: FONT - #C000 + #4000) [1313]
            add hl, de		; Hyp.cls 1314
            ex de, hl               ; DE = its matrix [1315]
            pop hl		; Hyp.cls 1316
            ld a, (de)		; Hyp.cls 1317
            ld (hl), a		; Hyp.cls 1318
            inc de		; Hyp.cls 1319
            ld a, h		; Hyp.cls 1320
            add a, 8		; Hyp.cls 1321
            ld h, a		; Hyp.cls 1322
            ld a, (de)		; Hyp.cls 1323
            ld (hl), a		; Hyp.cls 1324
            inc de		; Hyp.cls 1325
            ld a, h		; Hyp.cls 1326
            add a, 8		; Hyp.cls 1327
            ld h, a		; Hyp.cls 1328
            ld a, (de)		; Hyp.cls 1329
            ld (hl), a		; Hyp.cls 1330
            inc de		; Hyp.cls 1331
            ld a, h		; Hyp.cls 1332
            add a, 8		; Hyp.cls 1333
            ld h, a		; Hyp.cls 1334
            ld a, (de)		; Hyp.cls 1335
            ld (hl), a		; Hyp.cls 1336
            inc de		; Hyp.cls 1337
            ld a, h		; Hyp.cls 1338
            add a, 8		; Hyp.cls 1339
            ld h, a		; Hyp.cls 1340
            ld a, (de)		; Hyp.cls 1341
            ld (hl), a		; Hyp.cls 1342
            inc de		; Hyp.cls 1343
            ld a, h		; Hyp.cls 1344
            add a, 8		; Hyp.cls 1345
            ld h, a		; Hyp.cls 1346
            ld a, (de)		; Hyp.cls 1347
            ld (hl), a		; Hyp.cls 1348
            inc de		; Hyp.cls 1349
            ld a, h		; Hyp.cls 1350
            add a, 8		; Hyp.cls 1351
            ld h, a		; Hyp.cls 1352
            ld a, (de)		; Hyp.cls 1353
            ld (hl), a		; Hyp.cls 1354
            inc de		; Hyp.cls 1355
            ld a, h		; Hyp.cls 1356
            add a, 8		; Hyp.cls 1357
            ld h, a		; Hyp.cls 1358
            ld a, (de)		; Hyp.cls 1359
            ld (hl), a		; Hyp.cls 1360
            ret		; Hyp.cls 1361
; cn_scr: D = column, E = row -> HL = the screen address: the screen's start (sco) + row *
; columns (scc) + column, within each 2K line block, at #C000
asm_1_283_n_cn_scr:		; Hyp.cls 1364
            push de		; Hyp.cls 1365
            ld a, (var_hyp_scc)		; Hyp.cls 1366
            call asm_1_283_n_cn_mul		; Hyp.cls 1367
            pop de		; Hyp.cls 1368
            ld c, d		; Hyp.cls 1369
            ld b, 0		; Hyp.cls 1370
            add hl, bc		; Hyp.cls 1371
            ld bc, (var_hyp_sco)		; Hyp.cls 1372
            add hl, bc		; Hyp.cls 1373
            ld a, h		; Hyp.cls 1374
            and #07		; Hyp.cls 1375
            or #C0		; Hyp.cls 1376
            ld h, a		; Hyp.cls 1377
            ret		; Hyp.cls 1378
asm_1_283_n_cn_cuxor:                           ; the cursor's underline XORed at cn_ca, on <-> off [1379]
            ld hl, (asm_1_283_n_cn_ca)		; Hyp.cls 1380
            ld a, (hl)		; Hyp.cls 1381
            cpl		; Hyp.cls 1382
            ld (hl), a		; Hyp.cls 1383
            ld a, (var_hyp_ccu)		; Hyp.cls 1384
            xor 1		; Hyp.cls 1385
            ld (var_hyp_ccu), a		; Hyp.cls 1386
            ret		; Hyp.cls 1387
asm_1_283_n_cn_was:     db 0		; Hyp.cls 1388
asm_1_283_n_cn_ca:      dw 0		; Hyp.cls 1389
asm_1_283_n_cn_front:   db 0		; Hyp.cls 1390
asm_1_283_n_cn_c:       db 80                   ; the slot's columns, rows [1391]
asm_1_283_n_cn_r:       db 25		; Hyp.cls 1392
asm_1_283_n_cn_pv:      db 0                    ; cn_pp / cn_sp valid (0: the cursor moved) [1393]
asm_1_283_n_cn_pp:      dw 0                    ; the page byte for the next character [1394]
asm_1_283_n_cn_sp:      dw 0                    ; its screen address [1395]
asm_1_283_n_cn_left:    dw 0		; Hyp.cls 1396
asm_1_283_n_cn_ptr:     dw 0		; Hyp.cls 1397
            IF asm_1_283_n_CN_SB		; Hyp.cls 1398
asm_1_283_n_cn_pg:      dw 0                    ; the slot's page 3 setting (pg) [1399]
asm_1_283_n_cn_h1:      dw 0                    ; cn_hcp: from (its setting, address), to, 8-byte runs left [1400]
asm_1_283_n_cn_hs:      dw 0		; Hyp.cls 1401
asm_1_283_n_cn_h2:      dw 0		; Hyp.cls 1402
asm_1_283_n_cn_hd:      dw 0		; Hyp.cls 1403
asm_1_283_n_cn_hn:      db 0		; Hyp.cls 1404
            ENDIF		; Hyp.cls 1405
asm_1_283_n_cn_end:		; Hyp.cls 1406
			ret			; end of #asm

asm_1_1414_n:		; #asm, Hyp.cls line 1414 (normal)
            ld (var_hyp_hsp), sp		; Hyp.cls 1415
            ld sp, (ntc_csp)		; Hyp.cls 1416
            ld bc, (var_hyp_hps)          ; the hypervisor's page in the window: the font [1417]
            out (c), c		; Hyp.cls 1418
            ld hl, (var_hyp_sco)          ; the screen's start (TOP is shown in MODE 2: 80 columns) [1419]
            ld (asm_1_1414_n_sy_off), hl		; Hyp.cls 1420
            ld hl, (var_hyp_say_p)		; Hyp.cls 1421
            ld a, (var_hyp_say_n)		; Hyp.cls 1422
            ld b, a		; Hyp.cls 1423
            ld a, (var_hyp_say_col)		; Hyp.cls 1424
            ld d, a		; Hyp.cls 1425
            ld a, (var_hyp_say_row)		; Hyp.cls 1426
            ld e, a		; Hyp.cls 1427
            inc b		; Hyp.cls 1428
asm_1_1414_n_sy_lp:		; Hyp.cls 1429
            dec b		; Hyp.cls 1430
            jr z, asm_1_1414_n_sy_done		; Hyp.cls 1431
            ld a, d		; Hyp.cls 1432
            cp 80		; Hyp.cls 1433
            jr nc, asm_1_1414_n_sy_done		; Hyp.cls 1434
            ld a, (hl)		; Hyp.cls 1435
            inc hl		; Hyp.cls 1436
            push hl		; Hyp.cls 1437
            push bc		; Hyp.cls 1438
            push de		; Hyp.cls 1439
            sub 32                  ; the character's matrix [1440]
            cp 96		; Hyp.cls 1441
            jr c, asm_1_1414_n_sy_ok		; Hyp.cls 1442
            ld a, '?' - 32		; Hyp.cls 1443
asm_1_1414_n_sy_ok:		; Hyp.cls 1444
            ld l, a		; Hyp.cls 1445
            ld h, 0		; Hyp.cls 1446
            add hl, hl		; Hyp.cls 1447
            add hl, hl		; Hyp.cls 1448
            add hl, hl		; Hyp.cls 1449
            ld bc, #4000 + 4096  ; (the hypervisor's page in the window) [1450]
            add hl, bc		; Hyp.cls 1451
            push hl		; Hyp.cls 1452
            ld l, e                 ; its screen address: start + row * 80 + column, in 2K [1453]
            ld h, 0		; Hyp.cls 1454
            add hl, hl		; Hyp.cls 1455
            add hl, hl		; Hyp.cls 1456
            add hl, hl		; Hyp.cls 1457
            add hl, hl		; Hyp.cls 1458
            push hl		; Hyp.cls 1459
            add hl, hl		; Hyp.cls 1460
            add hl, hl		; Hyp.cls 1461
            pop bc		; Hyp.cls 1462
            add hl, bc		; Hyp.cls 1463
            ld c, d		; Hyp.cls 1464
            ld b, 0		; Hyp.cls 1465
            add hl, bc		; Hyp.cls 1466
            ld bc, (asm_1_1414_n_sy_off)		; Hyp.cls 1467
            add hl, bc		; Hyp.cls 1468
            ld a, h		; Hyp.cls 1469
            and #07		; Hyp.cls 1470
            or #C0		; Hyp.cls 1471
            ld h, a		; Hyp.cls 1472
            pop de		; Hyp.cls 1473
            ld b, 8		; Hyp.cls 1474
asm_1_1414_n_sy_ln:		; Hyp.cls 1475
            ld a, (de)		; Hyp.cls 1476
            ld (hl), a		; Hyp.cls 1477
            inc de		; Hyp.cls 1478
            ld a, h		; Hyp.cls 1479
            add a, 8		; Hyp.cls 1480
            ld h, a		; Hyp.cls 1481
            djnz asm_1_1414_n_sy_ln		; Hyp.cls 1482
            pop de		; Hyp.cls 1483
            pop bc		; Hyp.cls 1484
            pop hl		; Hyp.cls 1485
            inc d		; Hyp.cls 1486
            jr asm_1_1414_n_sy_lp		; Hyp.cls 1487
asm_1_1414_n_sy_done:		; Hyp.cls 1488
            ld bc, (ntc_rampt)		; Hyp.cls 1489
            out (c), c		; Hyp.cls 1490
            ld sp, (var_hyp_hsp)		; Hyp.cls 1491
            jr asm_1_1414_n_sy_end		; Hyp.cls 1492
asm_1_1414_n_sy_off:     dw 0		; Hyp.cls 1493
asm_1_1414_n_sy_end:		; Hyp.cls 1494
			ret			; end of #asm

asm_1_1508_n:		; #asm, Hyp.cls line 1508 (normal)
            ld (var_hyp_hsp), sp          ; (the real stack: SP is the thread) [1509]
            ld sp, (ntc_csp)		; Hyp.cls 1510
            xor a		; Hyp.cls 1511
            ld (var_hyp_ccu), a           ; (the screen cleared: no cursor on it) [1512]
            ld a, (var_hyp_scr_m)		; Hyp.cls 1513
            cp 6		; Hyp.cls 1514
            jr c, asm_1_1508_n_sm_ok		; Hyp.cls 1515
            xor a		; Hyp.cls 1516
asm_1_1508_n_sm_ok:		; Hyp.cls 1517
            ld l, a                 ; the mode's row of the table (6 bytes) [1518]
            add a, a		; Hyp.cls 1519
            add a, l		; Hyp.cls 1520
            add a, a		; Hyp.cls 1521
            ld e, a		; Hyp.cls 1522
            ld d, 0		; Hyp.cls 1523
            ld hl, asm_1_1508_n_sm_tab		; Hyp.cls 1524
            add hl, de		; Hyp.cls 1525
            ld a, (var_hyp_scr_k)		; Hyp.cls 1526
            or a		; Hyp.cls 1527
            jr z, asm_1_1508_n_sm_cols		; Hyp.cls 1528
            dec a		; Hyp.cls 1529
            jr z, asm_1_1508_n_sm_rows		; Hyp.cls 1530
            push hl                 ; 2: the screen [1531]
            ld e, (hl)              ; its columns [1532]
            ld d, 0		; Hyp.cls 1533
            ld (var_hyp_scc), de		; Hyp.cls 1534
            srl e		; Hyp.cls 1535
            ld (var_hyp_scw), de		; Hyp.cls 1536
            ld hl, 0		; Hyp.cls 1537
            ld (var_hyp_sco), hl		; Hyp.cls 1538
            ld (var_hyp_pon), hl          ; (no pointer on the cleared screen) [1539]
            pop hl		; Hyp.cls 1540
            inc hl		; Hyp.cls 1541
            inc hl                  ; R1, R2, R6, R7 [1542]
            di		; Hyp.cls 1543
            ld d, 1		; Hyp.cls 1544
            call asm_1_1508_n_sm_crtc		; Hyp.cls 1545
            ld d, 2		; Hyp.cls 1546
            call asm_1_1508_n_sm_crtc		; Hyp.cls 1547
            ld d, 6		; Hyp.cls 1548
            call asm_1_1508_n_sm_crtc		; Hyp.cls 1549
            ld d, 7		; Hyp.cls 1550
            call asm_1_1508_n_sm_crtc		; Hyp.cls 1551
            ld hl, asm_1_1508_n_sm_start         ; R12, R13: #C000 [1552]
            ld d, 12		; Hyp.cls 1553
            call asm_1_1508_n_sm_crtc		; Hyp.cls 1554
            ld d, 13		; Hyp.cls 1555
            call asm_1_1508_n_sm_crtc		; Hyp.cls 1556
            xor a                   ; cleared (written, not copied: the Library: ROM build may [1557]
            ld hl, #C000            ; have the keyword ROM over it for reads) [1558]
            ld c, #40		; Hyp.cls 1559
asm_1_1508_n_sm_cl:		; Hyp.cls 1560
            ld b, 0		; Hyp.cls 1561
asm_1_1508_n_sm_cl1:		; Hyp.cls 1562
            ld (hl), a		; Hyp.cls 1563
            inc hl		; Hyp.cls 1564
            djnz asm_1_1508_n_sm_cl1		; Hyp.cls 1565
            dec c		; Hyp.cls 1566
            jr nz, asm_1_1508_n_sm_cl		; Hyp.cls 1567
            ld hl, 0		; Hyp.cls 1568
            jr asm_1_1508_n_sm_res		; Hyp.cls 1569
asm_1_1508_n_sm_cols:		; Hyp.cls 1570
            ld a, (hl)              ; the console's: the screen's, less the status strip's 4 (S) [1571]
            inc hl		; Hyp.cls 1572
            sub (hl)		; Hyp.cls 1573
            jr asm_1_1508_n_sm_a		; Hyp.cls 1574
asm_1_1508_n_sm_rows:		; Hyp.cls 1575
            inc hl		; Hyp.cls 1576
            inc hl		; Hyp.cls 1577
            inc hl		; Hyp.cls 1578
            inc hl		; Hyp.cls 1579
            ld a, (hl)		; Hyp.cls 1580
asm_1_1508_n_sm_a:		; Hyp.cls 1581
            ld l, a		; Hyp.cls 1582
            ld h, 0		; Hyp.cls 1583
asm_1_1508_n_sm_res:		; Hyp.cls 1584
            ld (var_hyp_scr_scr), hl		; Hyp.cls 1585
            ld sp, (var_hyp_hsp)		; Hyp.cls 1586
            ret                     ; (on with the thread) [1587]
asm_1_1508_n_sm_crtc:                            ; CRTC register D = (HL), HL on [1588]
            ld bc, #BC00		; Hyp.cls 1589
            out (c), d		; Hyp.cls 1590
            ld b, #BD		; Hyp.cls 1591
            ld a, (hl)		; Hyp.cls 1592
            out (c), a		; Hyp.cls 1593
            inc hl		; Hyp.cls 1594
            ret		; Hyp.cls 1595
asm_1_1508_n_sm_start:   db #30, 0		; Hyp.cls 1596
; columns, the status strip's, R1 (words a row), R2 (horizontal sync), R6 (rows), R7 (vertical sync)
asm_1_1508_n_sm_tab:     db 80, 0, 40, 46, 25, 30		; Hyp.cls 1598
            db 84, 4, 42, 47, 24, 30		; Hyp.cls 1599
            db 88, 0, 44, 48, 23, 29		; Hyp.cls 1600
            db 96, 0, 48, 50, 21, 28		; Hyp.cls 1601
            db 64, 0, 32, 42, 32, 34		; Hyp.cls 1602
            db 84, 0, 42, 47, 24, 30		; Hyp.cls 1603
			ret			; end of #asm

asm_1_1610_n:		; #asm, Hyp.cls line 1610 (normal)
            ld (var_hyp_hsp), sp		; Hyp.cls 1611
            ld sp, (ntc_csp)		; Hyp.cls 1612
            call #BB42              ; KM GET DELAY: H the start delay, L the repeat [1613]
            di		; Hyp.cls 1614
            ld a, h		; Hyp.cls 1615
            call asm_1_1610_n_kr_mul		; Hyp.cls 1616
            ld h, a		; Hyp.cls 1617
            ld a, l		; Hyp.cls 1618
            call asm_1_1610_n_kr_mul		; Hyp.cls 1619
            ld l, a		; Hyp.cls 1620
            call #BB3F              ; KM SET DELAY [1621]
            di		; Hyp.cls 1622
            ld sp, (var_hyp_hsp)		; Hyp.cls 1623
            jr asm_1_1610_n_kr_end		; Hyp.cls 1624
asm_1_1610_n_kr_mul:                             ; A = A x f, 255 at most (0: 256 to the firmware - kept) [1625]
            or a		; Hyp.cls 1626
            ret z		; Hyp.cls 1627
            push hl		; Hyp.cls 1628
            ld e, a		; Hyp.cls 1629
            ld d, 0		; Hyp.cls 1630
            ld hl, 0		; Hyp.cls 1631
            ld a, (var_hyp_keyrep_f)		; Hyp.cls 1632
            ld b, a		; Hyp.cls 1633
asm_1_1610_n_kr_lp:		; Hyp.cls 1634
            add hl, de		; Hyp.cls 1635
            djnz asm_1_1610_n_kr_lp		; Hyp.cls 1636
            ld a, h		; Hyp.cls 1637
            or a		; Hyp.cls 1638
            ld a, l		; Hyp.cls 1639
            pop hl		; Hyp.cls 1640
            ret z		; Hyp.cls 1641
            ld a, 255		; Hyp.cls 1642
            ret		; Hyp.cls 1643
asm_1_1610_n_kr_end:		; Hyp.cls 1644
			ret			; end of #asm

asm_1_1674_n:		; #asm, Hyp.cls line 1674 (normal)
            ld (var_hyp_sps), sp		; Hyp.cls 1675
            ld sp, (ntc_csp)		; Hyp.cls 1676
            call #B903              ; KL U ROM DISABLE: the task's top 16K, not a ROM (Library: [1677]
            di                      ; ROM has the keyword ROM on), while it runs [1678]
            ld (var_hyp_rrom), a		; Hyp.cls 1679
            ld a, 6		; Hyp.cls 1680
            ld (var_hyp_slc), a		; Hyp.cls 1681
            ld a, 1                 ; from BASIC: it has taken the characters (Collected) [1682]
            ld (var_hyp_rclr), a		; Hyp.cls 1683
asm_1_1674_n_rn_again:		; Hyp.cls 1684
            push ix                 ; IX, IY and [1685]
            push iy		; Hyp.cls 1686
            db #08                  ; ex af, af': the alternate registers kept - the [1687]
            exx                     ; firmware's (BC' = its ROM / mode setting); a task [1688]
            push af                 ; may use them [1689]
            push bc		; Hyp.cls 1690
            push de		; Hyp.cls 1691
            push hl		; Hyp.cls 1692
            exx		; Hyp.cls 1693
            db #08		; Hyp.cls 1694
            ld hl, asm_1_1674_n_rn_back		; Hyp.cls 1695
            push hl                 ; where main RAM carries on [1696]
            ld (ntc_bk_sp), sp		; Hyp.cls 1697
            ld a, (var_hyp_rclr)		; Hyp.cls 1698
            ld e, a                 ; E = 1: the bank empties its characters out (BASIC has them) [1699]
            ld a, (var_hyp_ra)		; Hyp.cls 1700
            ld hl, (var_hyp_rhl)		; Hyp.cls 1701
            ld bc, (var_hyp_run_setting)		; Hyp.cls 1702
            jp ntc_bk_out           ; out (c), c: the task's bank; its #0046 lands it [1703]
asm_1_1674_n_rn_back:		; Hyp.cls 1704
            ld (var_hyp_rcnt), ix         ; the characters it collected (the stubs put them in IX) [1705]
            db #08                  ; ex af, af' [1706]
            exx		; Hyp.cls 1707
            pop hl                  ; the alternate registers back [1708]
            pop de		; Hyp.cls 1709
            pop bc		; Hyp.cls 1710
            pop af		; Hyp.cls 1711
            exx		; Hyp.cls 1712
            db #08		; Hyp.cls 1713
            pop iy		; Hyp.cls 1714
            pop ix		; Hyp.cls 1715
            push af                 ; carry: a BDOS call (A = C, DE = DE) [1716]
            push bc		; Hyp.cls 1717
            ld bc, (ntc_rampt)      ; the window's page back [1718]
            out (c), c		; Hyp.cls 1719
            pop bc		; Hyp.cls 1720
            pop af		; Hyp.cls 1721
            jr c, asm_1_1674_n_rn_far		; Hyp.cls 1722
            rst #38                 ; an interrupt stopped the task: the firmware's handler [1723]
            di		; Hyp.cls 1724
            ld hl, var_hyp_slc            ; a time slice is SLICE interrupts: until it is used up the [1725]
            dec (hl)                ; task carries on straight away (no trip through BASIC) [1726]
            jr z, asm_1_1674_n_rn_int		; Hyp.cls 1727
            ld a, (ntc_isldue)      ; ... unless an interrupt class (the system keys) is due [1728]
            or a		; Hyp.cls 1729
            jr nz, asm_1_1674_n_rn_int		; Hyp.cls 1730
            xor a                   ; its characters stay in its bank (and the count goes on) [1731]
            ld (var_hyp_rclr), a		; Hyp.cls 1732
            jp asm_1_1674_n_rn_again		; Hyp.cls 1733
asm_1_1674_n_rn_int:		; Hyp.cls 1734
            ld hl, 0		; Hyp.cls 1735
            jr asm_1_1674_n_rn_end		; Hyp.cls 1736
asm_1_1674_n_rn_far:		; Hyp.cls 1737
            ld (var_hyp_rfn), a		; Hyp.cls 1738
            ld (var_hyp_rde), de		; Hyp.cls 1739
            ld hl, 1		; Hyp.cls 1740
asm_1_1674_n_rn_end:		; Hyp.cls 1741
            ld (var_hyp_run_run), hl		; Hyp.cls 1742
            ld a, (var_hyp_rrom)		; Hyp.cls 1743
            call #B90C              ; KL ROM RESTORE [1744]
            di		; Hyp.cls 1745
            ld sp, (var_hyp_sps)		; Hyp.cls 1746

			ret			; end of #asm

fn_hyp_info:		; function info (asm keyword), Hyp.cls line 1756
            pop hl		; Hyp.cls 1757
            ld a, (hl)		; Hyp.cls 1758
            ld hl, fn_hyp_info_hi_p0		; Hyp.cls 1759
            or a		; Hyp.cls 1760
            jr z, fn_hyp_info_in_e		; Hyp.cls 1761
            ld hl, fn_hyp_info_hi_p0e - fn_hyp_info_hi_p0		; Hyp.cls 1762
            dec a		; Hyp.cls 1763
            jr z, fn_hyp_info_in_e		; Hyp.cls 1764
            ld hl, fn_hyp_info_sb_img		; Hyp.cls 1765
            dec a		; Hyp.cls 1766
            jr z, fn_hyp_info_in_e		; Hyp.cls 1767
            ld hl, fn_hyp_info_sb_end - fn_hyp_info_sb_start		; Hyp.cls 1768
            dec a		; Hyp.cls 1769
            jr z, fn_hyp_info_in_e		; Hyp.cls 1770
            ld hl, fn_hyp_info_sb_init		; Hyp.cls 1771
fn_hyp_info_in_e:		; Hyp.cls 1772
            ex de, hl		; Hyp.cls 1773
            pop hl		; Hyp.cls 1774
            ld (hl), e		; Hyp.cls 1775
            inc hl		; Hyp.cls 1776
            ld (hl), d		; Hyp.cls 1777
            ret		; Hyp.cls 1778

			ret			; end of #asm

asm_1_2347_n:		; #asm, Hyp.cls line 2347 (normal)
            ld (var_hyp_hsp), sp		; Hyp.cls 2348
            ld sp, (ntc_csp)		; Hyp.cls 2349
            ld a, (var_hyp_vdu_on)		; Hyp.cls 2350
            or a		; Hyp.cls 2351
            jr z, asm_1_2347_n_vd_off		; Hyp.cls 2352
            call #BB54              ; TXT VDU ENABLE [2353]
            jr asm_1_2347_n_vd_done		; Hyp.cls 2354
asm_1_2347_n_vd_off:		; Hyp.cls 2355
            call #BB57              ; TXT VDU DISABLE [2356]
asm_1_2347_n_vd_done:		; Hyp.cls 2357
            di		; Hyp.cls 2358
            ld sp, (var_hyp_hsp)		; Hyp.cls 2359
			ret			; end of #asm

asm_1_2379_n:		; #asm, Hyp.cls line 2379 (normal)
            ld (var_hyp_hsp), sp		; Hyp.cls 2380
            ld sp, (ntc_csp)		; Hyp.cls 2381
            ld (asm_1_2379_n_fl_ix), ix		; Hyp.cls 2382
            ld (asm_1_2379_n_fl_iy), iy		; Hyp.cls 2383
            ld a, 255		; Hyp.cls 2384
            ld (asm_1_2379_n_fl_res), a		; Hyp.cls 2385
            ld a, (var_hyp_filecall_slot)		; Hyp.cls 2386
            ld (asm_1_2379_n_fl_slot), a		; Hyp.cls 2387
            ld a, (var_hyp_filecall_f)		; Hyp.cls 2388
            cp 99		; Hyp.cls 2389
            jp z, asm_1_2379_n_fl_inst		; Hyp.cls 2390
            IF NTC_ROMLIB = 0		; Hyp.cls 2391
; the RAM discs' driver (RAMDISC.CYB's, in a page of its own at #4000) sees the call first:
; carry - it was one of its drives' (HL the answer), else on to the disc ROM. It gets IX = the
; call (f, fcb, slot, setting, dma, drive, buf; 100-105: drive = the hypervisor's drive), at
; #4003 a jump to fl_dx (its copies: it runs in the window, so can't switch it itself), at
; #4006 its page's RAM setting
            ASSERT var_hyp_filecall_buf - var_hyp_filecall_f = 12, "FileCall's parameters, one after another"		; Hyp.cls 2397
            ld a, (var_hyp_drs + 1)		; Hyp.cls 2398
            or a		; Hyp.cls 2399
            jr z, asm_1_2379_n_fl_nodrv		; Hyp.cls 2400
            di		; Hyp.cls 2401
            ld a, (var_hyp_filecall_f)		; Hyp.cls 2402
            cp 100		; Hyp.cls 2403
            jr c, asm_1_2379_n_fl_dr_go		; Hyp.cls 2404
            cp 106		; Hyp.cls 2405
            jr nc, asm_1_2379_n_fl_dr_go		; Hyp.cls 2406
            ld hl, (var_hyp_hdr)		; Hyp.cls 2407
            ld (var_hyp_filecall_drive), hl		; Hyp.cls 2408
asm_1_2379_n_fl_dr_go:		; Hyp.cls 2409
            ld bc, (var_hyp_drs)		; Hyp.cls 2410
            out (c), c		; Hyp.cls 2411
            ld hl, asm_1_2379_n_fl_dx		; Hyp.cls 2412
            ld (#4004), hl		; Hyp.cls 2413
            ld hl, (var_hyp_drs)		; Hyp.cls 2414
            ld (#4006), hl		; Hyp.cls 2415
            ld ix, var_hyp_filecall_f		; Hyp.cls 2416
            call #4000		; Hyp.cls 2417
            jr nc, asm_1_2379_n_fl_nodrv		; Hyp.cls 2418
            ld (asm_1_2379_n_fl_res16), hl		; Hyp.cls 2419
            ld a, 1		; Hyp.cls 2420
            ld (asm_1_2379_n_fl_r16), a		; Hyp.cls 2421
            jp asm_1_2379_n_fl_done		; Hyp.cls 2422
; fl_dx - A bytes (1-128) from HL to DE through dxb: IX = HL's RAM setting, IY = DE's (0:
; main RAM, no switch); the driver's page back in the window after. HL, DE on past them
asm_1_2379_n_fl_dx:		; Hyp.cls 2425
            ld (asm_1_2379_n_fl_dxn), a		; Hyp.cls 2426
            push de		; Hyp.cls 2427
            ld de, (var_hyp_dxb)		; Hyp.cls 2428
            push ix		; Hyp.cls 2429
            pop bc		; Hyp.cls 2430
            inc b		; Hyp.cls 2431
            dec b		; Hyp.cls 2432
            jr z, asm_1_2379_n_fl_dx1		; Hyp.cls 2433
            out (c), c		; Hyp.cls 2434
asm_1_2379_n_fl_dx1:		; Hyp.cls 2435
            ld c, a		; Hyp.cls 2436
            ld b, 0		; Hyp.cls 2437
            ldir		; Hyp.cls 2438
            pop de		; Hyp.cls 2439
            push hl		; Hyp.cls 2440
            push iy		; Hyp.cls 2441
            pop bc		; Hyp.cls 2442
            inc b		; Hyp.cls 2443
            dec b		; Hyp.cls 2444
            jr z, asm_1_2379_n_fl_dx2		; Hyp.cls 2445
            out (c), c		; Hyp.cls 2446
asm_1_2379_n_fl_dx2:		; Hyp.cls 2447
            ld hl, (var_hyp_dxb)		; Hyp.cls 2448
            ld a, (asm_1_2379_n_fl_dxn)		; Hyp.cls 2449
            ld c, a		; Hyp.cls 2450
            ld b, 0		; Hyp.cls 2451
            ldir		; Hyp.cls 2452
            pop hl		; Hyp.cls 2453
            ld bc, (var_hyp_drs)		; Hyp.cls 2454
            out (c), c		; Hyp.cls 2455
            ret		; Hyp.cls 2456
asm_1_2379_n_fl_dxn:     db 0		; Hyp.cls 2457
asm_1_2379_n_fl_nodrv:		; Hyp.cls 2458
            ENDIF		; Hyp.cls 2459
            di		; Hyp.cls 2460
            ld bc, (var_hyp_hps)          ; the rest runs in the hypervisor's page (window data from [2461]
            out (c), c              ; #5300: fp_go) [2462]
            call asm_1_2379_n_fp_go		; Hyp.cls 2463
            jp asm_1_2379_n_fl_done		; Hyp.cls 2464
; 99: the window data (#5300 to fp_end: the bank image, the page code) copied from main RAM's
; own #4000-#7FFF (where the file put it) into the hypervisor's page, through buf; once, at the
; start, before anything else uses main RAM's #4000-#7FFF
asm_1_2379_n_fl_inst:		; Hyp.cls 2468
            ld hl, #5300		; Hyp.cls 2469
asm_1_2379_n_fl_in_lp:		; Hyp.cls 2470
            push hl		; Hyp.cls 2471
            ld bc, #7FC0            ; main RAM's own [2472]
            out (c), c		; Hyp.cls 2473
            ld de, (var_hyp_filecall_buf)		; Hyp.cls 2474
            ld bc, 128		; Hyp.cls 2475
            ldir		; Hyp.cls 2476
            ld bc, (var_hyp_hps)		; Hyp.cls 2477
            out (c), c		; Hyp.cls 2478
            pop de		; Hyp.cls 2479
            push de		; Hyp.cls 2480
            ld hl, (var_hyp_filecall_buf)		; Hyp.cls 2481
            ld bc, 128		; Hyp.cls 2482
            ldir		; Hyp.cls 2483
            pop hl		; Hyp.cls 2484
            ld bc, 128		; Hyp.cls 2485
            add hl, bc		; Hyp.cls 2486
            ld de, asm_1_2379_n_fp_end		; Hyp.cls 2487
            or a		; Hyp.cls 2488
            sbc hl, de		; Hyp.cls 2489
            add hl, de		; Hyp.cls 2490
            jr c, asm_1_2379_n_fl_in_lp		; Hyp.cls 2491
            xor a		; Hyp.cls 2492
            ld (asm_1_2379_n_fl_res), a		; Hyp.cls 2493
            jp asm_1_2379_n_fl_done		; Hyp.cls 2494
; ---- what the page code can't do itself (it runs in the window): switch the window to a slot's
; page and back. Each puts the hypervisor's page back in the window
asm_1_2379_n_fl_sel:                             ; the slot's page holding HL in the window: HL = there [2497]
            push de		; Hyp.cls 2498
            ld a, h		; Hyp.cls 2499
            rlca		; Hyp.cls 2500
            rlca		; Hyp.cls 2501
            and 3		; Hyp.cls 2502
            add a, 4		; Hyp.cls 2503
            ld e, a		; Hyp.cls 2504
            ld bc, (var_hyp_filecall_setting)		; Hyp.cls 2505
            ld a, c		; Hyp.cls 2506
            and #F8		; Hyp.cls 2507
            or e		; Hyp.cls 2508
            ld c, a		; Hyp.cls 2509
            out (c), c		; Hyp.cls 2510
            ld a, h		; Hyp.cls 2511
            and #3F		; Hyp.cls 2512
            or #40		; Hyp.cls 2513
            ld h, a		; Hyp.cls 2514
            pop de		; Hyp.cls 2515
            ret		; Hyp.cls 2516
asm_1_2379_n_fl_peek:                            ; A = the slot's byte at HL (BC, DE, HL kept) [2517]
            push bc		; Hyp.cls 2518
            push hl		; Hyp.cls 2519
            call asm_1_2379_n_fl_sel		; Hyp.cls 2520
            ld a, (hl)		; Hyp.cls 2521
asm_1_2379_n_fl_pk_back:		; Hyp.cls 2522
            ld bc, (var_hyp_hps)		; Hyp.cls 2523
            out (c), c		; Hyp.cls 2524
            pop hl		; Hyp.cls 2525
            pop bc		; Hyp.cls 2526
            ret		; Hyp.cls 2527
asm_1_2379_n_fl_poke:                            ; the slot's byte at HL = A (BC, DE, HL kept) [2528]
            push bc		; Hyp.cls 2529
            push hl		; Hyp.cls 2530
            push af		; Hyp.cls 2531
            call asm_1_2379_n_fl_sel		; Hyp.cls 2532
            pop af		; Hyp.cls 2533
            ld (hl), a		; Hyp.cls 2534
            jr asm_1_2379_n_fl_pk_back		; Hyp.cls 2535
asm_1_2379_n_fl_toslot:                          ; BC bytes from DE (main RAM) to the slot's HL (all in one of [2536]
            push bc                 ; its pages: fl_fits) [2537]
            call asm_1_2379_n_fl_sel		; Hyp.cls 2538
            pop bc		; Hyp.cls 2539
            ex de, hl		; Hyp.cls 2540
            ldir		; Hyp.cls 2541
            jr asm_1_2379_n_fl_blk_back		; Hyp.cls 2542
asm_1_2379_n_fl_fromslot:                        ; BC bytes from the slot's HL (in one page) to DE (main RAM) [2543]
            push bc		; Hyp.cls 2544
            call asm_1_2379_n_fl_sel		; Hyp.cls 2545
            pop bc		; Hyp.cls 2546
            ldir		; Hyp.cls 2547
asm_1_2379_n_fl_blk_back:		; Hyp.cls 2548
            ld bc, (var_hyp_hps)		; Hyp.cls 2549
            out (c), c		; Hyp.cls 2550
            ret		; Hyp.cls 2551
asm_1_2379_n_fl_done:		; Hyp.cls 2552
            di		; Hyp.cls 2553
            ld bc, (ntc_rampt)      ; the page that was in the window back [2554]
            out (c), c		; Hyp.cls 2555
            ld a, (asm_1_2379_n_fl_res)		; Hyp.cls 2556
            ld l, a		; Hyp.cls 2557
            ld h, 0		; Hyp.cls 2558
            ld a, (asm_1_2379_n_fl_r16)		; Hyp.cls 2559
            or a		; Hyp.cls 2560
            jr z, asm_1_2379_n_fl_d8		; Hyp.cls 2561
            ld hl, (asm_1_2379_n_fl_res16)		; Hyp.cls 2562
            xor a		; Hyp.cls 2563
            ld (asm_1_2379_n_fl_r16), a		; Hyp.cls 2564
asm_1_2379_n_fl_d8:		; Hyp.cls 2565
            ld (var_hyp_filecall_filecall), hl		; Hyp.cls 2566
            ld ix, (asm_1_2379_n_fl_ix)		; Hyp.cls 2567
            ld iy, (asm_1_2379_n_fl_iy)		; Hyp.cls 2568
            ld sp, (var_hyp_hsp)		; Hyp.cls 2569
            jp asm_1_2379_n_fl_exit		; Hyp.cls 2570
asm_1_2379_n_fl_ix:      dw 0		; Hyp.cls 2571
asm_1_2379_n_fl_iy:      dw 0		; Hyp.cls 2572
asm_1_2379_n_fl_res:     db 0		; Hyp.cls 2573
asm_1_2379_n_fl_r16:     db 0                    ; 1: the result is fl_res16 [2574]
asm_1_2379_n_fl_res16:   dw 0		; Hyp.cls 2575
asm_1_2379_n_fl_slot:    db 0		; Hyp.cls 2576
; (main RAM: the page code calls them - no room left in the page)
asm_1_2379_n_fl_isin:                            ; Z: the file being read is this slot's, this FCB [2578]
            ld a, (var_hyp_fin)		; Hyp.cls 2579
            ld hl, asm_1_2379_n_fl_infcb		; Hyp.cls 2580
            jr asm_1_2379_n_fl_is		; Hyp.cls 2581
asm_1_2379_n_fl_isout:		; Hyp.cls 2582
            ld a, (var_hyp_fout)		; Hyp.cls 2583
            ld hl, asm_1_2379_n_fl_outfcb		; Hyp.cls 2584
asm_1_2379_n_fl_is:                              ; (its FCB: the one it was opened with - or, the first [2585]
            ld b, a                 ; call after with another, that one: a program's own copy [2586]
            ld a, (asm_1_2379_n_fl_slot)         ; of it, BBC BASIC's channels) [2587]
            cp b		; Hyp.cls 2588
            ret nz		; Hyp.cls 2589
            ld e, (hl)		; Hyp.cls 2590
            inc hl		; Hyp.cls 2591
            ld d, (hl)		; Hyp.cls 2592
            inc hl		; Hyp.cls 2593
            push hl		; Hyp.cls 2594
            call asm_1_2379_n_fl_cmpf		; Hyp.cls 2595
            pop de		; Hyp.cls 2596
            ret z		; Hyp.cls 2597
            ld a, (de)              ; (the open's FCB still: this one from now on - unless it [2598]
            xor 1                   ; is the other file's: a program reading the record it [2599]
            ret nz                  ; writes, through that file's FCB) [2600]
            push de		; Hyp.cls 2601
            ld a, (var_hyp_fin)		; Hyp.cls 2602
            ld de, (asm_1_2379_n_fl_infcb)		; Hyp.cls 2603
            call asm_1_2379_n_fl_oth		; Hyp.cls 2604
            jr z, asm_1_2379_n_fl_is_no		; Hyp.cls 2605
            ld a, (var_hyp_fout)		; Hyp.cls 2606
            ld de, (asm_1_2379_n_fl_outfcb)		; Hyp.cls 2607
            call asm_1_2379_n_fl_oth		; Hyp.cls 2608
asm_1_2379_n_fl_is_no:		; Hyp.cls 2609
            pop de		; Hyp.cls 2610
            jr nz, asm_1_2379_n_fl_is_re		; Hyp.cls 2611
            inc a                   ; (NZ: not this one) [2612]
            ret		; Hyp.cls 2613
asm_1_2379_n_fl_is_re:		; Hyp.cls 2614
            xor a		; Hyp.cls 2615
            ld (de), a		; Hyp.cls 2616
            ld hl, (var_hyp_filecall_fcb)		; Hyp.cls 2617
            ex de, hl		; Hyp.cls 2618
            dec hl		; Hyp.cls 2619
            ld (hl), d		; Hyp.cls 2620
            dec hl		; Hyp.cls 2621
            ld (hl), e		; Hyp.cls 2622
            ret		; Hyp.cls 2623
asm_1_2379_n_fl_oth:                             ; Z: the slot's file (A: fin / fout), its FCB DE the call's [2624]
            ld b, a		; Hyp.cls 2625
            ld a, (asm_1_2379_n_fl_slot)		; Hyp.cls 2626
            cp b		; Hyp.cls 2627
            ret nz		; Hyp.cls 2628
asm_1_2379_n_fl_cmpf:                            ; Z: the call's FCB is DE [2629]
            ld hl, (var_hyp_filecall_fcb)		; Hyp.cls 2630
            or a		; Hyp.cls 2631
            sbc hl, de		; Hyp.cls 2632
            ret		; Hyp.cls 2633
asm_1_2379_n_fl_exit:		; Hyp.cls 3924
			ret			; end of #asm

asm_1_3930_n:		; #asm, Hyp.cls line 3930 (normal)
            ld (var_hyp_hsp), sp		; Hyp.cls 3931
            ld sp, (ntc_csp)		; Hyp.cls 3932
            ld bc, (var_hyp_hps)          ; (the buffers: the hypervisor's page) [3933]
            out (c), c		; Hyp.cls 3934
            ld a, (var_hyp_fileshut_slot)		; Hyp.cls 3935
            ld b, a		; Hyp.cls 3936
            ld a, (var_hyp_fin)		; Hyp.cls 3937
            cp b		; Hyp.cls 3938
            jr nz, asm_1_3930_n_fs_out		; Hyp.cls 3939
            xor a		; Hyp.cls 3940
            ld (var_hyp_fin), a		; Hyp.cls 3941
            push bc		; Hyp.cls 3942
            call #BC7A              ; CAS IN CLOSE [3943]
            di		; Hyp.cls 3944
            pop bc		; Hyp.cls 3945
asm_1_3930_n_fs_out:		; Hyp.cls 3946
            ld a, (var_hyp_fout)		; Hyp.cls 3947
            cp b		; Hyp.cls 3948
            jr nz, asm_1_3930_n_fs_done		; Hyp.cls 3949
            xor a		; Hyp.cls 3950
            ld (var_hyp_fout), a		; Hyp.cls 3951
            call #BC8F              ; CAS OUT CLOSE [3952]
            di		; Hyp.cls 3953
asm_1_3930_n_fs_done:		; Hyp.cls 3954
            ld bc, (ntc_rampt)		; Hyp.cls 3955
            out (c), c		; Hyp.cls 3956
            ld sp, (var_hyp_hsp)		; Hyp.cls 3957
			ret			; end of #asm

fn_keys_down:		; function down (asm keyword), Keys.cls line 44
            pop hl		; Keys.cls 45
            ld e, (hl)		; Keys.cls 46
            inc hl		; Keys.cls 47
            ld d, (hl)		; Keys.cls 48
            ex de, hl		; Keys.cls 49
            jp ntc_kdown		; Keys.cls 50
			ret			; end of #asm

fn_memory_freepages:		; function freepages (asm keyword), Memory.cls line 80
            pop hl		; Memory.cls 81
            ld (mem_res), hl		; Memory.cls 82
            ld hl, mem_freepages		; Memory.cls 83
            jp mem_go		; Memory.cls 84
			ret			; end of #asm

fn_memory_ramsize:		; function ramsize (asm keyword), Memory.cls line 90
            pop hl		; Memory.cls 91
            ld (mem_res), hl		; Memory.cls 92
            ld hl, mem_ramsize		; Memory.cls 93
            jp mem_go		; Memory.cls 94
			ret			; end of #asm

fn_memory_allocpage:		; function allocpage (asm keyword), Memory.cls line 219
            pop hl		; Memory.cls 220
            ld e, (hl)		; Memory.cls 221
            inc hl		; Memory.cls 222
            ld d, (hl)		; Memory.cls 223
            ld (mem_a1), de		; Memory.cls 224
            pop hl		; Memory.cls 225
            ld (mem_res), hl		; Memory.cls 226
            ld hl, mem_allocpage		; Memory.cls 227
            jp mem_go		; Memory.cls 228
			ret			; end of #asm

fn_memory_selectpage:		; function selectpage (asm keyword), Memory.cls line 250
            pop hl		; Memory.cls 251
            ld e, (hl)		; Memory.cls 252
            inc hl		; Memory.cls 253
            ld d, (hl)		; Memory.cls 254
            ld (mem_a1), de		; Memory.cls 255
            pop hl		; Memory.cls 256
            ld (mem_res), hl		; Memory.cls 257
            ld hl, mem_selpage		; Memory.cls 258
            jp mem_go		; Memory.cls 259
			ret			; end of #asm

fn_memory_readbyte:		; function readbyte (asm keyword), Memory.cls line 340
            pop hl		; Memory.cls 341
            ld (mem_a1), hl		; Memory.cls 342
            pop hl		; Memory.cls 343
            ld (mem_res), hl		; Memory.cls 344
            ld hl, mem_readbyte		; Memory.cls 345
            jp mem_go		; Memory.cls 346
			ret			; end of #asm

fn_memory_writebyte:		; sub writebyte (asm keyword), Memory.cls line 362
            pop hl		; Memory.cls 363
            ld (mem_a1), hl		; Memory.cls 364
            pop hl		; Memory.cls 365
            ld e, (hl)		; Memory.cls 366
            inc hl		; Memory.cls 367
            ld d, (hl)		; Memory.cls 368
            ld (mem_a2), de		; Memory.cls 369
            ld hl, mem_writebyte		; Memory.cls 370
            jp mem_go0		; Memory.cls 371
			ret			; end of #asm

fn_memory_writeword:		; sub writeword (asm keyword), Memory.cls line 376
            pop hl		; Memory.cls 377
            ld (mem_a1), hl		; Memory.cls 378
            pop hl		; Memory.cls 379
            ld e, (hl)		; Memory.cls 380
            inc hl		; Memory.cls 381
            ld d, (hl)		; Memory.cls 382
            ld (mem_a2), de		; Memory.cls 383
            ld hl, mem_writeword		; Memory.cls 384
            jp mem_go0		; Memory.cls 385
			ret			; end of #asm

fn_memory_copy:		; function copy (asm keyword), Memory.cls line 393
            pop hl		; Memory.cls 394
            ld (mem_a1), hl		; Memory.cls 395
            pop hl		; Memory.cls 396
            ld (mem_a2), hl		; Memory.cls 397
            pop hl		; Memory.cls 398
            ld e, (hl)		; Memory.cls 399
            inc hl		; Memory.cls 400
            ld d, (hl)		; Memory.cls 401
            ld (mem_a3), de		; Memory.cls 402
            pop hl		; Memory.cls 403
            ld (mem_res), hl		; Memory.cls 404
            ld hl, mem_copy		; Memory.cls 405
            jp mem_go		; Memory.cls 406
			ret			; end of #asm

fn_memory_banks:		; function banks (asm keyword), Memory.cls line 414
            pop hl		; Memory.cls 415
            ld (mem_res), hl		; Memory.cls 416
            ld hl, mem_bankcount		; Memory.cls 417
            jp mem_go		; Memory.cls 418
			ret			; end of #asm

fn_memory_allocbank:		; function allocbank (asm keyword), Memory.cls line 424
            pop hl		; Memory.cls 425
            ld (mem_res), hl		; Memory.cls 426
            ld hl, mem_allocbank		; Memory.cls 427
            jp mem_go		; Memory.cls 428
			ret			; end of #asm


ntc_rg59_e:
			IF ($ < 32768) && (ntc_rg60_e - ntc_rg60 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg60:
; ============================================================
; Variables
; ============================================================

ntc_rg60_e:
			IF ($ < 32768) && (ntc_rg61_e - ntc_rg61 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg61:
var_k:			dw 0
ntc_rg61_e:
			IF ($ < 32768) && (ntc_rg62_e - ntc_rg62 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg62:
var_ns:			dw 0
ntc_rg62_e:
			IF ($ < 32768) && (ntc_rg63_e - ntc_rg63 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg63:
var_i:			dw 0
ntc_rg63_e:
			IF ($ < 32768) && (ntc_rg64_e - ntc_rg64 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg64:
var_hp:			dw 0
ntc_rg64_e:
			IF ($ < 32768) && (ntc_rg65_e - ntc_rg65 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg65:
var_memory_selectpage_selectpage:			dw 0
ntc_rg65_e:
			IF ($ < 32768) && (ntc_rg66_e - ntc_rg66 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg66:
var_hyp_filecall_filecall:			dw 0
ntc_rg66_e:
			IF ($ < 32768) && (ntc_rg67_e - ntc_rg67 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg67:
for3_l:			dw 0
ntc_rg67_e:
			IF ($ < 32768) && (ntc_rg68_e - ntc_rg68 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg68:
var_memory_allocbank_allocbank:			dw 0
ntc_rg68_e:
			IF ($ < 32768) && (ntc_rg69_e - ntc_rg69 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg69:
var_memory_bankpage_bankpage:			dw 0
ntc_rg69_e:
			IF ($ < 32768) && (ntc_rg70_e - ntc_rg70 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg70:
var_hyp_setting_setting:			dw 0
ntc_rg70_e:
			IF ($ < 32768) && (ntc_rg71_e - ntc_rg71 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg71:
			db 82			; capacity
var_ob:			ds 83
ntc_rg71_e:
			IF ($ < 32768) && (ntc_rg72_e - ntc_rg72 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg72:
var_front:			dw 0
ntc_rg72_e:
			IF ($ < 32768) && (ntc_rg73_e - ntc_rg73 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg73:
			db 72			; capacity
var_a:			ds 73
ntc_rg73_e:
			IF ($ < 32768) && (ntc_rg74_e - ntc_rg74 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg74:
var_hk:			dw 0
ntc_rg74_e:
			IF ($ < 32768) && (ntc_rg75_e - ntc_rg75 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg75:
var_hot_take_take:			dw 0
ntc_rg75_e:
			IF ($ < 32768) && (ntc_rg76_e - ntc_rg76 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg76:
var_back:			dw 0
ntc_rg76_e:
			IF ($ < 32768) && (ntc_rg77_e - ntc_rg77 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg77:
var_pk:			dw 0
ntc_rg77_e:
			IF ($ < 32768) && (ntc_rg78_e - ntc_rg78 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg78:
var_wt:			dw 0
ntc_rg78_e:
			IF ($ < 32768) && (ntc_rg79_e - ntc_rg79 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg79:
var_hot_control_control:			dw 0
ntc_rg79_e:
			IF ($ < 32768) && (ntc_rg80_e - ntc_rg80 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg80:
var_hot_held_held:			dw 0
ntc_rg80_e:
			IF ($ < 32768) && (ntc_rg81_e - ntc_rg81 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg81:
var_running_running:			dw 0
ntc_rg81_e:
			IF ($ < 32768) && (ntc_rg82_e - ntc_rg82 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg82:
var_td:			dw 0
ntc_rg82_e:
			IF ($ < 32768) && (ntc_rg83_e - ntc_rg83 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg83:
var_tc:			dw 0
ntc_rg83_e:
			IF ($ < 32768) && (ntc_rg84_e - ntc_rg84 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg84:
var_quit:			dw 0
ntc_rg84_e:
			IF ($ < 32768) && (ntc_rg85_e - ntc_rg85 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg85:
var_hyp_scr_scr:			dw 0
ntc_rg85_e:
			IF ($ < 32768) && (ntc_rg86_e - ntc_rg86 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg86:
var_runs:			dw 0
ntc_rg86_e:
			IF ($ < 32768) && (ntc_rg87_e - ntc_rg87 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg87:
p_running_rs:			dw 0
ntc_rg87_e:
			IF ($ < 32768) && (ntc_rg88_e - ntc_rg88 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg88:
var_running_j:			dw 0
ntc_rg88_e:
			IF ($ < 32768) && (ntc_rg89_e - ntc_rg89 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg89:
for17_l:			dw 0
ntc_rg89_e:
			IF ($ < 32768) && (ntc_rg90_e - ntc_rg90 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg90:
p_ready_rs:			dw 0
ntc_rg90_e:
			IF ($ < 32768) && (ntc_rg91_e - ntc_rg91 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg91:
var_ready_t:			dw 0
ntc_rg91_e:
			IF ($ < 32768) && (ntc_rg92_e - ntc_rg92 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg92:
var_ready_ready:			dw 0
ntc_rg92_e:
			IF ($ < 32768) && (ntc_rg93_e - ntc_rg93 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg93:
p_runnext_rs:			dw 0
ntc_rg93_e:
			IF ($ < 32768) && (ntc_rg94_e - ntc_rg94 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg94:
var_runnext_n:			dw 0
ntc_rg94_e:
			IF ($ < 32768) && (ntc_rg95_e - ntc_rg95 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg95:
var_runnext_t:			dw 0
ntc_rg95_e:
			IF ($ < 32768) && (ntc_rg96_e - ntc_rg96 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg96:
var_runnext_r:			dw 0
ntc_rg96_e:
			IF ($ < 32768) && (ntc_rg97_e - ntc_rg97 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg97:
var_runnext_c:			dw 0
ntc_rg97_e:
			IF ($ < 32768) && (ntc_rg98_e - ntc_rg98 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg98:
var_runnext_q:			dw 0
ntc_rg98_e:
			IF ($ < 32768) && (ntc_rg99_e - ntc_rg99 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg99:
var_fr:			dw 0
ntc_rg99_e:
			IF ($ < 32768) && (ntc_rg100_e - ntc_rg100 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg100:
for25_l:			dw 0
ntc_rg100_e:
			IF ($ < 32768) && (ntc_rg101_e - ntc_rg101 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg101:
var_cur:			dw 0
ntc_rg101_e:
			IF ($ < 32768) && (ntc_rg102_e - ntc_rg102 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg102:
var_hyp_run_run:			dw 0
ntc_rg102_e:
			IF ($ < 32768) && (ntc_rg103_e - ntc_rg103 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg103:
var_far_far:			dw 0, 0
ntc_rg103_e:
			IF ($ < 32768) && (ntc_rg104_e - ntc_rg104 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg104:
var_memory_readbyte_readbyte:			dw 0
ntc_rg104_e:
			IF ($ < 32768) && (ntc_rg105_e - ntc_rg105 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg105:
var_hyp_count_count:			dw 0
ntc_rg105_e:
			IF ($ < 32768) && (ntc_rg106_e - ntc_rg106 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg106:
var_hyp_fn_fn:			dw 0
ntc_rg106_e:
			IF ($ < 32768) && (ntc_rg107_e - ntc_rg107 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg107:
p_bdos_rs:			dw 0
ntc_rg107_e:
			IF ($ < 32768) && (ntc_rg108_e - ntc_rg108 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg108:
var_bdos_t:			dw 0
ntc_rg108_e:
			IF ($ < 32768) && (ntc_rg109_e - ntc_rg109 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg109:
var_bdos_f:			dw 0
ntc_rg109_e:
			IF ($ < 32768) && (ntc_rg110_e - ntc_rg110 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg110:
var_bdos_e:			dw 0
ntc_rg110_e:
			IF ($ < 32768) && (ntc_rg111_e - ntc_rg111 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg111:
var_bdos_a:			dw 0
ntc_rg111_e:
			IF ($ < 32768) && (ntc_rg112_e - ntc_rg112 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg112:
var_hyp_arg_arg:			dw 0
ntc_rg112_e:
			IF ($ < 32768) && (ntc_rg113_e - ntc_rg113 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg113:
var_bdos___sel42:			dw 0
ntc_rg113_e:
			IF ($ < 32768) && (ntc_rg114_e - ntc_rg114 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg114:
var_sys_sys:			dw 0
ntc_rg114_e:
			IF ($ < 32768) && (ntc_rg115_e - ntc_rg115 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg115:
p_sys_rs:			dw 0
ntc_rg115_e:
			IF ($ < 32768) && (ntc_rg116_e - ntc_rg116 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg116:
var_sys_t:			dw 0
ntc_rg116_e:
			IF ($ < 32768) && (ntc_rg117_e - ntc_rg117 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg117:
var_sys_p:			dw 0
ntc_rg117_e:
			IF ($ < 32768) && (ntc_rg118_e - ntc_rg118 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg118:
var_sys_o:			dw 0
ntc_rg118_e:
			IF ($ < 32768) && (ntc_rg119_e - ntc_rg119 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg119:
var_sys_s:			dw 0
ntc_rg119_e:
			IF ($ < 32768) && (ntc_rg120_e - ntc_rg120 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg120:
var_sys_d:			dw 0
ntc_rg120_e:
			IF ($ < 32768) && (ntc_rg121_e - ntc_rg121 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg121:
var_txs:			dw 0
ntc_rg121_e:
			IF ($ < 32768) && (ntc_rg122_e - ntc_rg122 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg122:
			db 60			; capacity
var_en:			ds 61
ntc_rg122_e:
			IF ($ < 32768) && (ntc_rg123_e - ntc_rg123 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg123:
p_puten_rs:			dw 0
ntc_rg123_e:
			IF ($ < 32768) && (ntc_rg124_e - ntc_rg124 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg124:
var_puten_t:			dw 0
ntc_rg124_e:
			IF ($ < 32768) && (ntc_rg125_e - ntc_rg125 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg125:
var_puten_a:			dw 0
ntc_rg125_e:
			IF ($ < 32768) && (ntc_rg126_e - ntc_rg126 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg126:
var_nearp_nearp:			dw 0, 0
ntc_rg126_e:
			IF ($ < 32768) && (ntc_rg127_e - ntc_rg127 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg127:
var_memory_copy_copy:			dw 0
ntc_rg127_e:
			IF ($ < 32768) && (ntc_rg128_e - ntc_rg128 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg128:
p_hopen_rs:			dw 0
ntc_rg128_e:
			IF ($ < 32768) && (ntc_rg129_e - ntc_rg129 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg129:
var_hopen_hopen:			dw 0
ntc_rg129_e:
			IF ($ < 32768) && (ntc_rg130_e - ntc_rg130 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg130:
			db 16			; capacity
var_dn:			ds 17
ntc_rg130_e:
			IF ($ < 32768) && (ntc_rg131_e - ntc_rg131 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg131:
p_hclose_rs:			dw 0
ntc_rg131_e:
			IF ($ < 32768) && (ntc_rg132_e - ntc_rg132 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg132:
var_hclose_r:			dw 0
ntc_rg132_e:
			IF ($ < 32768) && (ntc_rg133_e - ntc_rg133 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg133:
p_filesshut_rs:			dw 0
ntc_rg133_e:
			IF ($ < 32768) && (ntc_rg134_e - ntc_rg134 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg134:
var_filesshut_t:			dw 0
ntc_rg134_e:
			IF ($ < 32768) && (ntc_rg135_e - ntc_rg135 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg135:
var_filesshut_r:			dw 0
ntc_rg135_e:
			IF ($ < 32768) && (ntc_rg136_e - ntc_rg136 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg136:
p_collected_rs:			dw 0
ntc_rg136_e:
			IF ($ < 32768) && (ntc_rg137_e - ntc_rg137 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg137:
var_collected_t:			dw 0
ntc_rg137_e:
			IF ($ < 32768) && (ntc_rg138_e - ntc_rg138 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg138:
var_collected_n:			dw 0
ntc_rg138_e:
			IF ($ < 32768) && (ntc_rg139_e - ntc_rg139 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg139:
p_puts_rs:			dw 0
ntc_rg139_e:
			IF ($ < 32768) && (ntc_rg140_e - ntc_rg140 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg140:
var_puts_t:			dw 0
ntc_rg140_e:
			IF ($ < 32768) && (ntc_rg141_e - ntc_rg141 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg141:
			db 255			; capacity
var_puts_s:			ds 256
ntc_rg141_e:
			IF ($ < 32768) && (ntc_rg142_e - ntc_rg142 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg142:
p_putln_rs:			dw 0
ntc_rg142_e:
			IF ($ < 32768) && (ntc_rg143_e - ntc_rg143 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg143:
var_putln_t:			dw 0
ntc_rg143_e:
			IF ($ < 32768) && (ntc_rg144_e - ntc_rg144 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg144:
			db 255			; capacity
var_putln_s:			ds 256
ntc_rg144_e:
			IF ($ < 32768) && (ntc_rg145_e - ntc_rg145 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg145:
p_putc_rs:			dw 0
ntc_rg145_e:
			IF ($ < 32768) && (ntc_rg146_e - ntc_rg146 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg146:
var_putc_t:			dw 0
ntc_rg146_e:
			IF ($ < 32768) && (ntc_rg147_e - ntc_rg147 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg147:
var_putc_c:			dw 0
ntc_rg147_e:
			IF ($ < 32768) && (ntc_rg148_e - ntc_rg148 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg148:
p_nearp_rs:			dw 0
ntc_rg148_e:
			IF ($ < 32768) && (ntc_rg149_e - ntc_rg149 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg149:
var_nearp_p:			dw 0
ntc_rg149_e:
			IF ($ < 32768) && (ntc_rg150_e - ntc_rg150 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg150:
p_far_rs:			dw 0
ntc_rg150_e:
			IF ($ < 32768) && (ntc_rg151_e - ntc_rg151 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg151:
var_far_t:			dw 0
ntc_rg151_e:
			IF ($ < 32768) && (ntc_rg152_e - ntc_rg152 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg152:
var_far_a:			dw 0
ntc_rg152_e:
			IF ($ < 32768) && (ntc_rg153_e - ntc_rg153 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg153:
p_clst_rs:			dw 0
ntc_rg153_e:
			IF ($ < 32768) && (ntc_rg154_e - ntc_rg154 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg154:
var_clst_t:			dw 0
ntc_rg154_e:
			IF ($ < 32768) && (ntc_rg155_e - ntc_rg155 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg155:
p_tofront_rs:			dw 0
ntc_rg155_e:
			IF ($ < 32768) && (ntc_rg156_e - ntc_rg156 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg156:
var_tofront_t:			dw 0
ntc_rg156_e:
			IF ($ < 32768) && (ntc_rg157_e - ntc_rg157 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg157:
var_tofront_r:			dw 0
ntc_rg157_e:
			IF ($ < 32768) && (ntc_rg158_e - ntc_rg158 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg158:
p_setmode_rs:			dw 0
ntc_rg158_e:
			IF ($ < 32768) && (ntc_rg159_e - ntc_rg159 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg159:
var_setmode_t:			dw 0
ntc_rg159_e:
			IF ($ < 32768) && (ntc_rg160_e - ntc_rg160 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg160:
var_setmode_m:			dw 0
ntc_rg160_e:
			IF ($ < 32768) && (ntc_rg161_e - ntc_rg161 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg161:
var_setmode_r:			dw 0
ntc_rg161_e:
			IF ($ < 32768) && (ntc_rg162_e - ntc_rg162 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg162:
			db 255			; capacity
var_n_n:			ds 256
ntc_rg162_e:
			IF ($ < 32768) && (ntc_rg163_e - ntc_rg163 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg163:
p_showtop_rs:			dw 0
ntc_rg163_e:
			IF ($ < 32768) && (ntc_rg164_e - ntc_rg164 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg164:
var_showtop_j:			dw 0
ntc_rg164_e:
			IF ($ < 32768) && (ntc_rg165_e - ntc_rg165 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg165:
p_toplines_rs:			dw 0
ntc_rg165_e:
			IF ($ < 32768) && (ntc_rg166_e - ntc_rg166 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg166:
var_toplines_mark:			dw 0
ntc_rg166_e:
			IF ($ < 32768) && (ntc_rg167_e - ntc_rg167 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg167:
var_toplines_keys:			dw 0
ntc_rg167_e:
			IF ($ < 32768) && (ntc_rg168_e - ntc_rg168 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg168:
var_toplines_j:			dw 0
ntc_rg168_e:
			IF ($ < 32768) && (ntc_rg169_e - ntc_rg169 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg169:
			db 14			; capacity
var_toplines_s:			ds 15
ntc_rg169_e:
			IF ($ < 32768) && (ntc_rg170_e - ntc_rg170 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg170:
var_txn:			dw 0
ntc_rg170_e:
			IF ($ < 32768) && (ntc_rg171_e - ntc_rg171 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg171:
			db 255			; capacity
var_sk_sk:			ds 256
ntc_rg171_e:
			IF ($ < 32768) && (ntc_rg172_e - ntc_rg172 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg172:
for63_l:			dw 0
ntc_rg172_e:
			IF ($ < 32768) && (ntc_rg173_e - ntc_rg173 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg173:
var_ld:			dw 0
ntc_rg173_e:
			IF ($ < 32768) && (ntc_rg174_e - ntc_rg174 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg174:
var_rate_rate:			dw 0
ntc_rg174_e:
			IF ($ < 32768) && (ntc_rg175_e - ntc_rg175 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg175:
			db 255			; capacity
var_pad_pad:			ds 256
ntc_rg175_e:
			IF ($ < 32768) && (ntc_rg176_e - ntc_rg176 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg176:
p_totals_rs:			dw 0
ntc_rg176_e:
			IF ($ < 32768) && (ntc_rg177_e - ntc_rg177 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg177:
var_memory_ramsize_ramsize:			dw 0
ntc_rg177_e:
			IF ($ < 32768) && (ntc_rg178_e - ntc_rg178 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg178:
var_memory_freepages_freepages:			dw 0
ntc_rg178_e:
			IF ($ < 32768) && (ntc_rg179_e - ntc_rg179 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg179:
p_topadd_rs:			dw 0
ntc_rg179_e:
			IF ($ < 32768) && (ntc_rg180_e - ntc_rg180 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg180:
			db 255			; capacity
var_topadd_s:			ds 256
ntc_rg180_e:
			IF ($ < 32768) && (ntc_rg181_e - ntc_rg181 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg181:
p_roll_rs:			dw 0
ntc_rg181_e:
			IF ($ < 32768) && (ntc_rg182_e - ntc_rg182 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg182:
var_roll_j:			dw 0
ntc_rg182_e:
			IF ($ < 32768) && (ntc_rg183_e - ntc_rg183 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg183:
for68_l:			dw 0
ntc_rg183_e:
			IF ($ < 32768) && (ntc_rg184_e - ntc_rg184 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg184:
p_pad_rs:			dw 0
ntc_rg184_e:
			IF ($ < 32768) && (ntc_rg185_e - ntc_rg185 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg185:
var_pad_v:			dw 0
ntc_rg185_e:
			IF ($ < 32768) && (ntc_rg186_e - ntc_rg186 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg186:
p_rate_rs:			dw 0
ntc_rg186_e:
			IF ($ < 32768) && (ntc_rg187_e - ntc_rg187 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg187:
var_rate_n:			dw 0
ntc_rg187_e:
			IF ($ < 32768) && (ntc_rg188_e - ntc_rg188 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg188:
var_rate_d:			dw 0
ntc_rg188_e:
			IF ($ < 32768) && (ntc_rg189_e - ntc_rg189 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg189:
p_install_rs:			dw 0
ntc_rg189_e:
			IF ($ < 32768) && (ntc_rg190_e - ntc_rg190 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg190:
var_install_t:			dw 0
ntc_rg190_e:
			IF ($ < 32768) && (ntc_rg191_e - ntc_rg191 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg191:
var_install_p:			dw 0
ntc_rg191_e:
			IF ($ < 32768) && (ntc_rg192_e - ntc_rg192 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg192:
var_install_n:			dw 0
ntc_rg192_e:
			IF ($ < 32768) && (ntc_rg193_e - ntc_rg193 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg193:
var_hyp_farptr_farptr:			dw 0, 0
ntc_rg193_e:
			IF ($ < 32768) && (ntc_rg194_e - ntc_rg194 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg194:
p_resetslot_rs:			dw 0
ntc_rg194_e:
			IF ($ < 32768) && (ntc_rg195_e - ntc_rg195 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg195:
var_resetslot_s:			dw 0
ntc_rg195_e:
			IF ($ < 32768) && (ntc_rg196_e - ntc_rg196 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg196:
p_openslot_rs:			dw 0
ntc_rg196_e:
			IF ($ < 32768) && (ntc_rg197_e - ntc_rg197 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg197:
var_openslot_t:			dw 0
ntc_rg197_e:
			IF ($ < 32768) && (ntc_rg198_e - ntc_rg198 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg198:
p_sk_rs:			dw 0
ntc_rg198_e:
			IF ($ < 32768) && (ntc_rg199_e - ntc_rg199 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg199:
p_getnm_rs:			dw 0
ntc_rg199_e:
			IF ($ < 32768) && (ntc_rg200_e - ntc_rg200 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg200:
var_getnm_t:			dw 0
ntc_rg200_e:
			IF ($ < 32768) && (ntc_rg201_e - ntc_rg201 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg201:
var_getnm_n:			dw 0
ntc_rg201_e:
			IF ($ < 32768) && (ntc_rg202_e - ntc_rg202 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg202:
p_n_rs:			dw 0
ntc_rg202_e:
			IF ($ < 32768) && (ntc_rg203_e - ntc_rg203 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg203:
var_n_v:			dw 0
ntc_rg203_e:
			IF ($ < 32768) && (ntc_rg204_e - ntc_rg204 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg204:
p_prompt_rs:			dw 0
ntc_rg204_e:
			IF ($ < 32768) && (ntc_rg205_e - ntc_rg205 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg205:
var_prompt_t:			dw 0
ntc_rg205_e:
			IF ($ < 32768) && (ntc_rg206_e - ntc_rg206 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg206:
p_keyin_rs:			dw 0
ntc_rg206_e:
			IF ($ < 32768) && (ntc_rg207_e - ntc_rg207 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg207:
var_keyin_k:			dw 0
ntc_rg207_e:
			IF ($ < 32768) && (ntc_rg208_e - ntc_rg208 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg208:
var_keyin_t:			dw 0
ntc_rg208_e:
			IF ($ < 32768) && (ntc_rg209_e - ntc_rg209 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg209:
var_keyin_n:			dw 0
ntc_rg209_e:
			IF ($ < 32768) && (ntc_rg210_e - ntc_rg210 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg210:
p_command_rs:			dw 0
ntc_rg210_e:
			IF ($ < 32768) && (ntc_rg211_e - ntc_rg211 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg211:
var_command_t:			dw 0
ntc_rg211_e:
			IF ($ < 32768) && (ntc_rg212_e - ntc_rg212 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg212:
			db 72			; capacity
var_command_c:			ds 73
ntc_rg212_e:
			IF ($ < 32768) && (ntc_rg213_e - ntc_rg213 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg213:
var_command_p:			dw 0
ntc_rg213_e:
			IF ($ < 32768) && (ntc_rg214_e - ntc_rg214 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg214:
var_command_s:			dw 0
ntc_rg214_e:
			IF ($ < 32768) && (ntc_rg215_e - ntc_rg215 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg215:
			db 72			; capacity
var_b:			ds 73
ntc_rg215_e:
			IF ($ < 32768) && (ntc_rg216_e - ntc_rg216 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg216:
			db 255			; capacity
var_command___sel81:			ds 256
ntc_rg216_e:
			IF ($ < 32768) && (ntc_rg217_e - ntc_rg217 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg217:
var_bare:			dw 0
ntc_rg217_e:
			IF ($ < 32768) && (ntc_rg218_e - ntc_rg218 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg218:
p_starttask_rs:			dw 0
ntc_rg218_e:
			IF ($ < 32768) && (ntc_rg219_e - ntc_rg219 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg219:
var_starttask_t:			dw 0
ntc_rg219_e:
			IF ($ < 32768) && (ntc_rg220_e - ntc_rg220 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg220:
var_starttask_s:			dw 0
ntc_rg220_e:
			IF ($ < 32768) && (ntc_rg221_e - ntc_rg221 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg221:
var_starttask_h:			dw 0
ntc_rg221_e:
			IF ($ < 32768) && (ntc_rg222_e - ntc_rg222 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg222:
var_starttask_n:			dw 0
ntc_rg222_e:
			IF ($ < 32768) && (ntc_rg223_e - ntc_rg223 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg223:
var_starttask_rest:			dw 0
ntc_rg223_e:
			IF ($ < 32768) && (ntc_rg224_e - ntc_rg224 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg224:
var_starttask_com:			dw 0
ntc_rg224_e:
			IF ($ < 32768) && (ntc_rg225_e - ntc_rg225 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg225:
			db 72			; capacity
var_starttask_w:			ds 73
ntc_rg225_e:
			IF ($ < 32768) && (ntc_rg226_e - ntc_rg226 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg226:
var_starttask_d:			dw 0
ntc_rg226_e:
			IF ($ < 32768) && (ntc_rg227_e - ntc_rg227 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg227:
var_hyp_info_info:			dw 0
ntc_rg227_e:
			IF ($ < 32768) && (ntc_rg228_e - ntc_rg228 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg228:
p_notfound_rs:			dw 0
ntc_rg228_e:
			IF ($ < 32768) && (ntc_rg229_e - ntc_rg229 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg229:
var_notfound_t:			dw 0
ntc_rg229_e:
			IF ($ < 32768) && (ntc_rg230_e - ntc_rg230 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg230:
p_endtask_rs:			dw 0
ntc_rg230_e:
			IF ($ < 32768) && (ntc_rg231_e - ntc_rg231 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg231:
var_endtask_t:			dw 0
ntc_rg231_e:
			IF ($ < 32768) && (ntc_rg232_e - ntc_rg232 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg232:
var_endtask_c:			dw 0
ntc_rg232_e:
			IF ($ < 32768) && (ntc_rg233_e - ntc_rg233 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg233:
var_hyp_hps:			dw 0
ntc_rg233_e:
			IF ($ < 32768) && (ntc_rg234_e - ntc_rg234 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg234:
var_hyp_hsp:			dw 0
ntc_rg234_e:
			IF ($ < 32768) && (ntc_rg235_e - ntc_rg235 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg235:
p_hyp_con_rs:			dw 0
ntc_rg235_e:
			IF ($ < 32768) && (ntc_rg236_e - ntc_rg236 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg236:
var_hyp_con_pg:			dw 0
ntc_rg236_e:
			IF ($ < 32768) && (ntc_rg237_e - ntc_rg237 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg237:
var_hyp_con_src:			dw 0
ntc_rg237_e:
			IF ($ < 32768) && (ntc_rg238_e - ntc_rg238 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg238:
var_hyp_con_n:			dw 0
ntc_rg238_e:
			IF ($ < 32768) && (ntc_rg239_e - ntc_rg239 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg239:
var_hyp_con_front:			dw 0
ntc_rg239_e:
			IF ($ < 32768) && (ntc_rg240_e - ntc_rg240 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg240:
var_hyp_ccu:			dw 0
ntc_rg240_e:
			IF ($ < 32768) && (ntc_rg241_e - ntc_rg241 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg241:
var_hyp_nta:			dw 0
ntc_rg241_e:
			IF ($ < 32768) && (ntc_rg242_e - ntc_rg242 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg242:
var_hyp_ntb:			dw 0
ntc_rg242_e:
			IF ($ < 32768) && (ntc_rg243_e - ntc_rg243 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg243:
var_hyp_sco:			dw 0
ntc_rg243_e:
			IF ($ < 32768) && (ntc_rg244_e - ntc_rg244 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg244:
var_hyp_scc:			dw 0
ntc_rg244_e:
			IF ($ < 32768) && (ntc_rg245_e - ntc_rg245 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg245:
var_hyp_pon:			dw 0
ntc_rg245_e:
			IF ($ < 32768) && (ntc_rg246_e - ntc_rg246 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg246:
var_hyp_ntu:			dw 0
ntc_rg246_e:
			IF ($ < 32768) && (ntc_rg247_e - ntc_rg247 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg247:
p_hyp_say_rs:			dw 0
ntc_rg247_e:
			IF ($ < 32768) && (ntc_rg248_e - ntc_rg248 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg248:
var_hyp_say_p:			dw 0
ntc_rg248_e:
			IF ($ < 32768) && (ntc_rg249_e - ntc_rg249 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg249:
var_hyp_say_n:			dw 0
ntc_rg249_e:
			IF ($ < 32768) && (ntc_rg250_e - ntc_rg250 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg250:
var_hyp_say_col:			dw 0
ntc_rg250_e:
			IF ($ < 32768) && (ntc_rg251_e - ntc_rg251 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg251:
var_hyp_say_row:			dw 0
ntc_rg251_e:
			IF ($ < 32768) && (ntc_rg252_e - ntc_rg252 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg252:
p_hyp_scr_rs:			dw 0
ntc_rg252_e:
			IF ($ < 32768) && (ntc_rg253_e - ntc_rg253 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg253:
var_hyp_scr_m:			dw 0
ntc_rg253_e:
			IF ($ < 32768) && (ntc_rg254_e - ntc_rg254 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg254:
var_hyp_scr_k:			dw 0
ntc_rg254_e:
			IF ($ < 32768) && (ntc_rg255_e - ntc_rg255 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg255:
var_hyp_scw:			dw 0
ntc_rg255_e:
			IF ($ < 32768) && (ntc_rg256_e - ntc_rg256 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg256:
p_hyp_keyrep_rs:			dw 0
ntc_rg256_e:
			IF ($ < 32768) && (ntc_rg257_e - ntc_rg257 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg257:
var_hyp_keyrep_f:			dw 0
ntc_rg257_e:
			IF ($ < 32768) && (ntc_rg258_e - ntc_rg258 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg258:
p_hyp_show_rs:			dw 0
ntc_rg258_e:
			IF ($ < 32768) && (ntc_rg259_e - ntc_rg259 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg259:
var_hyp_show_pg:			dw 0
ntc_rg259_e:
			IF ($ < 32768) && (ntc_rg260_e - ntc_rg260 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg260:
p_hyp_reply_rs:			dw 0
ntc_rg260_e:
			IF ($ < 32768) && (ntc_rg261_e - ntc_rg261 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg261:
var_hyp_reply_a:			dw 0
ntc_rg261_e:
			IF ($ < 32768) && (ntc_rg262_e - ntc_rg262 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg262:
var_hyp_reply_hl:			dw 0
ntc_rg262_e:
			IF ($ < 32768) && (ntc_rg263_e - ntc_rg263 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg263:
var_hyp_ra:			dw 0
ntc_rg263_e:
			IF ($ < 32768) && (ntc_rg264_e - ntc_rg264 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg264:
var_hyp_rhl:			dw 0
ntc_rg264_e:
			IF ($ < 32768) && (ntc_rg265_e - ntc_rg265 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg265:
p_hyp_fn_rs:			dw 0
ntc_rg265_e:
			IF ($ < 32768) && (ntc_rg266_e - ntc_rg266 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg266:
var_hyp_rfn:			dw 0
ntc_rg266_e:
			IF ($ < 32768) && (ntc_rg267_e - ntc_rg267 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg267:
p_hyp_arg_rs:			dw 0
ntc_rg267_e:
			IF ($ < 32768) && (ntc_rg268_e - ntc_rg268 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg268:
var_hyp_rde:			dw 0
ntc_rg268_e:
			IF ($ < 32768) && (ntc_rg269_e - ntc_rg269 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg269:
p_hyp_count_rs:			dw 0
ntc_rg269_e:
			IF ($ < 32768) && (ntc_rg270_e - ntc_rg270 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg270:
var_hyp_rcnt:			dw 0
ntc_rg270_e:
			IF ($ < 32768) && (ntc_rg271_e - ntc_rg271 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg271:
p_hyp_run_rs:			dw 0
ntc_rg271_e:
			IF ($ < 32768) && (ntc_rg272_e - ntc_rg272 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg272:
var_hyp_run_setting:			dw 0
ntc_rg272_e:
			IF ($ < 32768) && (ntc_rg273_e - ntc_rg273 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg273:
var_hyp_sps:			dw 0
ntc_rg273_e:
			IF ($ < 32768) && (ntc_rg274_e - ntc_rg274 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg274:
var_hyp_rrom:			dw 0
ntc_rg274_e:
			IF ($ < 32768) && (ntc_rg275_e - ntc_rg275 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg275:
var_hyp_slc:			dw 0
ntc_rg275_e:
			IF ($ < 32768) && (ntc_rg276_e - ntc_rg276 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg276:
var_hyp_rclr:			dw 0
ntc_rg276_e:
			IF ($ < 32768) && (ntc_rg277_e - ntc_rg277 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg277:
p_hyp_vdu_rs:			dw 0
ntc_rg277_e:
			IF ($ < 32768) && (ntc_rg278_e - ntc_rg278 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg278:
var_hyp_vdu_on:			dw 0
ntc_rg278_e:
			IF ($ < 32768) && (ntc_rg279_e - ntc_rg279 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg279:
p_hyp_filecall_rs:			dw 0
ntc_rg279_e:
			IF ($ < 32768) && (ntc_rg280_e - ntc_rg280 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg280:
var_hyp_filecall_f:			dw 0
ntc_rg280_e:
			IF ($ < 32768) && (ntc_rg281_e - ntc_rg281 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg281:
var_hyp_filecall_fcb:			dw 0
ntc_rg281_e:
			IF ($ < 32768) && (ntc_rg282_e - ntc_rg282 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg282:
var_hyp_filecall_slot:			dw 0
ntc_rg282_e:
			IF ($ < 32768) && (ntc_rg283_e - ntc_rg283 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg283:
var_hyp_filecall_setting:			dw 0
ntc_rg283_e:
			IF ($ < 32768) && (ntc_rg284_e - ntc_rg284 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg284:
var_hyp_filecall_dma:			dw 0
ntc_rg284_e:
			IF ($ < 32768) && (ntc_rg285_e - ntc_rg285 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg285:
var_hyp_filecall_drive:			dw 0
ntc_rg285_e:
			IF ($ < 32768) && (ntc_rg286_e - ntc_rg286 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg286:
var_hyp_filecall_buf:			dw 0
ntc_rg286_e:
			IF ($ < 32768) && (ntc_rg287_e - ntc_rg287 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg287:
var_hyp_drs:			dw 0
ntc_rg287_e:
			IF ($ < 32768) && (ntc_rg288_e - ntc_rg288 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg288:
var_hyp_hdr:			dw 0
ntc_rg288_e:
			IF ($ < 32768) && (ntc_rg289_e - ntc_rg289 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg289:
var_hyp_dxb:			dw 0
ntc_rg289_e:
			IF ($ < 32768) && (ntc_rg290_e - ntc_rg290 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg290:
var_hyp_fin:			dw 0
ntc_rg290_e:
			IF ($ < 32768) && (ntc_rg291_e - ntc_rg291 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg291:
var_hyp_fout:			dw 0
ntc_rg291_e:
			IF ($ < 32768) && (ntc_rg292_e - ntc_rg292 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg292:
p_hyp_fileshut_rs:			dw 0
ntc_rg292_e:
			IF ($ < 32768) && (ntc_rg293_e - ntc_rg293 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg293:
var_hyp_fileshut_slot:			dw 0
ntc_rg293_e:
			IF ($ < 32768) && (ntc_rg294_e - ntc_rg294 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg294:
p_hot_speed_rs:			dw 0
ntc_rg294_e:
			IF ($ < 32768) && (ntc_rg295_e - ntc_rg295 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg295:
var_hot_speed_f:			dw 0
ntc_rg295_e:
			IF ($ < 32768) && (ntc_rg296_e - ntc_rg296 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg296:
var_hot_dbl:			dw 0
ntc_rg296_e:
			IF ($ < 32768) && (ntc_rg297_e - ntc_rg297 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg297:
p_hot_slots_rs:			dw 0
ntc_rg297_e:
			IF ($ < 32768) && (ntc_rg298_e - ntc_rg298 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg298:
var_hot_slots_n:			dw 0
ntc_rg298_e:
			IF ($ < 32768) && (ntc_rg299_e - ntc_rg299 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg299:
var_hot_ns:			dw 0
ntc_rg299_e:
			IF ($ < 32768) && (ntc_rg300_e - ntc_rg300 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg300:
p_hot_tick_rs:			dw 0
ntc_rg300_e:
			IF ($ < 32768) && (ntc_rg301_e - ntc_rg301 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg301:
var_hot_tick_k:			dw 0
ntc_rg301_e:
			IF ($ < 32768) && (ntc_rg302_e - ntc_rg302 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg302:
var_hot_ctl:			dw 0
ntc_rg302_e:
			IF ($ < 32768) && (ntc_rg303_e - ntc_rg303 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg303:
var_keys_down_down:			dw 0
ntc_rg303_e:
			IF ($ < 32768) && (ntc_rg304_e - ntc_rg304 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg304:
var_hot_last:			dw 0
ntc_rg304_e:
			IF ($ < 32768) && (ntc_rg305_e - ntc_rg305 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg305:
var_hot_one:			dw 0
ntc_rg305_e:
			IF ($ < 32768) && (ntc_rg306_e - ntc_rg306 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg306:
var_hot_pend:			dw 0
ntc_rg306_e:
			IF ($ < 32768) && (ntc_rg307_e - ntc_rg307 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg307:
var_hot_age:			dw 0
ntc_rg307_e:
			IF ($ < 32768) && (ntc_rg308_e - ntc_rg308 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg308:
p_hot_take_rs:			dw 0
ntc_rg308_e:
			IF ($ < 32768) && (ntc_rg309_e - ntc_rg309 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg309:
p_hot_control_rs:			dw 0
ntc_rg309_e:
			IF ($ < 32768) && (ntc_rg310_e - ntc_rg310 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg310:
p_hot_held_rs:			dw 0
ntc_rg310_e:
			IF ($ < 32768) && (ntc_rg311_e - ntc_rg311 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg311:
p_memory_bankpage_rs:			dw 0
ntc_rg311_e:
			IF ($ < 32768) && (ntc_rg312_e - ntc_rg312 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg312:
var_memory_bankpage_bank:			dw 0
ntc_rg312_e:
			IF ($ < 32768) && (ntc_rg313_e - ntc_rg313 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg313:
var_memory_bankpage_n:			dw 0
ntc_rg313_e:
			IF ($ < 32768) && (ntc_rg314_e - ntc_rg314 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg314:
tmp0:			dw 0
ntc_rg314_e:
			IF ($ < 32768) && (ntc_rg315_e - ntc_rg315 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg315:
tmp1:			dw 0
ntc_rg315_e:
			IF ($ < 32768) && (ntc_rg316_e - ntc_rg316 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg316:
tmp2:			dw 0
ntc_rg316_e:
			IF ($ < 32768) && (ntc_rg317_e - ntc_rg317 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg317:
tmp3:			dw 0
ntc_rg317_e:
			IF ($ < 32768) && (ntc_rg318_e - ntc_rg318 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg318:
tmp4:			dw 0
ntc_rg318_e:
			IF ($ < 32768) && (ntc_rg319_e - ntc_rg319 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg319:
tmp5:			dw 0
ntc_rg319_e:
			IF ($ < 32768) && (ntc_rg320_e - ntc_rg320 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg320:
tmp6:			dw 0
ntc_rg320_e:
			IF ($ < 32768) && (ntc_rg321_e - ntc_rg321 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg321:
			db 255			; capacity
stmp0:			ds 256
ntc_rg321_e:
			IF ($ < 32768) && (ntc_rg322_e - ntc_rg322 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg322:
			db 255			; capacity
stmp1:			ds 256
ntc_rg322_e:
			IF ($ < 32768) && (ntc_rg323_e - ntc_rg323 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg323:
			db 255			; capacity
stmp2:			ds 256
ntc_rg323_e:
			IF ($ < 32768) && (ntc_rg324_e - ntc_rg324 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg324:
			db 255			; capacity
stmp3:			ds 256
ntc_rg324_e:
			IF ($ < 32768) && (ntc_rg325_e - ntc_rg325 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg325:
ltmp0:			dw 0, 0
ntc_rg325_e:
			IF ($ < 32768) && (ntc_rg326_e - ntc_rg326 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg326:
ltmp1:			dw 0, 0

; numbers passed by address (read only)
ntc_rg326_e:
			IF ($ < 32768) && (ntc_rg327_e - ntc_rg327 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg327:
lit_0:			dw 0
ntc_rg327_e:
			IF ($ < 32768) && (ntc_rg328_e - ntc_rg328 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg328:
lit_1:			dw 1
ntc_rg328_e:
			IF ($ < 32768) && (ntc_rg329_e - ntc_rg329 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg329:
lit_85:			dw 85
ntc_rg329_e:
			IF ($ < 32768) && (ntc_rg330_e - ntc_rg330 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg330:
vp_arr_rb:			dw arr_rb
ntc_rg330_e:
			IF ($ < 32768) && (ntc_rg331_e - ntc_rg331 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg331:
lit_99:			dw 99
ntc_rg331_e:
			IF ($ < 32768) && (ntc_rg332_e - ntc_rg332 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg332:
lit_82:			dw 82
ntc_rg332_e:
			IF ($ < 32768) && (ntc_rg333_e - ntc_rg333 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg333:
lit_255:			dw 255
ntc_rg333_e:
			IF ($ < 32768) && (ntc_rg334_e - ntc_rg334 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg334:
lit_m3:			dw -3
ntc_rg334_e:
			IF ($ < 32768) && (ntc_rg335_e - ntc_rg335 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg335:
lit_2:			dw 2
ntc_rg335_e:
			IF ($ < 32768) && (ntc_rg336_e - ntc_rg336 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg336:
lit_m2431:			dw -2431
ntc_rg336_e:
			IF ($ < 32768) && (ntc_rg337_e - ntc_rg337 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg337:
lit_m2423:			dw -2423
ntc_rg337_e:
			IF ($ < 32768) && (ntc_rg338_e - ntc_rg338 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg338:
vp_var_en:			dw var_en
ntc_rg338_e:
			IF ($ < 32768) && (ntc_rg339_e - ntc_rg339 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg339:
vp_var_dn:			dw var_dn
ntc_rg339_e:
			IF ($ < 32768) && (ntc_rg340_e - ntc_rg340 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg340:
lit_100:			dw 100
ntc_rg340_e:
			IF ($ < 32768) && (ntc_rg341_e - ntc_rg341 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg341:
lit_101:			dw 101
ntc_rg341_e:
			IF ($ < 32768) && (ntc_rg342_e - ntc_rg342 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg342:
lit_102:			dw 102
ntc_rg342_e:
			IF ($ < 32768) && (ntc_rg343_e - ntc_rg343 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg343:
vp_var_puts_s:			dw var_puts_s
ntc_rg343_e:
			IF ($ < 32768) && (ntc_rg344_e - ntc_rg344 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg344:
vp_var_putc_c:			dw var_putc_c
ntc_rg344_e:
			IF ($ < 32768) && (ntc_rg345_e - ntc_rg345 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg345:
llit_65536:			dw 0, 1
ntc_rg345_e:
			IF ($ < 32768) && (ntc_rg346_e - ntc_rg346 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg346:
lit_m2425:			dw -2425
ntc_rg346_e:
			IF ($ < 32768) && (ntc_rg347_e - ntc_rg347 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg347:
lit_m2424:			dw -2424
ntc_rg347_e:
			IF ($ < 32768) && (ntc_rg348_e - ntc_rg348 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg348:
lit_4:			dw 4
ntc_rg348_e:
			IF ($ < 32768) && (ntc_rg349_e - ntc_rg349 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg349:
lit_m2422:			dw -2422
ntc_rg349_e:
			IF ($ < 32768) && (ntc_rg350_e - ntc_rg350 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg350:
lit_15:			dw 15
ntc_rg350_e:
			IF ($ < 32768) && (ntc_rg351_e - ntc_rg351 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg351:
lit_13:			dw 13
ntc_rg351_e:
			IF ($ < 32768) && (ntc_rg352_e - ntc_rg352 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg352:
vp_var_topadd_s:			dw var_topadd_s
ntc_rg352_e:
			IF ($ < 32768) && (ntc_rg353_e - ntc_rg353 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg353:
lit_9:			dw 9
ntc_rg353_e:
			IF ($ < 32768) && (ntc_rg354_e - ntc_rg354 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg354:
lit_3:			dw 3
ntc_rg354_e:
			IF ($ < 32768) && (ntc_rg355_e - ntc_rg355 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg355:
lit_m4352:			dw -4352
ntc_rg355_e:
			IF ($ < 32768) && (ntc_rg356_e - ntc_rg356 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg356:
lit_4096:			dw 4096
ntc_rg356_e:
			IF ($ < 32768) && (ntc_rg357_e - ntc_rg357 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg357:
lit_m3328:			dw -3328
ntc_rg357_e:
			IF ($ < 32768) && (ntc_rg358_e - ntc_rg358 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg358:
lit_768:			dw 768
ntc_rg358_e:
			IF ($ < 32768) && (ntc_rg359_e - ntc_rg359 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg359:
lit_m2432:			dw -2432
ntc_rg359_e:
			IF ($ < 32768) && (ntc_rg360_e - ntc_rg360 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg360:
lit_m2344:			dw -2344
ntc_rg360_e:
			IF ($ < 32768) && (ntc_rg361_e - ntc_rg361 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg361:
lit_12:			dw 12
ntc_rg361_e:
			IF ($ < 32768) && (ntc_rg362_e - ntc_rg362 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg362:
lit_m2343:			dw -2343
ntc_rg362_e:
			IF ($ < 32768) && (ntc_rg363_e - ntc_rg363 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg363:
lit_m2417:			dw -2417
ntc_rg363_e:
			IF ($ < 32768) && (ntc_rg364_e - ntc_rg364 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg364:
lit_8:			dw 8
ntc_rg364_e:
			IF ($ < 32768) && (ntc_rg365_e - ntc_rg365 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg365:
lit_32:			dw 32
ntc_rg365_e:
			IF ($ < 32768) && (ntc_rg366_e - ntc_rg366 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg366:
lit_m2416:			dw -2416
ntc_rg366_e:
			IF ($ < 32768) && (ntc_rg367_e - ntc_rg367 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg367:
vp_var_ob:			dw var_ob
ntc_rg367_e:
			IF ($ < 32768) && (ntc_rg368_e - ntc_rg368 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg368:
lit_103:			dw 103
ntc_rg368_e:
			IF ($ < 32768) && (ntc_rg369_e - ntc_rg369 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg369:
lit_256:			dw 256
ntc_rg369_e:
			IF ($ < 32768) && (ntc_rg370_e - ntc_rg370 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg370:
lit_m3332:			dw -3332
ntc_rg370_e:
			IF ($ < 32768) && (ntc_rg371_e - ntc_rg371 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg371:
lit_m3330:			dw -3330
ntc_rg371_e:
			IF ($ < 32768) && (ntc_rg372_e - ntc_rg372 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg372:
lit_m2:			dw -2
ntc_rg372_e:
			IF ($ < 32768) && (ntc_rg373_e - ntc_rg373 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg373:
lit_128:			dw 128
ntc_rg373_e:
			IF ($ < 32768) && (ntc_rg374_e - ntc_rg374 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg374:
vp_var_b:			dw var_b
ntc_rg374_e:
			IF ($ < 32768) && (ntc_rg375_e - ntc_rg375 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg375:
lit_129:			dw 129
ntc_rg375_e:
			IF ($ < 32768) && (ntc_rg376_e - ntc_rg376 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg376:
vp_var_a:			dw var_a
ntc_rg376_e:
			IF ($ < 32768) && (ntc_rg377_e - ntc_rg377 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg377:
lit_m2427:			dw -2427
ntc_rg377_e:
			IF ($ < 32768) && (ntc_rg378_e - ntc_rg378 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg378:
lit_m1:			dw -1
ntc_rg378_e:
			IF ($ < 32768) && (ntc_rg379_e - ntc_rg379 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg379:
lit_23:			dw 23
ntc_rg379_e:
			IF ($ < 32768) && (ntc_rg380_e - ntc_rg380 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg380:
lit_64:			dw 64
ntc_rg380_e:
			IF ($ < 32768) && (ntc_rg381_e - ntc_rg381 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg381:
lit_65:			dw 65
ntc_rg381_e:
			IF ($ < 32768) && (ntc_rg382_e - ntc_rg382 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg382:
lit_57:			dw 57
ntc_rg382_e:
			IF ($ < 32768) && (ntc_rg383_e - ntc_rg383 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg383:
lit_56:			dw 56
ntc_rg383_e:
			IF ($ < 32768) && (ntc_rg384_e - ntc_rg384 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg384:
lit_49:			dw 49
ntc_rg384_e:
			IF ($ < 32768) && (ntc_rg385_e - ntc_rg385 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg385:
lit_48:			dw 48
ntc_rg385_e:
			IF ($ < 32768) && (ntc_rg386_e - ntc_rg386 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg386:
lit_41:			dw 41
ntc_rg386_e:
			IF ($ < 32768) && (ntc_rg387_e - ntc_rg387 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg387:
lit_40:			dw 40
ntc_rg387_e:
			IF ($ < 32768) && (ntc_rg388_e - ntc_rg388 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg388:
lit_33:			dw 33
ntc_rg388_e:
			IF ($ < 32768) && (ntc_rg389_e - ntc_rg389 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg389:
lit_66:			dw 66

ntc_rg389_e:
			IF ($ < 32768) && (ntc_rg390_e - ntc_rg390 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg390:
; ============================================================
; Strings
; ============================================================

ntc_rg390_e:
			IF ($ < 32768) && (ntc_rg391_e - ntc_rg391 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg391:
str0:			db "CyborgOS needs 320K (a 256K expansion) or more", 0
ntc_rg391_e:
			IF ($ < 32768) && (ntc_rg392_e - ntc_rg392 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg392:
str1:			db "Press a key", 0
ntc_rg392_e:
			IF ($ < 32768) && (ntc_rg393_e - ntc_rg393 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg393:
str2:			db 0
ntc_rg393_e:
			IF ($ < 32768) && (ntc_rg394_e - ntc_rg394 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg394:
str3:			db " KEYREP ", 0
ntc_rg394_e:
			IF ($ < 32768) && (ntc_rg395_e - ntc_rg395 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg395:
str4:			db "CyborgOS ended, ", 0
ntc_rg395_e:
			IF ($ < 32768) && (ntc_rg396_e - ntc_rg396 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg396:
str5:			db " programs ran", 0
ntc_rg396_e:
			IF ($ < 32768) && (ntc_rg397_e - ntc_rg397 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg397:
str6:			db 13, 0
ntc_rg397_e:
			IF ($ < 32768) && (ntc_rg398_e - ntc_rg398 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg398:
str7:			db 10, 0
ntc_rg398_e:
			IF ($ < 32768) && (ntc_rg399_e - ntc_rg399 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg399:
str8:			db 27, 0
ntc_rg399_e:
			IF ($ < 32768) && (ntc_rg400_e - ntc_rg400 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg400:
str9:			db "E", 0
ntc_rg400_e:
			IF ($ < 32768) && (ntc_rg401_e - ntc_rg401 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg401:
str10:			db "[", 0
ntc_rg401_e:
			IF ($ < 32768) && (ntc_rg402_e - ntc_rg402 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg402:
str11:			db "]   ", 0
ntc_rg402_e:
			IF ($ < 32768) && (ntc_rg403_e - ntc_rg403 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg403:
str12:			db "CyborgOS TOP", 0
ntc_rg403_e:
			IF ($ < 32768) && (ntc_rg404_e - ntc_rg404 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg404:
str13:			db "Control + ESC: back, ", 0
ntc_rg404_e:
			IF ($ < 32768) && (ntc_rg405_e - ntc_rg405 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg405:
str14:			db ": that slot", 0
ntc_rg405_e:
			IF ($ < 32768) && (ntc_rg406_e - ntc_rg406 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg406:
str15:			db "SLOT  STATE          PROGRAM         TURNS/S   BDOS/S  CHARS/S   (last second)", 0
ntc_rg406_e:
			IF ($ < 32768) && (ntc_rg407_e - ntc_rg407 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg407:
str16:			db "-", 0
ntc_rg407_e:
			IF ($ < 32768) && (ntc_rg408_e - ntc_rg408 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg408:
str17:			db "command line", 0
ntc_rg408_e:
			IF ($ < 32768) && (ntc_rg409_e - ntc_rg409 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg409:
str18:			db "waiting (key)", 0
ntc_rg409_e:
			IF ($ < 32768) && (ntc_rg410_e - ntc_rg410 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg410:
str19:			db "running", 0
ntc_rg410_e:
			IF ($ < 32768) && (ntc_rg411_e - ntc_rg411 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg411:
str20:			db " ", 0
ntc_rg411_e:
			IF ($ < 32768) && (ntc_rg412_e - ntc_rg412 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg412:
str21:			db "*", 0
ntc_rg412_e:
			IF ($ < 32768) && (ntc_rg413_e - ntc_rg413 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg413:
str22:			db "  ", 0
ntc_rg413_e:
			IF ($ < 32768) && (ntc_rg414_e - ntc_rg414 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg414:
str23:			db "Total memory: ", 0
ntc_rg414_e:
			IF ($ < 32768) && (ntc_rg415_e - ntc_rg415 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg415:
str24:			db " KB   Free memory: ", 0
ntc_rg415_e:
			IF ($ < 32768) && (ntc_rg416_e - ntc_rg416 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg416:
str25:			db " KB", 0
ntc_rg416_e:
			IF ($ < 32768) && (ntc_rg417_e - ntc_rg417 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg417:
str26:			db "CyborgOS slot ", 0
ntc_rg417_e:
			IF ($ < 32768) && (ntc_rg418_e - ntc_rg418 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg418:
str27:			db " of ", 0
ntc_rg418_e:
			IF ($ < 32768) && (ntc_rg419_e - ntc_rg419 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg419:
str28:			db " - ", 0
ntc_rg419_e:
			IF ($ < 32768) && (ntc_rg420_e - ntc_rg420 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg420:
str29:			db ", Control + ESC TOP, HELP", 0
ntc_rg420_e:
			IF ($ < 32768) && (ntc_rg421_e - ntc_rg421 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg421:
str30:			db "Control + 1-", 0
ntc_rg421_e:
			IF ($ < 32768) && (ntc_rg422_e - ntc_rg422 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg422:
str31:			db "Control + 1-9, 0", 0
ntc_rg422_e:
			IF ($ < 32768) && (ntc_rg423_e - ntc_rg423 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg423:
str32:			db "Control + 1-9, 0 (twice 11-", 0
ntc_rg423_e:
			IF ($ < 32768) && (ntc_rg424_e - ntc_rg424 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg424:
str33:			db ")", 0
ntc_rg424_e:
			IF ($ < 32768) && (ntc_rg425_e - ntc_rg425 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg425:
str34:			db "> ", 0
ntc_rg425_e:
			IF ($ < 32768) && (ntc_rg426_e - ntc_rg426 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg426:
str35:			db ":", 0
ntc_rg426_e:
			IF ($ < 32768) && (ntc_rg427_e - ntc_rg427 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg427:
str36:			db "CV", 0
ntc_rg427_e:
			IF ($ < 32768) && (ntc_rg428_e - ntc_rg428 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg428:
str37:			db "CLS", 0
ntc_rg428_e:
			IF ($ < 32768) && (ntc_rg429_e - ntc_rg429 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg429:
str38:			db "RUN", 0
ntc_rg429_e:
			IF ($ < 32768) && (ntc_rg430_e - ntc_rg430 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg430:
str39:			db "no slot", 0
ntc_rg430_e:
			IF ($ < 32768) && (ntc_rg431_e - ntc_rg431 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg431:
str40:			db "slot", 0
ntc_rg431_e:
			IF ($ < 32768) && (ntc_rg432_e - ntc_rg432 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg432:
str41:			db " is busy", 0
ntc_rg432_e:
			IF ($ < 32768) && (ntc_rg433_e - ntc_rg433 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg433:
str42:			db "QUIT", 0
ntc_rg433_e:
			IF ($ < 32768) && (ntc_rg434_e - ntc_rg434 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg434:
str43:			db "RUN what?", 0
ntc_rg434_e:
			IF ($ < 32768) && (ntc_rg435_e - ntc_rg435 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg435:
str44:			db ".", 0
ntc_rg435_e:
			IF ($ < 32768) && (ntc_rg436_e - ntc_rg436 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg436:
str45:			db ".CYB", 0
ntc_rg436_e:
			IF ($ < 32768) && (ntc_rg437_e - ntc_rg437 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg437:
str46:			db ".COM", 0
ntc_rg437_e:
			IF ($ < 32768) && (ntc_rg438_e - ntc_rg438 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg438:
str47:			db "RUN ", 0
ntc_rg438_e:
			IF ($ < 32768) && (ntc_rg439_e - ntc_rg439 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg439:
str48:			db " runs in slot", 0
ntc_rg439_e:
			IF ($ < 32768) && (ntc_rg440_e - ntc_rg440 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg440:
str49:			db "? ", 0
ntc_rg440_e:
			IF ($ < 32768) && (ntc_rg441_e - ntc_rg441 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg441:
str50:			db " (HELP)", 0
ntc_rg441_e:
			IF ($ < 32768) && (ntc_rg442_e - ntc_rg442 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg442:
str51:			db ": not found", 0
ntc_rg442_e:
			IF ($ < 32768) && (ntc_rg443_e - ntc_rg443 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg443:
str52:			db " ended]", 0

ntc_rg443_e:
			IF ($ < 32768) && (ntc_rg444_e - ntc_rg444 + $ > 16384)	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= 32768, "the window data (; @window) must fit in the window"
			ds 32768 - $		; Option Reserve #4000-#7FFF: round it
			ENDIF
ntc_rg444:
; ============================================================
; Keyword library (rom)
; ============================================================

; Library: ROM - the keyword library is in the ROM NTC CPCFW (NTCFW.ROM).
; Its routines: this jump block, the numbers made into addresses by the ROM at the start.
; Its variables and constants: fixed addresses (RAM #8800 - #A5EF is the ROM's).
ntc_rj_block:
kw_stop:		jp 1
ntc_xn:		jp 2
kw_goto_iffalse_n:	jp 11
kw_goto_iftrue_n:	jp 13
kw_goto_ifzero_n:	jp 15
kw_forupv_n:	jp 25
kw_next1v_n:	jp 33
kw_ltov:		jp 47
kw_vtov:		jp 48
kw_ztov:		jp 49
kw_ftov:		jp 50
kw_inc:		jp 51
kw_add:		jp 53
kw_addl:		jp 54
kw_subvv:	jp 55
kw_4x:		jp 58
kw_mulvl:	jp 61
kw_divvv:	jp 63
kw_divvl:	jp 64
kw_andvv:	jp 72
kw_andvl:	jp 73
kw_orvv:		jp 74
kw_orvl:		jp 75
kw_notv:		jp 78
kw_scpltvl:	jp 80
kw_scplevv:	jp 81
kw_scplevl:	jp 82
kw_scpgtvv:	jp 83
kw_scpgtvl:	jp 84
kw_scpgevl:	jp 86
kw_cpeqvv:	jp 95
kw_cpeqvl:	jp 96
kw_cpnevv:	jp 97
kw_cpnevl:	jp 98
kw_lptrtov8:	jp 99
kw_vptrtov8:	jp 100
kw_aget:		jp 111
kw_aset:		jp 112
kw_asetl:	jp 117
kw_strcpy:	jp 122
kw_strcat:	jp 124
kw_strlen:	jp 125
kw_strcmpeq:	jp 126
kw_strcmpne:	jp 127
kw_printstrvar:	jp 129
kw_printint:	jp 131
kw_printnl0:	jp 134
kw_printnl:	jp 138
kw_inkey:	jp 144
kw_model:	jp 150
kw_frame:	jp 152
kw_ticks:	jp 154
kw_strleft:	jp 156
kw_strright:	jp 157
kw_strmid:	jp 173
kw_strchr:	jp 174
kw_strstr:	jp 176
kw_strspace:	jp 178
kw_strucase:	jp 180
kw_strtrim:	jp 184
kw_strval:	jp 186
kw_strinstr:	jp 187
kw_l_mov:	jp 206
kw_l_itol:	jp 207
kw_l_add:	jp 209
mem_go0:		jp 243
mem_go:		jp 245
mem_readbyte:	jp 254
mem_writebyte:	jp 256
mem_writeword:	jp 257
mem_freepages:	jp 260
mem_ramsize:	jp 261
mem_allocpage:	jp 266
mem_selpage:	jp 268
mem_copy:	jp 273
ntc_isl_tick:	jp 287
kw_bssinit:	jp 288
ntc_plat_irqon:	jp 314
mem_bankcount:	jp 329
mem_allocbank:	jp 330
ntc_kdown:	jp 334
kw_waitkey:	jp 348
NTC_RJ_N	equ 82		; entries
mem_a1	equ #884F		; ROM data
mem_a2	equ #8851		; ROM data
mem_a3	equ #8853		; ROM data
mem_res	equ #8855		; ROM data
ntc_csp	equ #8800		; ROM data
ntc_irqv	equ #8917		; ROM data
ntc_isl	equ #9786		; ROM bss
ntc_isldue	equ #8908		; ROM data
ntc_isln	equ #8907		; ROM data
ntc_nmode	equ #8807		; ROM data
ntc_rampt	equ #881F		; ROM data
ntc_v_free	equ #894E		; ROM data
ntc_v_romen	equ #8954		; ROM data
ntc_v_romold	equ #8956		; ROM data
ntc_v_stamp	equ #8952		; ROM data
ntc_v_start	equ #8950		; ROM data
			ASSERT ntc_free <= #8800, "Library: ROM - the program and its arrays must end below #8800 (the ROM's RAM)"

; End: the caller's ROM selection again, then back to the caller
ntc_rj_exit:
			ld bc, (ntc_rj_old)
			call #B918		; KL ROM DESELECT
			ret
ntc_rj_old:		dw 0			; the caller's ROM selection (C) and state (B)


; the start code (Library: ROM): run once, then the arrays go over it
ntc_rj_drop:
; the start: find the ROM set in slots 0 - 31 (its main ROM, then the others with the same
; stamp), have the main one patch the jump block. NC = ready; C = not there / too old
; (the message is shown, the caller's ROM selection is back)
ntc_rj_find:
			ld c, 0
			call #B90F		; KL ROM SELECT: B / C = the caller's state and selection
			ld (ntc_rj_old), bc
			xor a
			ld (ntc_rj_want), a
			call ntc_rj_scan		; the main ROM
			jp c, ntc_rj_nf
			ld (ntc_rj_slots), a
			ld e, (hl)
			inc hl
			ld d, (hl)			; its patcher
			ld (ntc_rj_call + 1), de
			ld a, 1
ntc_rj_more:				; the other ROMs of the set
			ld (ntc_rj_want), a
			ld hl, ntc_rj_n
			cp (hl)
			jr nc, ntc_rj_all
			call ntc_rj_scan
			jp c, ntc_rj_part
			ld b, a
			ld a, (ntc_rj_want)
			ld e, a
			ld d, 0
			ld hl, ntc_rj_slots
			add hl, de
			ld (hl), b
			inc a
			jr ntc_rj_more
ntc_rj_all:
			ld a, (ntc_rj_slots)
			ld c, a
			call #B90F		; KL ROM SELECT: the main ROM
			di					; (KL ROM SELECT lets interrupts in)
			ld a, (ntc_rj_slots)	; its slot
			ld hl, ntc_rj_block
			ld bc, NTC_RJ_N
			ld de, ntc_rj_slots
ntc_rj_call:
			call 0				; HL = jump block, BC = entries, A = slot, DE = slots; C: DE = a number it hasn't got
			jp c, ntc_rj_lacks
			IF (ntc_bss >= 32768) && (ntc_bssfrom <= 16384)	; fwdref-ok
			ld hl, ntc_bssfrom		; (the end of the program - or this start code, which tables may go over)
			ELSE
			ld hl, ntc_free
			ENDIF
			ld (ntc_v_free), hl
			ld hl, ntc_start
			ld (ntc_v_start), hl
			ld hl, 0
			ld (ntc_v_stamp), hl
			ld a, 1
			ld (ntc_v_romen), a
			ld a, (ntc_rj_old)
			ld (ntc_v_romold), a
			or a				; NC: ready
			ret
; ntc_rj_scan - a ROM of the set: ROM ntc_rj_want (0 = the main one, any stamp; the others
; with the main one's stamp). NC: A = its slot, HL = past its block's count byte (the main
; one: at its patcher), it is selected. C: not there
ntc_rj_scan:
			ld c, 0
ntc_rj_next:
			push bc
			call #B90F		; KL ROM SELECT: ROM C
			pop bc
			ld a, (#C000)
			cp 1				; a background ROM?
			jr nz, ntc_rj_skip
			ld hl, (#C004)		; its names
			ld a, h
			cp #C0
			jr c, ntc_rj_skip
ntc_rj_name:
			ld a, (hl)
			inc hl
			or a
			jr nz, ntc_rj_name		; to the 0 after the names
			ld de, ntc_rj_sig
			ld b, ntc_rj_sige - ntc_rj_sig
ntc_rj_cmp:
			ld a, (de)
			cp (hl)
			jr nz, ntc_rj_skip
			inc de
			inc hl
			djnz ntc_rj_cmp
			ld e, (hl)
			inc hl
			ld d, (hl)			; DE = its set's stamp
			inc hl
			ld a, (ntc_rj_want)
			cp (hl)				; its place in the set
			jr nz, ntc_rj_skip
			or a
			jr z, ntc_rj_got
			push hl
			ld hl, (ntc_rj_set)
			or a
			sbc hl, de
			pop hl
			jr nz, ntc_rj_skip		; another build's
ntc_rj_got:
			ld (ntc_rj_set), de
			inc hl
			ld a, (hl)
			ld (ntc_rj_n), a		; ROMs in the set
			inc hl
			ld a, c
			or a				; NC
			ret
ntc_rj_skip:
			inc c
			ld a, c
			cp 32
			jr c, ntc_rj_next
			scf					; C: not there
			ret
ntc_rj_nf:
			ld hl, ntc_rj_tnf
			jr ntc_rj_fail
ntc_rj_part:				; a ROM of the set is missing: its number (1 = the main one)
			ld a, (ntc_rj_want)
			inc a
			ld e, a
			ld d, 0
			ld (ntc_rj_num), de
			ld hl, ntc_rj_tpt
			jr ntc_rj_fnum
ntc_rj_lacks:
			ld (ntc_rj_num), de
			ld hl, ntc_rj_tlk
ntc_rj_fnum:
			ld a, 1
			ld (ntc_rj_pn), a		; the number after the message
ntc_rj_fail:
			push hl
			ld bc, (ntc_rj_old)
			call #B918		; KL ROM DESELECT: the caller's selection again
			pop hl
			call ntc_rj_puts
			ld a, (ntc_rj_pn)
			or a
			jr z, ntc_rj_nl
			ld a, (ntc_rj_num + 1)
			call ntc_rj_hex
			ld a, (ntc_rj_num)
			call ntc_rj_hex
ntc_rj_nl:
			ld hl, ntc_rj_tnl
			call ntc_rj_puts
			ei
			call #BB06		; KM WAIT CHAR: a key first (a RUN" program's return resets the machine)
			di
			scf
			ret
ntc_rj_puts:				; HL = text, 0 ends; DE = its start
			ld d, h
			ld e, l
ntc_rj_pl:
			ld a, (hl)
			or a
			ret z
			call #BB5A		; TXT OUTPUT
			inc hl
			jr ntc_rj_pl
ntc_rj_hex:
			push af
			rrca
			rrca
			rrca
			rrca
			call ntc_rj_dig
			pop af
ntc_rj_dig:
			and 15
			add a, #90
			daa
			adc a, #40
			daa
			jp #BB5A
ntc_rj_num:		dw 0
ntc_rj_pn:		db 0			; 1 = a number goes after the message
ntc_rj_want:	db 0			; the ROM of the set looked for
ntc_rj_n:		db 1			; ROMs in the set
ntc_rj_set:		dw 0			; the set's stamp
ntc_rj_slots:	ds 8			; each ROM's slot, the main one first
ntc_rj_sig:		db "NTC", 2, "CPCFW", 0	; the ROMs' NTC block
ntc_rj_sige:
ntc_rj_tnf:		db "ROM NTC CPCFW (NTCFW.ROM) not found", 0
ntc_rj_tlk:		db "ROM NTC CPCFW too old: no routine #", 0
ntc_rj_tpt:		db "ROM NTCFW<n>.ROM not found: n = #", 0
ntc_rj_tnl:		db 13, 10, "Press a key", 13, 10, 0
ntc_rj_dropend:
ntc_rg444_e:
ntc_end:				; the end of the program (and of its file)
			IF $ < #4000	; fwdref-ok
			ds #4000 - $		; the window data (; @window), from #4000
			ntc_windata
			ASSERT $ <= #8000, "the window data (; @window) must fit in the window"
			ENDIF
ntc_fileend:			; the file ends here (the window data in it)
; arrays: after the program, not in its file - kw_bssinit checks they fit and clears them
			IF ntc_rj_dropend == ntc_end	; fwdref-ok
ntc_bssfrom	equ ntc_rj_drop		; the arrays over the start code (it has run)
			ELSE
ntc_bssfrom	equ ntc_end
			ENDIF
			IF (ntc_bssfrom < 32768) && (ntc_bssfrom + ntc_bss_size > 16384)	; fwdref-ok
ntc_bss		equ 32768		; after Option Reserve #4000-#7FFF
			ELSE
ntc_bss		equ ntc_bssfrom
			ENDIF
arr_bk		equ ntc_bss + 0		; 10 bytes
arr_sg		equ ntc_bss + 10		; 10 bytes
arr_st		equ ntc_bss + 20		; 10 bytes
arr_kq		equ ntc_bss + 30		; 10 bytes
arr_wp		equ ntc_bss + 40		; 10 bytes
arr_dm		equ ntc_bss + 50		; 10 bytes
arr_ra		equ ntc_bss + 60		; 10 bytes
arr_wk		equ ntc_bss + 70		; 10 bytes
arr_tn		equ ntc_bss + 80		; 10 bytes
arr_nb		equ ntc_bss + 90		; 10 bytes
arr_nc		equ ntc_bss + 100		; 10 bytes
arr_lt		equ ntc_bss + 110		; 10 bytes
arr_lb		equ ntc_bss + 120		; 10 bytes
arr_lc		equ ntc_bss + 130		; 10 bytes
arr_rb		equ ntc_bss + 140		; 128 bytes
arr_ent_en		equ ntc_bss + 268		; 12 bytes
ntc_bss_size	equ 280
ntc_free	equ ntc_bss + ntc_bss_size	; the first free byte (heap, Memory tables)
			IF ntc_free <= 32768	; fwdref-ok
ntc_memtab	equ 32768		; the Memory class's tables: above the window (Option Reserve)
			ELSE
ntc_memtab	equ ntc_free
			ENDIF
; Option Reserve: the program and its arrays (ntc_start .. ntc_free) must stay out of these
			ASSERT (ntc_free <= 16384) || (ntc_bss >= 32768), "the program (or its arrays) reaches into Option Reserve #4000-#7FFF (Main.bas line 25)"
			SAVEAMSDOS "CYBORGOS.BIN", ntc_start, ntc_fileend - ntc_start, ntc_start
