#' R6 Class Representing a Loan
#'
#' @description
#' A loan used to create and calculate various mortgage statistics.
#' @import R6
#' @import dplyr
#' @import tibble
#' @import ggplot2
#' @import scales
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
    #' @field downpayment Downpayment amount
    downpayment = NULL,

    # Initialize loan object
    #' @description
    #' Create a new `Loan` object.
    #' @param principal Principal amount of the loan
    #' @param interest Interest rate of the loan
    #' @param term Term of the loan
    #' @param term_unit Unit of the term
    #' @param compounded Compounding method
    #' @param currency Currency symbol
    #' @param downpayment Downpayment amount
    initialize = function(
      principal,
      interest,
      term,
      term_unit = "years",
      compounded = "monthly",
      currency = "$",
      downpayment = 0
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
          compounded %in% c("daily", "monthly", "annually"),
        "`downpayment` must be a positive value" =
          downpayment >= 0
      )
      periods <- list(
        daily = 365,
        monthly = 12,
        annually = 1
      )
      self$principal <- as.double(principal - downpayment)
      self$interest <- as.double(interest * 100) / 100
      self$term <- term
      self$term_unit <- term_unit
      self$compounded <- compounded
      self$currency <- currency
      self$downpayment <- downpayment
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
    #' Return the percentage of the total principal that is interest
    interest_to_principal = function() {
      round(self$total_interest() / self$total_principal() * 100, 1)
    },
    #' @description
    #' Return the percentage of the total amount that is interest
    interest_to_paid = function() {
      round(self$total_interest() / self$total_paid() * 100, 1)
    },
    #' @description
    #' Return the number of years to pay off the loan
    years_to_pay = function() {
      round(self$term, 1)
    },

    #' @description
    #' Return the annual percentage rate (APR) of the loan
    apr = function() {
      simple_interest <- function(term) {
        self$principal * self$interest * term
      }
      round((simple_interest(term=1) / self$principal) * 100, 2)
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
      total_principal <- 0
      balance <- self$principal

      for (i in 1:(self$term * self$n_periods)) {
        monthly_payment <- self$monthly_payment()
        interest_payment <- balance * (self$interest / self$n_periods)
        principal_payment <- monthly_payment - interest_payment
        total_interest <- total_interest + interest_payment
        total_principal <- total_principal + principal_payment
        balance <- balance - principal_payment

        schedule <- dplyr::bind_rows(schedule, list(
          number = i,
          payment = round(monthly_payment, 2),
          interest = round(interest_payment, 2),
          principal = round(principal_payment, 2),
          total_interest = round(total_interest, 2),
          total_principal = round(total_principal, 2),
          balance = round(balance, 2)
        ))
      }

      schedule
    },

    #' @description
    #' Return the tipping point of the loan which is the payment number when you begin paying off more principal than interest in a payment
    tipping_point = function(){
      self$schedule %>%
        dplyr::filter(interest < principal) %>%
        dplyr::slice(1) %>%
        dplyr::pull(number)
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
      cat(sprintf("Home price:               %s%11.2f\n", self$currency, self$principal + self$downpayment))
      cat(sprintf("Downpayment:              %s%11.2f\n", self$currency, self$downpayment))
      cat(sprintf("Original Balance:         %s%11.2f\n", self$currency, self$principal))
      cat(sprintf("Interest Rate:             %11.2f%%\n", self$interest * 100))
      cat(sprintf("APY:                       %11.2f%%\n", self$apy()))
      cat(sprintf("APR:                       %11.2f%%\n", self$apr()))
      cat(sprintf("Term:                      %11.1f %s\n", self$term, self$term_unit))
      cat(sprintf("Monthly Payment:          %s%11.2f\n", self$currency, self$monthly_payment()))
      cat("\n")
      cat(sprintf("Total principal payments: %s%11.2f\n", self$currency, self$total_principal()))
      cat(sprintf("Total interest payments:  %s%11.2f\n", self$currency, self$total_interest()))
      cat(sprintf("Total payments:           %s%11.2f\n", self$currency, self$total_paid()))
      cat(sprintf("Interest to Principal:     %11.2f%%\n", self$interest_to_principal()))
      cat(sprintf("Years to pay:              %11.1f\n", self$years_to_pay()))
    },

    #' @description
    #' Print the loan object
    print = function() {
      cat(sprintf("<Loan principal=%.2f, interest=%.2f, term=%.1f>", self$principal, self$interest, self$term))
      invisible(self)
    },

    #' @description
    #' Plot the amortization schedule of the loan
    plot = function() {
      ggplot2::ggplot(self$schedule) +
        ggplot2::geom_line(ggplot2::aes(x = number, y = balance, color = "Loan Balance")) +
        ggplot2::geom_line(ggplot2::aes(x = number, y = total_principal, color = "Principal Paid")) +
        ggplot2::geom_line(ggplot2::aes(x = number, y = total_interest, color = "Interest Paid")) +
        ggplot2::scale_color_manual(values = c("Loan Balance" = "#0041a7",
                                               "Principal Paid" = "#4898ff",
                                               "Interest Paid" = "#88dd9b")) +
        ggplot2::scale_y_continuous(labels = scales::dollar_format()) +  # Apply dollar formatting
        ggplot2::labs(title = "Amortization Schedule", x = "Payment Number", y = "Balance ($)", color = "Legend") +
        ggplot2::theme_minimal() +
        ggplot2::theme(legend.position = "bottom")
    }

  )
)

