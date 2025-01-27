#' R6 Class Representing a Loan Comparison
#'
#' @description
#' A class used to compare multiple loan objects.
#' @import R6
#' @import dplyr
#' @import tibble
#' @export
LoanComparison <- R6::R6Class(
  "LoanComparison",
  public = list(
    #' @field loans List of loan objects
    loans = NULL,

    #' @description
    #' Create a new `LoanComparison` object.
    #' @param loans List of loan objects
    initialize = function(loans) {
      stopifnot("All elements must be Loan objects" = all(sapply(loans, inherits, "Loan")))
      self$loans <- loans
    },

    #' @description
    #' Compare the total interest of the loans
    compare_total_interest = function() {
      tibble::tibble(
        Loan = seq_along(self$loans),
        TotalInterest = sapply(self$loans, function(loan) loan$total_interest())
      )
    },

    #' @description
    #' Compare the monthly payments of the loans
    compare_monthly_payments = function() {
      tibble::tibble(
        Loan = seq_along(self$loans),
        MonthlyPayment = sapply(self$loans, function(loan) loan$monthly_payment())
      )
    },

    #' @description
    #' Compare the total payments of the loans
    compare_total_payments = function() {
      tibble::tibble(
        Loan = seq_along(self$loans),
        TotalPayments = sapply(self$loans, function(loan) loan$total_paid())
      )
    },

    #' @description
    #' Compare difference of total payments between two or more loans in matrix
    compare_total_payments_diff = function() {
      n_loans <- length(self$loans)
      total_payments <- sapply(self$loans, function(loan) loan$total_paid())
      diff_matrix <- matrix(NA, nrow = n_loans, ncol = n_loans)
      for (i in 1:n_loans) {
        for (j in 1:n_loans) {
          diff_matrix[i, j] <- total_payments[i] - total_payments[j]
        }
      }
      rownames(diff_matrix) <- colnames(diff_matrix) <- seq_along(self$loans)
      diff_matrix
    },

    #' @description
    #' Print a summary of the loan comparison
    summarize = function() {
      cat("Loan Comparison Summary:\n")
      cat("Total Interest:\n")
      print(self$compare_total_interest())
      cat("\nMonthly Payments:\n")
      print(self$compare_monthly_payments())
      cat("\nTotal Payments:\n")
      print(self$compare_total_payments())
      cat("\nTotal Payments Difference Matrix:\n")
      print(self$compare_total_payments_diff())
    },

    #' @description
    #' Print the loan object
    print = function() {
      cat("Loan Comparison Object\n")
      cat("Loans:\n")
      for (i in seq_along(self$loans)) {
        cat("Loan ", i, ":\n")
        print(self$loans[[i]])
      }
    }
  )
)
