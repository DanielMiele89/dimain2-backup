CREATE TABLE [MI].[ControlSalesWorking] (
    [ID]                  INT              IDENTITY (1, 1) NOT NULL,
    [Programid]           INT              NOT NULL,
    [PartnerGroupID]      INT              NULL,
    [PartnerID]           INT              NULL,
    [ClientServiceRef]    NVARCHAR (40)    NULL,
    [PaymentTypeID]       INT              NOT NULL,
    [ChannelID]           INT              NOT NULL,
    [CustomerAttributeID] INT              NOT NULL,
    [Mid_SplitID]         INT              NOT NULL,
    [CumulativeTypeID]    INT              NOT NULL,
    [PeriodTypeID]        INT              NOT NULL,
    [DateID]              INT              NOT NULL,
    [Controlsales]        MONEY            NOT NULL,
    [ControlTransactions] INT              NOT NULL,
    [ControlSpenders]     INT              NOT NULL,
    [ControlCardHolders]  INT              NOT NULL,
    [AdjFactorSPC]        DECIMAL (18, 16) NULL,
    [AdjFactorTPC]        DECIMAL (18, 16) NULL,
    [AdjFactorRR]         DECIMAL (18, 16) NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

