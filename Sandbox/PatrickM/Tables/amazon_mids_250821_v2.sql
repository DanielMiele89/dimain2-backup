CREATE TABLE [PatrickM].[amazon_mids_250821_v2] (
    [MID]               NVARCHAR (50) NOT NULL,
    [Narrative_Cleaned] NVARCHAR (50) NOT NULL,
    [column3]           NVARCHAR (1)  NULL
);


GO
CREATE CLUSTERED INDEX [CIX_MID]
    ON [PatrickM].[amazon_mids_250821_v2]([MID] ASC, [Narrative_Cleaned] ASC);

