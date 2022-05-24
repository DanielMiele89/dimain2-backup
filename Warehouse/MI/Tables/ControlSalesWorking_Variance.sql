CREATE TABLE [MI].[ControlSalesWorking_Variance] (
    [Programid]           INT              NOT NULL,
    [PartnerGroupID]      INT              NOT NULL,
    [PartnerID]           INT              NULL,
    [ClientServiceRef]    VARCHAR (40)     NOT NULL,
    [PaymentTypeID]       INT              NOT NULL,
    [ChannelID]           INT              NOT NULL,
    [CustomerAttributeID] INT              NOT NULL,
    [Mid_SplitID]         INT              NOT NULL,
    [CumulativeTypeID]    INT              NOT NULL,
    [PeriodTypeID]        INT              NOT NULL,
    [DateID]              INT              NULL,
    [SPC_Var]             FLOAT (53)       NULL,
    [SPS_Var]             FLOAT (53)       NULL,
    [RR_Var]              NUMERIC (38, 13) NULL
);

