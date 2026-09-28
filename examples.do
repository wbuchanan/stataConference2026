*! examples.do
*! The three example dashboards embedded in the 2026 Stata Conference deck,
*! "dash: A Drop-In Replacement for twoway".
*!
*!   1. nlsw88   -- filters of every type, KPI cards, linked brushing across
*!                  three scatters, and a Bootstrap grid with tabs
*!   2. sp500    -- a date axis, a secondary y axis, a range plot, and the
*!                  Download CSV button
*!   3. lifeexp  -- marker labels, a log scale, colour by group, a fit with its
*!                  confidence band, all drawn under a bundled StataCorp scheme
*!   4. census   -- three tabs, four linked scatters brushed as one, by()
*!                  facets on a shared scale, lowess and qfitci, under the
*!                  economist scheme
*!
*! Every command below is twoway syntax with `twoway' replaced by `dash', plus
*! the handful of options dash adds: name(), and on dash build the layout,
*! filter, tab, link and export options.  Where a line uses an option twoway
*! would refuse, a comment says so.
*!
*! Usage:  do examples.do
*!         (run from the repository root; writes into dashboards/)
*!
*! Produces: dashboards/nlsw88-filters.html
*!           dashboards/sp500-timeseries.html
*!           dashboards/lifeexp-encoding.html
*!           dashboards/census-tabs.html
*!
*! Requires: dash and jsonio on the ado-path, and Stata's Python with numpy,
*!           pandas and bokeh.  dash's own setup names Python 3.8 and
*!           bokeh 3.0 as the floor; the code needs bokeh >= 3.6, which needs
*!           Python >= 3.10.  Built and verified with StataNow 19.5 MP,
*!           Python 3.13.9 and Bokeh 3.8.0, at dash commit 91d97be.
*!
*! Version: 1.1.0  25sep2026

clear all
set more off

// ----------------------------------------------------------------
// Where dash lives
// ----------------------------------------------------------------
// These point at the development trees on the machine the deck was built
// on.  With dash and jsonio net-installed they are unnecessary; `capture'
// lets the file run either way.
capture adopath ++ "/Users/billy/Desktop/Programs/Java/StataJSON"
capture adopath ++ "/Users/billy/Desktop/Programs/StataPrograms/d/dash"

capture mkdir dashboards


// ================================================================
// 1. nlsw88 -- filters, KPI cards, linked brushing, tabs
// ================================================================
sysuse nlsw88, clear
dash clear

// Tooltips, marker labels and KPI cards are written in each variable's
// display format, and this dataset ships every numeric variable in %8.0g or
// %9.0g.  A %g format has no fixed number of decimals, so dash has nothing to
// pass to the browser and its own formatter takes over -- 7.766949 becomes
// 7.767 and a float 0.1 becomes 0.10000000149011612.  Give every variable a
// dashboard reads a format with a fixed number of decimals.
format wage                                       %9.2f
format ttl_exp tenure                             %9.1f
format age grade hours                            %9.0f
format industry occupation union collgrad race    %9.0f

// -- Relationships ------------------------------------------------------
// Three scatters of the hourly wage.  They are linked at build time, so
// box- or lasso-selecting a group of women in one highlights the same women
// in the other two.  lfit is the OLS line through whatever the filters
// leave; lfitci draws the same line with its 95% confidence band.
dash (scatter wage ttl_exp, msize(small))             ///
     (lfit    wage ttl_exp),                          ///
    name(g1) title("Hourly wage by total work experience") ///
    xtitle("Total work experience (years)")           ///
    ytitle("Hourly wage (USD)")

dash (scatter wage tenure, msize(small))              ///
     (lfit    wage tenure),                           ///
    name(g2) title("Hourly wage by tenure in current job") ///
    xtitle("Job tenure (years)")                      ///
    ytitle("Hourly wage (USD)")

// grade takes whole numbers, so the points stack in columns; jitter() spreads
// them, and jitterseed() makes the picture the same every time it is drawn.
dash (scatter wage grade, msize(small) jitter(3) jitterseed(1988)) ///
     (lfitci  wage grade),                            ///
    name(g3) title("Hourly wage by years of schooling")   ///
    xtitle("Highest grade completed")                 ///
    ytitle("Hourly wage (USD)")

