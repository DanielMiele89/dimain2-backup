CREATE TABLE [Relational].[Partner_CampaignKPIs] (
    [PartnerID]            INT        NOT NULL,
    [Year]                 INT        NOT NULL,
    [Strategic_WOWs]       INT        NULL,
    [Tactical_WOWs]        INT        NULL,
    [Avg_Offer_Rate]       FLOAT (53) NULL,
    [Overall_Blended_Rate] FLOAT (53) NULL,
    PRIMARY KEY CLUSTERED ([PartnerID] ASC, [Year] ASC)
);

