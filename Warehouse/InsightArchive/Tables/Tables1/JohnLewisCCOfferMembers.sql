CREATE TABLE [InsightArchive].[JohnLewisCCOfferMembers] (
    [FanID] INT           NOT NULL,
    [Email] VARCHAR (100) NULL
);


GO
CREATE CLUSTERED INDEX [cix_JohnLewisCCOfferMembers_FanID]
    ON [InsightArchive].[JohnLewisCCOfferMembers]([FanID] ASC);

