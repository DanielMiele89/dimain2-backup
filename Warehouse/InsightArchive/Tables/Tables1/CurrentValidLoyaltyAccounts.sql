CREATE TABLE [InsightArchive].[CurrentValidLoyaltyAccounts] (
    [CustomerSegment]  VARCHAR (8)  NULL,
    [FanID]            INT          NOT NULL,
    [SourceUID]        VARCHAR (20) NOT NULL,
    [IssuerCustomerID] INT          NOT NULL,
    [clubid]           INT          NOT NULL,
    [CompositeID]      BIGINT       NOT NULL,
    [Type]             VARCHAR (3)  NOT NULL,
    [BankAccountID]    INT          NOT NULL,
    [AccountNumber]    VARCHAR (3)  NOT NULL,
    [AlreadyValid]     BIT          NOT NULL,
    [Nominee]          BIT          NOT NULL
);

