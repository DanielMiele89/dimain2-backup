CREATE TABLE [Staging].[SLC_ACAMissing_OLD] (
    [ID] INT NOT NULL
);


GO
CREATE CLUSTERED INDEX [CIX]
    ON [Staging].[SLC_ACAMissing_OLD]([ID] ASC);

