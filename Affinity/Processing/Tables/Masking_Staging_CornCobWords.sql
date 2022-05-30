CREATE TABLE [Processing].[Masking_Staging_CornCobWords] (
    [Word] VARCHAR (200) NULL
);


GO
CREATE CLUSTERED INDEX [cix_corn_stage]
    ON [Processing].[Masking_Staging_CornCobWords]([Word] ASC);

