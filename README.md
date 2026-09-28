# dash: A Drop-In Replacement for twoway

This talk will describe a new command intended to serve as a near drop-in replacement for `twoway` 
to create interactive dashboards in Stata and how the command was developed. This is functionality 
that several users have requested at previous Stata conferences, and it is now here using syntax 
that Stata users already know. Just replace `twoway` with `dash` and you can be on your way. The 
inclusion of the Bootstrap CSS framework provides responsive dashboards that will resize themselves 
automatically based on the device's screen size.

View the presentation at https://wbuchanan.github.io/stataConference2026/

## What is in the repository

| Path | What it is |
|---|---|
| `index.html` | The slide deck. |
| `examples.do` | The Stata code that builds the example dashboards in the presentation.|
| `dashboards/` | The dashboards created by `examples.do`. |
| `vendor/` | Reveal.js 5.2.1 dependencies |
| `.nojekyll` | Tells GitHub Pages to serve the files as they are, without running Jekyll. |

## Dependencies

`dash` does rely on `jsonio` to export the data and metadata to JSON.  You can find more information 
about `jsonio` at https://wbuchanan.github.io/StataJSON.

| Component | Version |
|---|---|
| `dash` | 0.1.0 |
| Stata | &ge; StataNow 19.5 |
| Python (Stata's `c(python_exec)`) | &ge; 3.13.9 |
| Bokeh | &ge;3.8.0 |
| numpy | &ge;2.3 |
| pandas | &ge;2.3 |