// -- Distributions ------------------------------------------------------
// A histogram and a kernel density of the same variable on one figure.  The
// histogram is on the density scale so the two share a y axis.
dash (histogram wage, bin(40) density)                ///
     (kdensity  wage),                                ///
    name(g4) title("Distribution of hourly wages")        ///
    xtitle("Hourly wage (USD)") ytitle("Density")

// Two densities, each from its own subset.  A plot's own `if' is honoured
// inside the parentheses exactly as in twoway, so one figure compares two
// groups without reshaping the data.  368 women have no union status and
// belong to neither.
dash (kdensity wage if union == 1)                    ///
     (kdensity wage if union == 0),                   ///
    name(g5) title("Wage density: union and nonunion workers") ///
    xtitle("Hourly wage (USD)") ytitle("Density")     ///
    legend(label(1 "Union") label(2 "Nonunion"))

// -- KPI cards ----------------------------------------------------------
// dash kpi has no twoway counterpart.  update() says what a card follows:
//   filter -- the filter widgets (the default);
//   brush  -- a box- or lasso-selection on any linked graph;
//   both   -- either.
// The "Selected" card is the one to watch while brushing: it starts at the
// full sample and becomes the count of whatever is selected.
dash kpi count(wage),   name(k1) title("Women")             fmt(%9.0fc) ///
    subtitle("in the current filters")   update(both)
dash kpi mean(wage),    name(k2) title("Mean hourly wage")  fmt(%9.2f)  ///
    subtitle("USD, 1988")                update(both)
dash kpi median(wage),  name(k3) title("Median hourly wage") fmt(%9.2f) ///
    subtitle("USD, 1988")                update(filter)
dash kpi p90(wage),     name(k4) title("90th percentile")   fmt(%9.2f)  ///
    subtitle("of the hourly wage")       update(filter)
dash kpi iqr(wage),     name(k5) title("Interquartile range") fmt(%9.2f) ///
    subtitle("of the hourly wage, USD") update(filter)
dash kpi count(wage),   name(k6) title("Selected")          fmt(%9.0fc) ///
    subtitle("box- or lasso-selected women") update(brush)

// -- Build --------------------------------------------------------------
// layout(bs) is a Bootstrap 12-column grid that reflows as the browser
// narrows, and filterposition(left) puts the widgets in a sidebar.  Cards
// and graphs are grouped together into two tabs: each tab lays its items
// out in its own grid, so the cards that answer a brush -- Women, Mean
// hourly wage, Selected -- sit directly above the three linked scatters
// they follow, and the distributional cards above the two densities.  The
// three filters are one of each type: a dropdown over a value-labelled
// categorical, a two-ended range, and a one-sided slider.  exclude(g4)
// keeps the overall wage distribution at the full sample on every filter,
// so a filtered group's density in the figure beside it can be read
// against the whole.  link() names the three scatters explicitly.
dash build,                                                          ///
    saving("dashboards/nlsw88-filters.html") replace nobrowser        ///
    title("Young women in the labour force, 1988")                   ///
    subtitle("NLSW 1988 extract, 2,246 women aged 34 to 46")         ///
    layout(bs)                                                       ///
    tabs(Overview: k1 k2 k6 g1 g2 g3 / Distributions: k3 k4 k5 g4 g5) ///
    filterposition(left)                                             ///
    filter(industry, type(dropdown) label("Industry")  exclude(g4))  ///
    filter(age,      type(range)    label("Age")       exclude(g4))  ///
    filter(hours,    type(slider)   label("Weekly hours, at least") exclude(g4)) ///
    link(g1 g2 g3)

display as text "examples.do: wrote dashboards/nlsw88-filters.html"


// ================================================================
// 2. sp500 -- a date axis, a secondary axis, a range plot, CSV export
// ================================================================
sysuse sp500, clear
dash clear

// date is already %td.  dash carries the display format into the browser,
// so the x axis, the tooltips, the range filter and the two date-valued KPI
// cards all read as calendar dates.  The prices ship in %9.0g and volume in
// %12.0gc; as above, give them a fixed number of decimals.
format close open high low change   %9.2f
format volume                       %12.0fc

// The prices are stored as floats, and the Download CSV button writes each
// number exactly as the browser holds it: the float nearest 1236.72, widened
// to a double, is 1236.719970703125, and that is what the file would say.
// Prices are quoted to the cent, so hold them as doubles rounded to the cent
// and the download reads as the data does.
recast double close open high low change
foreach v of varlist close open high low change {
    quietly replace `v' = round(`v' * 100) / 100
}

