CREATE TABLE [MI].[RBSPortal_Exception_SpendEarnRedeemList] (
    [LineType]       TINYINT       NULL,
    [CIN]            VARCHAR (20)  NULL,
    [PartnerName]    VARCHAR (100) NULL,
    [AddMonth]       INT           NULL,
    [AddYear]        INT           NULL,
    [Spend]          MONEY         NULL,
    [Earnings]       MONEY         NULL,
    [Redemptions]    MONEY         NULL,
    [ItemCount]      INT           NULL,
    [ExceptionCount] INT           NULL,
    [ExceptionType]  TINYINT       NOT NULL
);

