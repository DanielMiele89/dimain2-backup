CREATE TABLE [MI].[ChargeOnRedeem_MonthCustomer] (
    [ID]                           INT      IDENTITY (1, 1) NOT NULL,
    [YearNumber]                   SMALLINT NOT NULL,
    [MonthNumber]                  SMALLINT NOT NULL,
    [EligibleCustomerCount]        INT      NOT NULL,
    [EligiblePendingCustomerCount] INT      NOT NULL,
    CONSTRAINT [PK_MI_ChargeOnRedeem_MonthCustomer] PRIMARY KEY CLUSTERED ([ID] ASC)
);

