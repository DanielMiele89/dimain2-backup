CREATE TABLE [Relational].[PartnerTransPreLaunchQRMay2012] (
    [Trans_CombinedID]     INT          NOT NULL,
    [SourceTable]          CHAR (1)     NULL,
    [FileID]               INT          NULL,
    [ArchiveRowNumber]     INT          NULL,
    [MatchID]              INT          NULL,
    [FanID]                INT          NULL,
    [CompositeID]          BIGINT       NULL,
    [SourceUID]            VARCHAR (20) NULL,
    [PaymentCardID]        BIGINT       NULL,
    [MerchantID]           VARCHAR (15) NULL,
    [LocationName]         VARCHAR (22) NULL,
    [LocationAddress]      VARCHAR (18) NULL,
    [LocationCountry]      VARCHAR (3)  NULL,
    [MerchantCategoryCode] VARCHAR (4)  NULL,
    [TransactionDate]      DATE         NULL,
    [TransactionAmount]    MONEY        NULL,
    [RetailOutletID]       INT          NULL,
    [PartnerID]            INT          NULL,
    [BrandID]              INT          NULL
);

