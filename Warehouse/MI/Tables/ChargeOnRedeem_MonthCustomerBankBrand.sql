CREATE TABLE [MI].[ChargeOnRedeem_MonthCustomerBankBrand] (
    [ID]                                  INT      IDENTITY (1, 1) NOT NULL,
    [YearNumber]                          SMALLINT NOT NULL,
    [MonthNumber]                         SMALLINT NOT NULL,
    [EligibleCustomerCountNatWest]        INT      NOT NULL,
    [EligiblePendingCustomerCountNatWest] INT      NOT NULL,
    [EligibleCustomerCountRBS]            INT      NOT NULL,
    [EligiblePendingCustomerCountRBS]     INT      NOT NULL,
    CONSTRAINT [PK_MI_ChargeOnRedeem_MonthCustomerBankBrand] PRIMARY KEY CLUSTERED ([ID] ASC)
);

