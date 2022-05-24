CREATE TABLE [MI].[INSchemeSalesWorking] (
    [ID]                   INT           IDENTITY (1, 1) NOT NULL,
    [Programid]            INT           NOT NULL,
    [PartnerGroupID]       INT           NULL,
    [PartnerID]            INT           NULL,
    [ClientServiceRef]     NVARCHAR (40) NULL,
    [PaymentTypeID]        INT           NOT NULL,
    [ChannelID]            INT           NOT NULL,
    [CustomerAttributeID]  INT           NOT NULL,
    [Mid_SplitID]          INT           NOT NULL,
    [CumulativeTypeID]     INT           NOT NULL,
    [PeriodTypeID]         INT           NOT NULL,
    [DateID]               INT           NOT NULL,
    [INSchemeSales]        MONEY         NOT NULL,
    [INSchemeTransactions] INT           NOT NULL,
    [INSchemeSpenders]     INT           NOT NULL,
    [Commission]           MONEY         NOT NULL,
    [Cardholders]          INT           NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

