CREATE TABLE [Selections].[PartnerDedupe_Haven_CustomerMatches_20200122] (
    [FanID]     INT           NOT NULL,
    [MatchedOn] VARCHAR (100) NULL
);


GO
CREATE NONCLUSTERED INDEX [CIX_Fan]
    ON [Selections].[PartnerDedupe_Haven_CustomerMatches_20200122]([FanID] ASC);

