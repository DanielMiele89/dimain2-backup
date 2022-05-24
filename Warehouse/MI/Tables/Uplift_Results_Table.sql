CREATE TABLE [MI].[Uplift_Results_Table] (
    [ID]                  INT           IDENTITY (1, 1) NOT NULL,
    [Programid]           INT           NOT NULL,
    [PartnerGroupID]      INT           NULL,
    [PartnerID]           INT           NULL,
    [ClientServiceRef]    NVARCHAR (40) NULL,
    [PaymentTypeID]       INT           NOT NULL,
    [ChannelID]           INT           NOT NULL,
    [CustomerAttributeID] INT           NOT NULL,
    [Mid_SplitID]         INT           NOT NULL,
    [CumulativeTypeID]    INT           NOT NULL,
    [PeriodTypeID]        INT           NOT NULL,
    [DateID]              INT           NOT NULL,
    [UpliftSales]         FLOAT (53)    NULL,
    [UpliftTransactions]  FLOAT (53)    NULL,
    [UpliftSpenders]      FLOAT (53)    NULL
);

