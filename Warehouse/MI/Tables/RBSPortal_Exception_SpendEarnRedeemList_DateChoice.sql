CREATE TABLE [MI].[RBSPortal_Exception_SpendEarnRedeemList_DateChoice] (
    [ID]             INT           IDENTITY (1, 1) NOT NULL,
    [DateChoiceID]   TINYINT       NOT NULL,
    [LineType]       TINYINT       NOT NULL,
    [CIN]            VARCHAR (20)  NOT NULL,
    [PartnerName]    VARCHAR (100) NULL,
    [AddMonth]       INT           NOT NULL,
    [AddYear]        INT           NOT NULL,
    [AddedDate]      DATE          NOT NULL,
    [Spend]          MONEY         NOT NULL,
    [Earnings]       MONEY         NOT NULL,
    [Redemptions]    MONEY         NOT NULL,
    [ItemCount]      INT           NOT NULL,
    [ExceptionCount] INT           NOT NULL,
    [ExceptionType]  TINYINT       NOT NULL,
    CONSTRAINT [PK_MI_RBSPortal_Exception_SpendEarnRedeemList_DateChoice] PRIMARY KEY CLUSTERED ([ID] ASC)
);

