CREATE TABLE [Prototype].[CampaignPlanning_Scaling] (
    [PartnerNameID] INT            NOT NULL,
    [AdjRR2]        FLOAT (53)     NULL,
    [AdjSPC2]       NUMERIC (2, 1) NOT NULL,
    [AdjTPC2]       NUMERIC (2, 1) NOT NULL,
    [AdjRR3]        FLOAT (53)     NULL,
    [AdjSPC3]       NUMERIC (2, 1) NOT NULL,
    [AdjTPC3]       NUMERIC (2, 1) NOT NULL,
    [AdjRR4]        FLOAT (53)     NULL,
    [AdjSPC4]       NUMERIC (2, 1) NOT NULL,
    [AdjTPC4]       NUMERIC (2, 1) NOT NULL
);


GO
CREATE CLUSTERED INDEX [IND]
    ON [Prototype].[CampaignPlanning_Scaling]([PartnerNameID] ASC);

