CREATE TABLE [InsightArchive].[Morrisons_IronOfferID_ControlGroup] (
    [FanID]       INT          NULL,
    [IronOfferID] INT          NULL,
    [Segment]     VARCHAR (20) NULL
);


GO
CREATE CLUSTERED INDEX [cix_FanID]
    ON [InsightArchive].[Morrisons_IronOfferID_ControlGroup]([FanID] ASC);


GO
CREATE NONCLUSTERED INDEX [nix_IronOfferID_FanID]
    ON [InsightArchive].[Morrisons_IronOfferID_ControlGroup]([IronOfferID] ASC)
    INCLUDE([FanID]);

