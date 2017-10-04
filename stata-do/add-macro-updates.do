
local countries US Germany UK Canada Australia Japan Italy France

local iter=1
foreach c in `countries'{
di "`c'..."
qui{
	preserve
	import excel "$wid_dir/Country-Updates/`c'/2017/August/`c'_WID.world.xlsx", clear

	// Clean
	dropmiss, force
	renvars, map(strtoname(@[3]))
	drop if _n<4
	destring _all, replace
	rename WID_code year
	dropmiss, force
	dropmiss, obs force

	// Reshape
	ds year, not
	renvars `r(varlist)', pref(value)
	reshape long value, i(year) j(widcode) string
	drop if mi(value)
	gen iso="`c'"
	tempfile `c'
	save "``c''"
	restore
if `iter'==1{
	use "``c''", clear
}
else{
	append using "``c''"
}
local iter=`iter'+1
}
}

// Currencies and countries
replace iso="GB" if iso=="UK"
replace iso="DE" if iso=="Germany"
replace iso="CA" if iso=="Canada"
replace iso="JP" if iso=="Japan"
replace iso="AU" if iso=="Australia"
replace iso="IT" if iso=="Italy"
replace iso="FR" if iso=="France"

gen currency = "GBP" if iso=="GB" & inlist(substr(widcode, 1, 1), "a", "t", "m", "i")
replace currency="EUR" if iso=="DE" & inlist(substr(widcode, 1, 1), "a", "t", "m", "i")
replace currency="CAD" if iso=="CA" & inlist(substr(widcode, 1, 1), "a", "t", "m", "i")
replace currency="USD" if iso=="US" & inlist(substr(widcode, 1, 1), "a", "t", "m", "i")
replace currency="JPY" if iso=="JP" & inlist(substr(widcode, 1, 1), "a", "t", "m", "i")
replace currency="AUD" if iso=="AU" & inlist(substr(widcode, 1, 1), "a", "t", "m", "i")
replace currency="EUR" if iso=="IT" & inlist(substr(widcode, 1, 1), "a", "t", "m", "i")
replace currency="EUR" if iso=="FR" & inlist(substr(widcode, 1, 1), "a", "t", "m", "i")
gen p="pall"

levelsof iso, local(countries)
foreach c in `countries'{
	levelsof widcode if iso=="`c'", local(`c'variables) clean
}

tempfile macroupdates
save "`macroupdates'"


// Create metadata
generate sixlet = substr(widcode, 1, 6)
keep iso sixlet
duplicates drop
generate source = `"[URL][URL_LINK][/URL_LINK]"' ///
	+ `"[URL_TEXT]Piketty, Thomas; Zucman, Gabriel (2014)."' ///
	+ `"Capital is back: Wealth-Income ratios in Rich Countries 1700-2010. Series updated by Luis Bauluz.[/URL_TEXT][/URL]; "'
generate method = ""
tempfile meta
save "`meta'"

// Add data to WID
use "$work_data/add-swedish-data-output.dta", clear
gen oldobs=1
foreach c in `countries'{
	foreach var in ``c'variables'{
		drop if widcode=="`var'" & iso=="`c'" & p=="pall" ///
			& substr(widcode,1,1)!="n" & substr(widcode,1,1)!="i"
	}
}
append using "`macroupdates'"
duplicates tag iso year p widcode, gen(dup)
qui count if dup==1 & !inlist(iso,"DE","GB","US","CA","JP","AU") & !inlist(iso,"FR","IT")
assert r(N)==0
drop if oldobs==1 & dup==1
drop oldobs dup

label data "Generated by add-macro-updates.do"
save "$work_data/add-macro-updates-output.dta", replace

// Add metadata
use "$work_data/add-swedish-data-metadata.dta", clear
merge 1:1 iso sixlet using "`meta'", nogenerate update replace

label data "Generated by add-macro-updates.do"
save "$work_data/add-macro-updates-metadata.dta", replace



