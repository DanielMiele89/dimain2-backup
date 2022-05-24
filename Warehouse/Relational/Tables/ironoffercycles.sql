CREATE TABLE [Relational].[ironoffercycles] (
    [ironoffercyclesid]       INT IDENTITY (1, 1) NOT NULL,
    [ironofferid]             INT NOT NULL,
    [offercyclesid]           INT NOT NULL,
    [controlgroupid]          INT NOT NULL,
    [OfferReportingPeriodsID] INT NULL,
    PRIMARY KEY CLUSTERED ([ironoffercyclesid] ASC) WITH (FILLFACTOR = 80)
);


GO
CREATE NONCLUSTERED INDEX [nix_ironoffercycles_ControlGroupID]
    ON [Relational].[ironoffercycles]([controlgroupid] ASC) WITH (FILLFACTOR = 80);