// -- The year in one figure -----------------------------------------------
// Each day's low-to-high range as a band, with the close drawn over it.  A
// range plot takes three variables, y1 y2 x, as in twoway.  hover() is
// dash's own: it adds variables to a layer's tooltip, and twoway refuses it.
//   A caution, measured 25sep2026 at dash commit 91d97be: a variable that
//   only hover() names is left out of the data the page carries, without a
//   note, and never reaches the tooltip.  volume appears here because the
//   next graph and a KPI card also use it.  Until that is fixed, hover()
//   only a variable some graph, card or filter on the page already uses.
dash (rarea low high date, fcolor(gs13) lcolor(gs13))     ///
     (line  close date),                                  ///
    name(g1) title("Daily range and close")                   ///
    ytitle("Index level")                                 ///
    legend(label(1 "Low to high") label(2 "Close"))       ///
    hover(volume)

// -- Two scales on one x axis ---------------------------------------------
// yaxis(2) puts a layer on a right-hand y axis scaled to its own data.
// ytitle2() titles that axis; twoway writes ytitle(..., axis(2)) instead.
dash (area volume date, yaxis(2) fcolor(ltblue%60) lcolor(ltblue)) ///
     (line close date),                                   ///
    name(g2) title("Close and trading volume")                ///
    ytitle("Index level") ytitle2("Volume (thousands)")

// -- Day-to-day movement --------------------------------------------------
dash spike change date,                                   ///
    name(g3) title("Daily change in the close")               ///
    ytitle("Change (index points)") yline(0)

// -- KPI cards ------------------------------------------------------------
// min() and max() of a date variable are dates, and stay dates as the range
// filter moves: the first and last trading day in the current selection.
dash kpi min(date),    name(k1) title("First trading day") ///
    subtitle("in the current range")
dash kpi max(date),    name(k2) title("Last trading day")  ///
    subtitle("in the current range")
dash kpi max(close),   name(k3) title("Highest close")  fmt(%9.2f)   ///
    subtitle("index level")
dash kpi mean(volume), name(k4) title("Mean daily volume") fmt(%12.0fc) ///
    subtitle("thousands of shares")

// -- Build ----------------------------------------------------------------
// csv adds a Download CSV button beside the filters.  It writes
// dashboard.csv: every observation the filters currently leave, with every
// variable the dashboard uses.  Only the filters count -- a brushed
// selection and a graph's own `if' do not narrow it.  It is opt-in because
// it hands any viewer of the page every row of every variable it uses.
dash build,                                                          ///
    saving("dashboards/sp500-timeseries.html") replace nobrowser      ///
    title("S&P 500 in 2001")                                         ///
    subtitle("248 trading days; narrow the dates, then download what remains") ///
    layout(bs: k1=3 k2=3 k3=3 k4=3 / g1=12 / g2=7 g3=5)               ///
    filter(date,   type(range)  label("Trading days"))               ///
    filter(volume, type(slider) label("Daily volume, at least"))     ///
    csv

display as text "examples.do: wrote dashboards/sp500-timeseries.html"


// ================================================================
// 3. lifeexp -- labels, a log scale, colour by group, a fit with its band,
//               under a StataCorp scheme
// ================================================================
sysuse lifeexp, clear
dash clear

format lexp        %9.0f
format gnppc       %12.0fc
format popgrowth   %9.2f

// GNP per capita runs from 370 to 39,980 dollars, so its axis is logged on
// the first figure.  The fit on the second is linear in log income -- the
// Preston curve -- so it is drawn against the logged variable, with its
// 95% band.  Five countries have no GNP figure and are absent from both.
generate double lngnppc = ln(gnppc)
label variable lngnppc "log GNP per capita"
format lngnppc %9.2f

// Labelling all 68 points would overprint the crowded middle of the cloud,
// in dash as in twoway.  The usual idiom: a label variable that is empty
// except where a label is wanted -- here the six shortest-lived countries
// and the six richest, the edges of the cloud.  hover() names the rest: it
// adds variables to every point's tooltip, and twoway refuses it.  (country
// reaches the tooltip because the Countries card counts it; see the note on
// hover() in the sp500 example above.)
egen byte rank_lexp  = rank(lexp),   unique
egen byte rank_gnppc = rank(-gnppc), unique
generate str28 label_country = country if rank_lexp <= 6 | rank_gnppc <= 6
label variable label_country "Country"

