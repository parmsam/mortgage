#' R6 Class Representing a Loan
#'
#' @description
#' A loan used to create and calculate various mortgage statistics.
#' @import R6
#' @import dplyr
#' @import tibble
#' @export
Loan <- R6::R6Class(
  "Loan",
  public = list(
    #' @field principal Principal amount of the loan
    principal = NULL,
    #' @field interest Interest rate of the loan
    interest = NULL,
    #' @field term Term of the loan
    term = NULL,
    #' @field term_unit Unit of the term
    term_unit = NULL,
    #' @field compounded Compounding method
    compounded = NULL,
    #' @field currency Currency symbol
    currency = NULL,
    #' @field n_periods Number of periods
    n_periods = NULL,
    #' @field schedule Amortization schedule
    schedule = NULL,

    # Initialize loan object
    #' @description
    #' Create a new `Loan` object.
    #' @param principal Principal amount of the loan
    #' @param interest Interest rate of the loan
    #' @param term Term of the loan
    #' @param term_unit Unit of the term
    #' @param compounded Compounding method
    #' @param currency Currency symbol
    initialize = function(
      principal, interest, term,
      term_unit = "years", compounded = "monthly", currency = "$"
      ) {
      term_units <- c("days", "months", "years")
      compounding_methods <- c("daily", "monthly", "annually")
      stopifnot(
        "`term_unit` must be 'days', 'years' or 'months'" =
          term_unit %in% term_units,
        '`compounded` must be "daily", "monthly" or "annually"' =
          compounded %in% compounding_methods
      )
      stopifnot(
        "`principal` must be positive value" =
          principal > 0,
        "`interest` must be between zero and one" =
          0 <= interest && interest <= 1,
        "`term` must be a positive number" =
          term > 0,
        "`term_unit` must be 'days', 'years' or 'months'" =
          term_unit %in% c("days", "years", "months"),
        '`compounded` must be "daily", "monthly" or "annually"' =
          compounded %in% c("daily", "monthly", "annually")
      )
      periods <- list(
        daily = 365,
        monthly = 12,
        annually = 1
      )
      self$principal <- as.double(principal)
      self$interest <- as.double(interest * 100) / 100
      self$term <- term
      self$term_unit <- term_unit
      self$compounded <- compounded
      self$currency <- currency
      self$n_periods <- periods[[compounded]]
      self$schedule <- self$amortize()
    },

    #' @description
    #' Return the principal amount of the loan
    total_principal = function() {
      self$principal
    },
    #' @description
    #' Return the total interest paid on the loan
    total_interest = function() {
        sum(self$schedule$interest)
    },
    #' @description
    #' Return the total amount paid on the loan
    total_paid = function() {
      self$total_principal() + self$total_interest()
    },
    #' @description
    #' Return the percentage of the total payment that is interest
    interest_to_principal = function() {
      round(self$total_interest() / self$total_principal() * 100, 1)
    },
    #' @description
    #' Return the number of years to pay off the loan
    years_to_pay = function() {
      round(self$term, 1)
    },

    #' @description
    #' Return the annual percentage rate (APR) of the loan
    apr = function() {
      simple_interest <- self$principal * self$interest * 1
      round((simple_interest / self$principal) * 100, 2)
    },

    #' @description
    #' Return the annual percentage yield (APY) of the loan
    apy = function() {
      rate <- self$interest / self$n_periods
      effective_rate <- (1 + rate)^self$n_periods - 1
      round(effective_rate * 100, 2)
    },

    #' @description
    #' Return the monthly payment of the loan
    monthly_payment = function() {
      principal <- self$principal
      int_rate <- self$interest
      n <- self$n_periods
      term <- self$term
      payment <- principal * (int_rate / n) / (1 - (1 + int_rate / n)^(-n * term))
      round(payment, 2)
    },

    #' @description
    #' Return the amortization schedule of the loan
    amortize = function() {
      schedule <- tibble::tibble()
      total_interest <- 0
      balance <- self$principal

      for (i in 1:(self$term * self$n_periods)) {
        monthly_payment <- self$monthly_payment()
        interest_payment <- balance * (self$interest / self$n_periods)
        principal_payment <- monthly_payment - interest_payment
        total_interest <- total_interest + interest_payment
        balance <- balance - principal_payment

        schedule <- dplyr::bind_rows(schedule, list(
          number = i,
          payment = round(monthly_payment, 2),
          interest = round(interest_payment, 2),
          principal = round(principal_payment, 2),
          total_interest = round(total_interest, 2),
          balance = round(balance, 2)
        ))
      }

      schedule
    },

    #' @description
    #' Return the interest and principal payment for a split payment
    #' @param payment_number The number of the payment
    #' @param amount The amount of the payment
    split_payment = function(payment_number, amount) {
      balance <- self$schedule[payment_number, "balance"]
      interest_payment <- balance * (self$interest / self$n_periods)
      principal_payment <- amount - interest_payment
      list(interest = round(interest_payment, 2), principal = round(principal_payment, 2))
    },

    #' @description
    #' Print a summary of the loan
    summarize = function() {
      cat(sprintf("Original Balance:         %s%.2f\n", self$currency, self$principal))
      cat(sprintf("Interest Rate:            %.2f%%\n", self$interest * 100))
      cat(sprintf("APY:                      %.2f%%\n", self$apy()))
      cat(sprintf("APR:                      %.2f%%\n", self$apr()))
      cat(sprintf("Term:                     %.1f %s\n", self$term, self$term_unit))
      cat(sprintf("Monthly Payment:          %s%.2f\n", self$currency, self$monthly_payment()))
      cat("\n")
      cat(sprintf("Total principal payments: %s%.2f\n", self$currency, self$total_principal()))
      cat(sprintf("Total interest payments:  %s%.2f\n", self$currency, self$total_interest()))
      cat(sprintf("Total payments:           %s%.2f\n", self$currency, self$total_paid()))
      cat(sprintf("Interest to Principal:    %.1f%%\n", self$interest_to_principal()))
      cat(sprintf("Years to pay:             %.1f\n", self$years_to_pay()))
    },

    #' @description
    #' Print the loan object
    print = function() {
      cat(sprintf("<Loan principal=%.2f, interest=%.2f, term=%.1f>", self$principal, self$interest, self$term))
      invisible(self)
    }

  )
)

