CREATE TABLE [PatrickM].[grocery_mids_250821_v2] (
    [MID] VARCHAR (50) NOT NULL
);


GO
CREATE CLUSTERED INDEX [CIX_MID]
    ON [PatrickM].[grocery_mids_250821_v2]([MID] ASC);

