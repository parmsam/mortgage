
<!-- README.md is generated from README.Rmd. Please edit that file -->

# mortgage

<!-- badges: start -->
<!-- badges: end -->

The goal of mortgage is to help understand the true cost of a mortgage.
It also can help you easily compare between different mortgages. It is
based on the [Python library of the same
name](https://mortgage.readthedocs.io/en/latest/). The package is built
using [R6](https://r6.r-lib.org/).

## Installation

You can install the development version of mortgage from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("parmsam/mortgage")
```

## Example

This is a basic example which shows you how to solve a common problem:

``` r
library(mortgage)
# Example usage
loan <- Loan$new(principal=200000, interest=.06, term=30)
loan
#> <Loan principal=200000.00, interest=0.06, term=30.0>
```

``` r
loan$summarize()
#> Original Balance:         $200000.00
#> Interest Rate:            6.00%
#> APY:                      6.17%
#> APR:                      6.00%
#> Term:                     30.0 years
#> Monthly Payment:          $1199.10
#> 
#> Total principal payments: $200000.00
#> Total interest payments:  $231677.04
#> Total payments:           $431677.04
#> Interest to Principal:    115.8%
#> Years to pay:             30.0
```

``` r
loan$amortize()
#> # A tibble: 360 × 6
#>    number payment interest principal total_interest balance
#>     <int>   <dbl>    <dbl>     <dbl>          <dbl>   <dbl>
#>  1      1   1199.    1000       199.          1000  199801.
#>  2      2   1199.     999       200.          1999  199601.
#>  3      3   1199.     998       201.          2997. 199400.
#>  4      4   1199.     997       202.          3994. 199198.
#>  5      5   1199.     996.      203.          4990  198994.
#>  6      6   1199.     995.      204.          5985. 198790.
#>  7      7   1199.     994.      205.          6979. 198585.
#>  8      8   1199.     993.      206.          7972. 198379.
#>  9      9   1199.     992.      207.          8964. 198172.
#> 10     10   1199.     991.      208.          9955. 197964.
#> # ℹ 350 more rows
```
