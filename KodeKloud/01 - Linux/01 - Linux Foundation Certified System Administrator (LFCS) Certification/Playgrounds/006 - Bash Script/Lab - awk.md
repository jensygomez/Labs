One challenge I worked on recently involved analyzing a large, pipe-delimited database file for a financial systems project. I needed to extract salary information from thousands of employee records and calculate both the total and average salary, so I built a solution using `awk`, which is a powerful text-processing tool in Linux.

I started by writing a script that used `awk` with a custom field separator to pull out the salary column and save it into a separate file. Then I extended it to calculate summary statistics using `awk`'s built-in variables — `NR` for counting lines and `NF` for counting fields — inside an `END` block, so the calculation would run once, after all the data had been processed.

What made this task more interesting was learning how to pass custom variables into `awk` using the `-v` flag, and using those variables dynamically as column selectors with the dollar-sign syntax. I applied that concept to build a small tool that could look up a specific value in a grid-like file, based on a row and column number passed as arguments — similar to checking desk availability in an office layout.

Along the way, I ran into a few syntax issues, like typos in command names or using the wrong symbol to reference a variable, which reinforced how important precision is when writing shell scripts. Overall, this task helped me strengthen my skills in text processing, script automation, and debugging in a Linux environment — skills I know are essential for a sysadmin role.

[[Laboratorios del LFCS]]
