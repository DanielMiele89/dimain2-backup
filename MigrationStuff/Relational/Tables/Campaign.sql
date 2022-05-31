CREATE TABLE [Relational].[Campaign] (
    [ID]             INT          IDENTITY (1, 1) NOT NULL,
    [CampaignRef]    VARCHAR (15) NULL,
    [CampaignTypeID] TINYINT      NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