// colorvar() with colordiscrete colours each country by its region and draws
// a key, as in Stata 18.  mlabel() puts the country's name beside its point.
dash (scatter lexp gnppc, colorvar(region) colordiscrete         ///
                          mlabel(label_country) mlabsize(small) mlabposition(3)), ///
    name(g1) title("Life expectancy and income, 1998")          ///
    xscale(log)                                                  ///
    xtitle("GNP per capita (USD, log scale)")                    ///
    ytitle("Life expectancy at birth (years)")                   ///
    hover(country)

dash (scatter lexp lngnppc, colorvar(region) colordiscrete)      ///
     (lfitci  lexp lngnppc),                                     ///
    name(g2) title("Linear in log income, with its 95% band")   ///
    xtitle("log GNP per capita")                                 ///
    ytitle("Life expectancy at birth (years)")                   ///
    hover(country)

// -- KPI cards ------------------------------------------------------------
// count() of a string variable counts its non-empty values.
dash kpi count(country),  name(k1) title("Countries")            fmt(%9.0f) ///
    subtitle("in the current filters")   update(both)
dash kpi mean(lexp),      name(k2) title("Mean life expectancy") fmt(%9.1f) ///
    subtitle("years at birth")           update(both)
dash kpi median(gnppc),   name(k3) title("Median GNP per capita") fmt(%12.0fc) ///
    subtitle("USD")                      update(both)
dash kpi mean(popgrowth), name(k4) title("Mean population growth") fmt(%9.2f) ///
    subtitle("percent per year")         update(both)

// -- Build ----------------------------------------------------------------
// scheme() draws the dashboard in one of the twenty StataCorp schemes dash
// ships.  stcolor is the scheme Stata 18 and later draw by default, so this
// page looks like the graphs the audience makes today; s2color, the older
// default, is the other one every Stata user recognises.  The two figures
// are linked: select a cluster of countries on either and the same countries
// light up on the other.
dash build,                                                          ///
    saving("dashboards/lifeexp-encoding.html") replace nobrowser      ///
    title("Life expectancy and national income, 1998")               ///
    subtitle("68 countries, drawn under Stata's stcolor scheme")     ///
    scheme(stcolor)                                                  ///
    layout(bs: k1=3 k2=3 k3=3 k4=3 / g1=7 g2=5)                       ///
    filter(region, type(dropdown) label("Region"))                   ///
    filter(lexp,   type(range)    label("Life expectancy"))          ///
    link(g1 g2)

display as text "examples.do: wrote dashboards/lifeexp-encoding.html"


// ================================================================
// 4. census -- three tabs, four linked scatters, by() facets on one scale,
//              lowess and qfitci, under the economist scheme
// ================================================================
sysuse census, clear
dash clear

format region  %9.0f
format medage  %9.2f
format pop     %12.0fc

// The counts ship in %12.0gc; the dashboard reads rates instead, so the
// states can be compared.  Deaths, marriages and divorces per 1,000
// residents, and three shares of the population, in percent.
generate double drate  = death    / pop * 1000
generate double mrate  = marriage / pop * 1000
generate double dvrate = divorce  / pop * 1000
generate double urban  = popurban / pop * 100
generate double old    = pop65p   / pop * 100
generate double young  = (poplt5 + pop5_17) / pop * 100
label variable drate  "Deaths per 1,000 residents"
label variable mrate  "Marriages per 1,000 residents"
label variable dvrate "Divorces per 1,000 residents"
label variable urban  "Urban share of the population (%)"
label variable old    "Share aged 65 and older (%)"
label variable young  "Share under 18 (%)"
format drate mrate dvrate urban old young %9.1f

// -- Rates: four scatters, brushed as one --------------------------------
// The four are linked at build time.  A box- or lasso-selection on any of
// them highlights the same states on the other three.  hover(state) names
// the state under the cursor; state reaches the tooltip because the States
// card counts it (see the note on hover() in the sp500 example).  Nevada
// married 142 couples per 1,000 residents in 1980, ten times any other
// state, so the marriage axis is logged to keep the other 49 readable.
// A tab draws four graphs as two rows; xsize() and ysize() set a figure's
// proportions, as in twoway, and 10 by 4 keeps both rows on one screen.
dash (scatter dvrate mrate, msize(medium)),                          ///
    name(g1) title("Divorces and marriages")                          ///
    xscale(log) xsize(10) ysize(4)                                   ///
    xtitle("Marriages per 1,000 residents (log scale)")              ///
    ytitle("Divorces per 1,000 residents")                           ///
    hover(state)

