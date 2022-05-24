CREATE TABLE [InsightArchive].[RetailAdjustmentFactor] (
    [ProgramID]           INT              NULL,
    [PartnerGroupID]      INT              NULL,
    [PartnerID]           INT              NULL,
    [ClientServicesRef]   VARCHAR (40)     NULL,
    [PaymentTypeID]       INT              NULL,
    [ChannelID]           INT              NOT NULL,
    [CustomerAttributeID] INT              NOT NULL,
    [Mid_SplitID]         INT              NULL,
    [CumulativeTypeID]    INT              NULL,
    [PeriodTypeID]        INT              NULL,
    [DateID]              INT              NOT NULL,
    [AdjFactorSPC]        DECIMAL (18, 16) NULL,
    [AdjFactorRR]         DECIMAL (18, 16) NULL,
    [AdjFactorTPC]        DECIMAL (18, 16) NULL
);

