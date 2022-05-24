CREATE TABLE [Staging].[DirectDebit_EligibleAccounts] (
    [ID]                SMALLINT     IDENTITY (1, 1) NOT NULL,
    [AccountType]       VARCHAR (3)  NOT NULL,
    [LoyaltyFeeAccount] BIT          NOT NULL,
    [V_Customer_Only]   BIT          NOT NULL,
    [ClubID]            INT          NOT NULL,
    [AccountName]       VARCHAR (75) NOT NULL,
    [StartDate]         DATE         NOT NULL,
    [EndDate]           DATE         NULL,
    [Ranking]           SMALLINT     NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

