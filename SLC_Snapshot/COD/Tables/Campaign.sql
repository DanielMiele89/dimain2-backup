CREATE TABLE [COD].[Campaign] (
    [ID]             INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [RetailerID]     INT            NOT NULL,
    [CampaignName]   NVARCHAR (128) NOT NULL,
    [CampaignCode]   NVARCHAR (50)  NOT NULL,
    [CampaignStatus] INT            NOT NULL,
    CONSTRAINT [PK__Campaign__3214EC27FDA4C4BC] PRIMARY KEY CLUSTERED ([ID] ASC)
);

