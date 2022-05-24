CREATE TABLE [Derived].[__MFDD_Households_Archived] (
    [ID]            INT          IDENTITY (1, 1) NOT NULL,
    [FanID]         BIGINT       NOT NULL,
    [SourceUID]     VARCHAR (20) NOT NULL,
    [BankAccountID] INT          NOT NULL,
    [HouseholdID]   INT          NOT NULL,
    [StartDate]     DATE         NOT NULL,
    [EndDate]       DATE         NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