dash (scatter drate old, msize(medium)),                             ///
    name(g2) title("Deaths and the share aged 65 and older")          ///
    xsize(10) ysize(4)                                               ///
    xtitle("Share aged 65 and older (%)")                            ///
    ytitle("Deaths per 1,000 residents")                             ///
    hover(state)

dash (scatter young medage, msize(medium)),                          ///
    name(g3) title("Share under 18 and median age")                   ///
    xsize(10) ysize(4)                                               ///
    xtitle("Median age (years)")                                     ///
    ytitle("Share under 18 (%)")                                     ///
    hover(state)

// Population spans two orders of magnitude, so its axis is logged.  The
// two-letter code labels every state; the tooltip gives the full name.
dash (scatter urban pop, msize(medium)                               ///
                         mlabel(state2) mlabsize(small) mlabposition(3)), ///
    name(g4) title("Urban share and population")                      ///
    xscale(log) xsize(10) ysize(4)                                   ///
    xtitle("Population (log scale)")                                 ///
    ytitle("Urban share of the population (%)")                      ///
    hover(state)

// -- By region: one figure, four panels ------------------------------------
// by() draws a panel per census region.  The panels share one scale only
// when the axes are ticked with #N, as here; without it each panel takes
// its own range (dash 91d97be).  lfit is fitted within each panel.  The
// figure is in the link group too: a selection on any panel, or on any of
// the four scatters above, lights up the same states everywhere.  A graph
// in a link group draws from the group's one shared source, so it follows
// every filter the group follows -- exclude() cannot hold it back
// (measured 25sep2026 at 91d97be) -- and a region filter leaves three of
// its four panels empty, as it should.
dash (scatter drate medage, msize(medium))                           ///
     (lfit    drate medage),                                         ///
    name(g5) title("Deaths and median age, by census region")         ///
    by(region, cols(2)) xlabel(#5) ylabel(#5) xsize(10) ysize(4)      ///
    xtitle("Median age (years)")                                     ///
    ytitle("Deaths per 1,000 residents")                             ///
    hover(state)

// -- Age structure: two smoothers twoway users know -----------------------
dash (scatter medage old, msize(medium))                             ///
     (lowess  medage old),                                           ///
    name(g6) title("Median age and the share aged 65 and older")      ///
    xtitle("Share aged 65 and older (%)")                            ///
    ytitle("Median age (years)")                                     ///
    hover(state)

dash (scatter medage young, msize(medium))                           ///
     (qfitci  medage young),                                         ///
    name(g7) title("Median age and the share under 18")               ///
    xtitle("Share under 18 (%)")                                     ///
    ytitle("Median age (years)")                                     ///
    hover(state)

// -- KPI cards ------------------------------------------------------------
dash kpi count(state), name(k1) title("States")            fmt(%9.0f) ///
    subtitle("in the current filters")   update(both)
dash kpi mean(medage), name(k2) title("Mean median age")   fmt(%9.1f) ///
    subtitle("years")                    update(both)

// -- Build ----------------------------------------------------------------
// Three tabs.  A tab lays its items out in its own grid of equal cells --
// ceil(sqrt(n)) columns, so four graphs make a 2 x 2 -- and the spans of
// layout(bs: ...) do not reach inside it.  economist is one of the twenty
// StataCorp schemes dash ships.
dash build,                                                          ///
    saving("dashboards/census-tabs.html") replace nobrowser           ///
    title("The 50 states in 1980")                                   ///
    subtitle("Census extract, drawn under Stata's economist scheme") ///
    scheme(economist)                                                ///
    layout(bs)                                                       ///
    tabs(Rates: g1 g2 g3 g4 / By region: g5 / Age structure: k1 k2 g6 g7) ///
    filter(region, type(dropdown) label("Census region"))            ///
    filter(medage, type(range)    label("Median age"))               ///
    link(g1 g2 g3 g4 g5)

display as text "examples.do: wrote dashboards/census-tabs.html"
