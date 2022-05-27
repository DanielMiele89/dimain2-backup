CREATE TABLE [Staging].[CampaignPlanning_Seasonality] (
    [PartnerID] INT           NOT NULL,
    [Date]      SMALLDATETIME NULL,
    [HolidayID] VARCHAR (3)   NULL,
    [SPCAdj]    FLOAT (53)    NULL
);

